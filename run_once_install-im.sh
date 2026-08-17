#!/usr/bin/env bash

set -Eeuo pipefail

readonly RIME_ICE_REPO="https://github.com/iDvel/rime-ice.git"
readonly WUBI_REPO="https://github.com/KyleBing/rime-wubi86-jidian.git"
readonly RIME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fcitx5/rime"

readonly -a FCITX5_PACKAGES=(
  fcitx5
  fcitx5-configtool
  fcitx5-chinese-addons
  fcitx5-qt
  fcitx5-gtk
  fcitx5-mozc
  fcitx5-rime
)

work_dir=""

log() {
  printf '\n==> %s\n' "$*"
}

die() {
  printf '错误: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$work_dir" && -d "$work_dir" ]]; then
    printf '\n==> 删除雾凇拼音和极点五笔的临时下载目录\n'
    rm -rf -- "$work_dir"
  fi
}

trap cleanup EXIT

install_packages() {
  command -v pacman >/dev/null 2>&1 || die "此脚本仅支持 Arch Linux（未找到 pacman）"

  log "将安装以下 Fcitx5 组件和下载工具"
  printf '  %s\n' "${FCITX5_PACKAGES[@]}"

  if ((EUID == 0)); then
    pacman -S --needed "${FCITX5_PACKAGES[@]}"
  else
    command -v sudo >/dev/null 2>&1 || die "安装系统软件包需要 sudo"
    sudo pacman -S --needed "${FCITX5_PACKAGES[@]}"
  fi
}

install_rime_ice() {
  local source_dir="$work_dir/rime-ice"

  log "下载并安装雾凇拼音"
  git clone --depth 1 "$RIME_ICE_REPO" "$source_dir"

  git -C "$source_dir" archive --format=tar HEAD | tar -xf - -C "$RIME_DIR"
}

install_wubi() {
  local source_dir="$work_dir/rime-wubi86-jidian"
  local -a scheme_files=()

  log "下载并安装极点五笔"
  git clone --depth 1 "$WUBI_REPO" "$source_dir"

  while IFS= read -r -d '' file; do
    scheme_files+=("$file")
  done < <(
    find "$source_dir" -maxdepth 1 -type f \
      \( -name 'wubi86*' -o -name 'pinyin*' \) -print0
  )

  ((${#scheme_files[@]} > 0)) || die "极点五笔仓库中没有找到 wubi86* 或 pinyin* 文件"
  cp -f -- "${scheme_files[@]}" "$RIME_DIR/"

  [[ -d "$source_dir/lua" ]] || die "极点五笔仓库中没有找到 lua 目录"
  mkdir -p "$RIME_DIR/lua"
  cp -a -- "$source_dir/lua/." "$RIME_DIR/lua/"
}

main() {
  install_packages

  command -v git >/dev/null 2>&1 || die "git 安装失败"
  command -v tar >/dev/null 2>&1 || die "未找到 tar"

  mkdir -p "$RIME_DIR"
  work_dir="$(mktemp -d "${TMPDIR:-/tmp}/fcitx5-rime-install.XXXXXXXX")"

  install_rime_ice
  install_wubi

  log "输入方案安装完成"
  printf 'Rime 用户目录：%s\n' "$RIME_DIR"
}

main "$@"
