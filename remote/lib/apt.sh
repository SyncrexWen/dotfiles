# shellcheck shell=bash
# lib/apt.sh — apt / sudo 相关函数。依赖 lib/common.sh。

SUDO=""
setup_sudo() {
  have apt-get || { warn "仅支持 Debian/Ubuntu (apt)"; exit 1; }
  if [ "$(id -u)" -ne 0 ]; then
    have sudo || { warn "非 root 且没有 sudo"; exit 1; }
    SUDO="sudo"
    sudo -v || { warn "需要 sudo 权限"; exit 1; }
  fi
}

# sudo 默认会清空环境变量，所以 DEBIAN_FRONTEND 必须通过 env 传进去
# SC2086：$SUDO 为空时必须展开成"没有这个词"，所以故意不加引号
# shellcheck disable=SC2086
apt_get()     { $SUDO env DEBIAN_FRONTEND=noninteractive apt-get "$@"; }
apt_install() { apt_get install -y "$@"; }
apt_has()     { apt-cache show "$1" >/dev/null 2>&1; }

apt_install_all() {  # 批量安装；失败则逐个重试，只要有一个失败就返回非 0
  apt_install "$@" && return 0
  warn "批量安装失败，改为逐个安装"
  local p rc=0
  for p in "$@"; do
    apt_install "$p" || { warn "apt: $p 安装失败"; rc=1; }
  done
  return $rc
}
