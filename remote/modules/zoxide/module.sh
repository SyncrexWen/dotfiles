# shellcheck shell=bash disable=SC2034
MOD_DESC="zoxide (智能 cd)，官方安装脚本"
MOD_DEPS=(base shell)
MOD_CHECK=(zoxide)

mod_install() {
  have zoxide || curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

mod_configure() {
  write_confd 90-zoxide.bash
}
