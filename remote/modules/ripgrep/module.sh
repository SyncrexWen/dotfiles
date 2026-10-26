# shellcheck shell=bash disable=SC2034
MOD_DESC="ripgrep 及配置 (~/.config/ripgrep/config)"
MOD_APT=(ripgrep)
MOD_CHECK=(rg)
# RIPGREP_CONFIG_PATH 仍由 shell 模块的 bashrc 片段导出（旧版即如此，且对非交互 shell 也生效）

mod_configure() {
  write_cfg "$MOD_DIR/ripgrep.config" "$CFG/ripgrep/config"
}
