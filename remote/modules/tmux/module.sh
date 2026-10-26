# shellcheck shell=bash disable=SC2034
MOD_DESC="tmux 及配置 (~/.tmux.conf)"
MOD_APT=(tmux)
MOD_CHECK=(tmux)

mod_configure() {
  write_cfg "$MOD_DIR/tmux.conf" "$HOME/.tmux.conf"
}
