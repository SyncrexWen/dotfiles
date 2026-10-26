# shellcheck shell=bash disable=SC2034
MOD_DESC="eza (现代 ls)：优先 apt，没有则加官方 gierens 源"
MOD_DEPS=(base)
MOD_CHECK=(eza)

mod_install() {
  have eza && return 0
  if apt_has eza; then apt_install eza && return 0; fi
  $SUDO mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | $SUDO gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg || return 1
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | $SUDO tee /etc/apt/sources.list.d/gierens.list >/dev/null
  $SUDO chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  apt_get update -y && apt_install eza && return 0
  $SUDO rm -f /etc/apt/sources.list.d/gierens.list   # 失败则回滚，避免污染 apt 源
  return 1
}
