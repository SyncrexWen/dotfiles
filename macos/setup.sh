#!/usr/bin/env bash
# Usage: ./setup.sh            # apply user-level settings
#        ./setup.sh --sudo     # also apply settings that need admin rights (firewall, etc.)
#        MAC_NAME=mymac ./setup.sh --sudo   # also set computer name (kept out of the repo)
set -euo pipefail
cd "$(dirname "$0")"

[[ "$(uname)" == Darwin ]] || { echo "[ERROR] macOS only"; exit 1; }

echo "[1/3] Applying defaults settings..."
bash ./defaults.sh

if [[ "${1:-}" == "--sudo" ]]; then
  echo "[2/3] Applying system-level settings (password required)..."
  # Enable application firewall
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
  # Computer name is passed via env var so it never lands in the public repo
  if [[ -n "${MAC_NAME:-}" ]]; then
    sudo scutil --set ComputerName "$MAC_NAME"
    sudo scutil --set LocalHostName "$MAC_NAME"
  fi
else
  echo "[2/3] Skipping system-level settings (use --sudo to apply)"
fi

echo "[3/3] Restarting affected processes..."
for app in Finder Dock SystemUIServer; do
  killall "$app" &>/dev/null || true
done

echo "[OK] Done. Some settings (e.g. key repeat rate) require logout/login to take effect."
echo "[INFO] Please verify FileVault is enabled: fdesetup status"
