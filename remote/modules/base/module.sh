# shellcheck shell=bash disable=SC2034
MOD_DESC="基础依赖 (curl/wget/gpg…)、fd、bat、tree"
MOD_APT=(ca-certificates curl wget gpg fd-find bat tree)
MOD_CHECK=(fd bat tree)

# Debian/Ubuntu 上 fd、bat 的二进制名分别是 fdfind、batcat，建软链还原
# （apt 批量安装发生在所有模块的 mod_install 之前，所以这里包已经装好了）
mod_install() {
  have fdfind && ! have fd  && ln -sf "$(command -v fdfind)" "$BIN/fd"
  have batcat && ! have bat && ln -sf "$(command -v batcat)" "$BIN/bat"
  return 0
}
