# shellcheck shell=bash disable=SC2034
MOD_DESC="压缩/解压与管道工具 (unzip/p7zip/7zip/pigz/pv)"
MOD_APT=(unzip p7zip-full pigz pv)
# 仓库里有才装（例如新版 Ubuntu 才有的 7zip，提供 7zz 并支持 RAR）
MOD_APT_OPTIONAL=(7zip)
MOD_CHECK=(pigz pv)
