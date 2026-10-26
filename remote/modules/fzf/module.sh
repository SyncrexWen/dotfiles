# shellcheck shell=bash disable=SC2034
MOD_DESC="fzf 及 shell 集成 (Ctrl+R / Ctrl+T / Alt+C)"
MOD_APT=(fzf)
MOD_DEPS=(shell)
MOD_CHECK=(fzf)

mod_configure() {
  write_confd 10-fzf.bash
}
