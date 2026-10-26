#!/usr/bin/env bash
# bootstrap.sh — Debian/Ubuntu 服务器一键配置的唯一 curl 入口
#
# 用法（推荐用进程替换：保留终端 stdin，sudo 密码提示和子安装器更稳）:
#   bash <(curl -fsSL https://raw.githubusercontent.com/SyncrexWen/dotfiles/main/remote/bootstrap.sh) [install.sh 的选项]
#   例: bash <(curl -fsSL .../bootstrap.sh) --dry-run
#
# 做的事:
#   1. 把仓库 tarball（不需要服务器装 git）下载到临时目录并完整校验、解压；
#   2. 全部成功后才替换到 ~/.cache/dotfiles-remote/src；
#   3. exec bash .../remote/install.sh "$@"（stdin 原样继承，参数原样透传）。
#
# 环境变量:
#   DOTFILES_REF   要使用的分支 / 标签 / 提交，默认 main
#
# 为什么解压到 ~/.cache/dotfiles-remote 而不是 ~/.dotfiles:
#   ~/.dotfiles 可能是用户自己的 git 检出，带有本地改动；解压覆盖它会丢改动或弄脏工作区。
#   缓存目录是脚本私有的，每次整体替换，不存在"半新半旧"的文件，也不需要 git。

set -uo pipefail   # 故意不用 -e：每一步都显式检查

readonly REPO="SyncrexWen/dotfiles"

die() { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }
log() { printf '\033[1;34m[+]\033[0m %s\n' "$*"; }

main() {
  local ref="${DOTFILES_REF:-main}"
  local url="https://github.com/$REPO/archive/$ref.tar.gz"
  local base="${XDG_CACHE_HOME:-${HOME:?HOME 未设置}/.cache}/dotfiles-remote"
  local tmp

  command -v curl >/dev/null 2>&1 || die "需要 curl"
  command -v tar  >/dev/null 2>&1 || die "需要 tar"

  mkdir -p "$base" || die "无法创建 $base"
  tmp=$(mktemp -d "$base/.dl.XXXXXX") || die "无法创建临时目录"
  # 任何中途失败都清理临时目录；成功路径在 exec 之前手动清理（exec 不会触发 EXIT trap）
  trap 'rm -rf "$tmp"' EXIT

  log "下载 $REPO@$ref ..."
  curl -fsSL --retry 3 --connect-timeout 15 -o "$tmp/src.tar.gz" "$url" \
    || die "下载失败: $url"
  # 通读整个压缩流，确认归档没有被截断 / 损坏
  tar -tzf "$tmp/src.tar.gz" >/dev/null 2>&1 || die "tarball 校验失败（下载不完整？）"

  mkdir "$tmp/src" || die "无法创建解压目录"
  # tarball 顶层目录名随 ref 变化（dotfiles-<ref>），用 --strip-components 去掉
  tar -xzf "$tmp/src.tar.gz" -C "$tmp/src" --strip-components=1 || die "解压失败"
  [ -f "$tmp/src/remote/install.sh" ] || die "归档中没有 remote/install.sh（ref 是否正确: $ref ？）"

  # 到这里下载与解压都已完整成功，才替换旧缓存
  rm -rf "$base/src" || die "无法清理旧缓存 $base/src"
  mv "$tmp/src" "$base/src" || die "无法移动解压结果"
  rm -rf "$tmp"
  trap - EXIT

  exec bash "$base/src/remote/install.sh" "$@"
}

# main 放在最后调用：下载被截断时不会执行半截脚本
main "$@"
