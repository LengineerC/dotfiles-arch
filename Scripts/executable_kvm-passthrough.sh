#!/bin/bash

VGA_PCI="0000:01:00.0"
AUDIO_PCI="0000:01:00.1"
# 虚拟机分配内存大小/2
HUGEPAGES_NUM=8192
# 虚拟机名称
VM_NAME="win11"

LOOP_TIMES=3

if [ "$EUID" -ne 0 ]; then
  echo "必须使用sudo运行脚本！"
  exit 1
fi

start_passthrough() {
  echo ">>> [1/4] 清理 NVIDIA 进程并卸载驱动模块..."
  UNLOAD_SUCCESS=false

  for ((i = 1; i <= LOOP_TIMES; i++)); do
    echo "  -> 第 $i 次尝试清理与卸载..."

    # 强制杀死占用 NVIDIA 设备的进程
    fuser -k -9 /dev/nvidia* 2>/dev/null || true
    sleep 1

    all_unloaded=true

    for mod in nvidia_drm nvidia_modeset nvidia_uvm nvidia; do
      out=$(LC_ALL=C rmmod "$mod" 2>&1)
      exit_code=$?

      if [ $exit_code -ne 0 ] && [[ ! "$out" =~ "is not currently loaded"$ && ! "$out" =~ "is not currently loaded."$ ]]; then
        all_unloaded=false
        echo "  [调试] $mod 卸载失败，真实原因为: $out"
        break
      fi
    done

    # 如果四个模块都顺利通过（要么成功，要么是 is not currently loaded）
    if [ "$all_unloaded" = true ]; then
      UNLOAD_SUCCESS=true
      echo "  ✅ 成功: NVIDIA 相关内核模块已全部彻底卸载。"
      break # 跳出最外层的 LOOP_TIMES 循环
    fi

    echo "  ⚠️ 警告: 模块仍被占用，3秒后进行下一次重试..."
    sleep 3
  done

  # 兜底：如果循环结束了还是没成功
  if [ "$UNLOAD_SUCCESS" = false ]; then
    echo "❌ 致命错误: 已重试 $LOOP_TIMES 次，NVIDIA 模块依然无法卸载！"
    exit 1
  fi

  echo ">>> [2/4] 从宿主机解绑原生驱动..."
  echo "$VGA_PCI" | tee /sys/bus/pci/drivers/nvidia/unbind
  echo "$AUDIO_PCI" | tee /sys/bus/pci/drivers/snd_hda_intel/unbind

  echo ">>> [3/4] 绑定显卡至 vfio-pci 驱动..."
  modprobe vfio-pci
  echo "vfio-pci" | tee /sys/bus/pci/devices/$VGA_PCI/driver_override
  echo "vfio-pci" | tee /sys/bus/pci/devices/$AUDIO_PCI/driver_override
  echo "$VGA_PCI" | tee /sys/bus/pci/drivers_probe
  echo "$AUDIO_PCI" | tee /sys/bus/pci/drivers_probe

  echo ">>> [4/4] 整理内存碎片并分配大页 (2MB) ..."
  sync
  echo 3 | tee /proc/sys/vm/drop_caches
  echo 1 | tee /proc/sys/vm/compact_memory
  sysctl -w vm.nr_hugepages=$HUGEPAGES_NUM >/dev/null

  lspci -k -s "$VGA_PCI" | grep -A 2 -i nvidia

  if lspci -k -s "$VGA_PCI" | grep -q "Kernel driver in use: vfio-pci"; then
    echo "----------------------------------------"
    echo "✅ 验证通过！显卡已成功被 VFIO 托管。"
    echo "✅ 内存大页分配完成，当前数量: $(cat /proc/sys/vm/nr_hugepages)"
  else
    echo "----------------------------------------"
    echo "❌ 警告：设备未能成功绑定到 vfio-pci，请检查系统日志(dmesg)！"
  fi
}

stop_passthrough() {
  echo ">>> [安全检测] 检查虚拟机状态..."

  # 1. 自动检测状态
  VM_STATE=$(virsh domstate "$VM_NAME" 2>/dev/null)
  if [[ "$VM_STATE" == *"running"* || "$VM_STATE" == *"pmsuspended"* || "$VM_STATE" == *"paused"* ]]; then
    echo "❌ 致命错误: 检测到虚拟机 ($VM_NAME) 仍在运行或挂起！状态: $VM_STATE"
    echo "❌ 强制抢夺显卡会导致宿主机内核崩溃。脚本已中止。"
    exit 1
  fi

  # 2. 手动二次确认
  echo "⚠️ 危险操作警告：如果虚拟机尚未完全关闭，恢复驱动将导致宿主机死机！"
  read -p "❓ 请确认虚拟机屏幕已彻底关闭。是否继续恢复显卡？[y/N]: " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "已取消恢复操作。"
    exit 0
  fi
  # ------------------------------

  echo ">>> [1/5] 清除 VFIO 驱动覆盖并解绑..."
  echo "" | tee /sys/bus/pci/devices/$VGA_PCI/driver_override
  echo "" | tee /sys/bus/pci/devices/$AUDIO_PCI/driver_override
  echo "$VGA_PCI" | tee /sys/bus/pci/drivers/vfio-pci/unbind
  echo "$AUDIO_PCI" | tee /sys/bus/pci/drivers/vfio-pci/unbind

  echo ">>> [2/5] 重新加载 NVIDIA 内核模块..."
  modprobe nvidia
  modprobe nvidia_drm
  modprobe nvidia_modeset
  modprobe nvidia_uvm

  echo ">>> [3/5] 重新探测设备并激活显卡..."
  echo "$VGA_PCI" | tee /sys/bus/pci/drivers_probe
  echo "$AUDIO_PCI" | tee /sys/bus/pci/drivers_probe

  echo ">>> [4/5] 释放内存大页归还宿主机..."
  sysctl -w vm.nr_hugepages=0

  echo ">>> [5/5] 验证 NVIDIA 原生驱动恢复状态..."
  lspci -k -s "$VGA_PCI" | grep -A 2 -i nvidia

  if lspci -k -s "$VGA_PCI" | grep -q "Kernel driver in use: nvidia"; then
    echo "----------------------------------------"
    echo "✅ 验证通过！原生 NVIDIA 驱动已成功接管显卡。"
    echo "✅ 内存大页已释放，当前数量: $(cat /proc/sys/vm/nr_hugepages)"
  else
    echo "----------------------------------------"
    echo "❌ 警告：NVIDIA 驱动未能接管设备，可能需要手动干预或重启！"
  fi
}

# 命令路由
case "$1" in
start)
  start_passthrough
  ;;
stop)
  stop_passthrough
  ;;
*)
  echo "用法: $0 {start|stop}"
  exit 1
  ;;
esac
