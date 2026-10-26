# shellcheck shell=bash disable=SC2034
MOD_DESC="btop 及初始配置"
MOD_APT=(btop)
MOD_CHECK=(btop)

mod_configure() {
  [ -f "$CFG/btop/btop.conf" ] && return 0   # 不覆盖 btop 自己生成的配置
  mkdir -p "$CFG/btop" || return 1
  cp "$MOD_DIR/btop.conf" "$CFG/btop/btop.conf"
}
