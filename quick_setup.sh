#!/usr/bin/env bash
set -euo pipefail

# clone into dotfiles
echo "==> cloning dotfiles"
git clone https://github.com/SyncrexWen/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# <<< START stow packages <<<
echo "==> stow packages"
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
  ssh
  wallpapers
  boop
  raycast
)

STOW_OPTS=(
  --no-folding
  --verbose=1
)

command -v stow >/dev/null 2>&1 || { echo "Error: stow not found, please install it first"; exit 1; }
[[ -d "$DOTFILES_DIR" ]] || { echo "Error: dotfiles directory does not exist: $DOTFILES_DIR"; exit 1; }

for pkg in "${PACKAGES[@]}"; do
  if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
    echo "==> stow $pkg"
    stow -d "$DOTFILES_DIR" -t "$TARGET_DIR" "${STOW_OPTS[@]}" "$pkg"
  else
    echo "Warning: skip missing package: $pkg" >&2
  fi
done

echo "done."
# <<< END stow packages <<<

# <<< START brew packages installation <<<
if command -v brew >/dev/null 2>&1; then
    echo "Homebrew is installed: $(brew --version | head -n 1)"
else
    echo "Homebrew is not installed."
    printf "Install homebrew? yes/no:"
    read answer

    if [ "$answer" = "yes" ]; then
        echo "installing homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Exiting. Stop at brew installation."
        exit 1
    fi
fi
echo "==> installing brew packages"
[ -d "$HOME/.dotfiles/brewfiles" ] && find "$HOME/.dotfiles/brewfiles" -type f -exec brew bundle --file={} \;

# ---- macOS settings ----
echo "==> configuring macos..."
if [[ "$(uname)" == "Darwin" ]]; then
  echo "[macOS] Applying system settings..."
  bash "$HOME/.dotfiles/macos/setup.sh" "$@" || echo "[WARN] macOS setup failed, continuing..."
fi
