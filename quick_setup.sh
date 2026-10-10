#!/usr/bin/env bash
set -euo pipefail

# 克隆 dotfiles
git clone https://github.com/SyncrexWen/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
TARGET_DIR="${TARGET_DIR:-$HOME}"

PACKAGES=(
  zsh
  git
  nvim
  wezterm
  aerospace
  starship
  vscode
  rime
  ssh
  docker
  wallpapers
)

# 通用 stow 选项
STOW_OPTS=(
  --no-folding
  --verbose=1   # 可选：0=静默, 1=摘要, 2=详细；不需要可删
)

# 检查依赖
command -v stow >/dev/null 2>&1 || { echo "错误: 未找到 stow，请先安装"; exit 1; }
[[ -d "$DOTFILES_DIR" ]] || { echo "错误: dotfiles 目录不存在: $DOTFILES_DIR"; exit 1; }

# 执行 stow
for pkg in "${PACKAGES[@]}"; do
  if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
    echo "==> stow $pkg"
    stow -d "$DOTFILES_DIR" -t "$TARGET_DIR" "${STOW_OPTS[@]}" "$pkg"
  else
    echo "警告: 跳过不存在的包: $pkg" >&2
  fi
done

echo "完成。"