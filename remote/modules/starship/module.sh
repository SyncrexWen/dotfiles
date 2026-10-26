# shellcheck shell=bash disable=SC2034
MOD_DESC="starship 提示符及配置 (~/.config/starship.toml)，官方安装脚本"
MOD_DEPS=(base shell)
MOD_CHECK=(starship)

mod_install() {
  have starship || curl -sSfL https://starship.rs/install.sh | sh -s -- -y -b "$BIN"
}

mod_configure() {
  local rc=0
  write_cfg "$MOD_DIR/starship.toml" "$CFG/starship.toml" || rc=1
  write_confd 50-starship.bash || rc=1
  return $rc
}
