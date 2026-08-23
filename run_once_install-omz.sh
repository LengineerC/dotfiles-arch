#!/usr/bin/env bash

set -Eeuo pipefail

readonly OMZ_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
readonly AUTOSUGGESTIONS_REPO="https://github.com/zsh-users/zsh-autosuggestions.git"
readonly SYNTAX_HIGHLIGHTING_REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"

readonly OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"
readonly CUSTOM_DIR="${ZSH_CUSTOM:-$OMZ_DIR/custom}"

log() {
  printf '\n==> %s\n' "$*"
}

die() {
  printf '错误: %s\n' "$*" >&2
  exit 1
}

clone_if_missing() {
  local repository="$1"
  local destination="$2"
  local name="$3"

  if [[ -e "$destination" ]]; then
    if [[ -d "$destination" && -e "$destination/.git" ]] &&
      git -C "$destination" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      log "$name 已安装，跳过"
      return
    fi

    die "$destination 已存在且不是 Git 仓库，请手动检查"
  fi

  log "安装 $name"
  mkdir -p "$(dirname "$destination")"
  git clone --depth 1 "$repository" "$destination"
}

main() {
  command -v git >/dev/null 2>&1 || die "未找到 git，请先安装 git"
  command -v zsh >/dev/null 2>&1 || die "未找到 zsh，请先安装 zsh"

  clone_if_missing "$OMZ_REPO" "$OMZ_DIR" "Oh My Zsh"
  clone_if_missing \
    "$AUTOSUGGESTIONS_REPO" \
    "$CUSTOM_DIR/plugins/zsh-autosuggestions" \
    "zsh-autosuggestions"
  clone_if_missing \
    "$SYNTAX_HIGHLIGHTING_REPO" \
    "$CUSTOM_DIR/plugins/zsh-syntax-highlighting" \
    "zsh-syntax-highlighting"

  sudo pacman -S --needed fzf

  log "Oh My Zsh 和插件安装完成"
  printf 'Oh My Zsh：%s\n' "$OMZ_DIR"
  printf '自定义插件：%s/plugins\n' "$CUSTOM_DIR"
}

main "$@"
