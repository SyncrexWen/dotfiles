# shellcheck shell=bash disable=SC2034
MOD_DESC="shcopy (OSC52 复制到本地剪贴板)，来自第三方 apt 源"
MOD_DEPS=(base)
MOD_CHECK=(shcopy)

mod_install() {
  have shcopy && return 0
  echo 'deb [trusted=yes] https://repo.aymanbagabas.com/apt/ /' \
    | $SUDO tee /etc/apt/sources.list.d/aymanbagabas.list >/dev/null
  apt_get update -y && apt_install shcopy && return 0
  $SUDO rm -f /etc/apt/sources.list.d/aymanbagabas.list
  return 1
}
