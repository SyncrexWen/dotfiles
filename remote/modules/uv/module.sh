# shellcheck shell=bash disable=SC2034
MOD_DESC="uv (Python 包管理器)，官方安装脚本"
MOD_DEPS=(base)
MOD_CHECK=(uv)

mod_install() {
  have uv || curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
}
