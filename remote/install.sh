#!/usr/bin/env bash
# install.sh — Debian/Ubuntu 服务器一键配置的调度器（需要 sudo）
#
# 一般不直接运行它，而是通过 bootstrap.sh 下载整个仓库后调用:
#   bash <(curl -fsSL https://raw.githubusercontent.com/SyncrexWen/dotfiles/main/remote/bootstrap.sh) [选项]
# 在本地检出的仓库里也可以直接运行:  bash remote/install.sh --dry-run
#
# 特性: 可重复执行（幂等）；单个步骤失败不影响其他；结束时汇总结果。
#
# 如何扩展:
#   新增一个工具  → 新建 modules/<name>/module.sh（约定见下方 "模块约定" 或任一现有模块），
#                   再在 profiles/server.list 里加一行 <name>
#   加别名 / 函数 → 改 modules/shell/shortcuts.bash
#   机器私有配置  → 写进 ~/.bashrc.local（脚本不会碰它）
#
# 模块约定（modules/<name>/module.sh，在子 shell 中加载，缺哪项就跳过哪项）:
#   MOD_DESC="一句话说明"          # 可选，仅用于 --list
#   MOD_APT=(...)                  # 需要的 apt 包（所有模块合并后一次批量安装）
#   MOD_APT_OPTIONAL=(...)         # 可选 apt 包（仓库里有才装）
#   MOD_DEPS=(...)                 # 依赖的其他模块（会被自动排到前面 / 被 --only 带上）
#   MOD_CHECK=(...)                # 结尾汇总时检查的命令名
#   mod_install()   { ... }        # 特殊安装方式
#   mod_configure() { ... }        # 写配置
#   可用变量: $MOD_DIR（模块目录）、$BIN $CFG $SHELL_DIR $CONFD、$SUDO；
#   可用函数: lib/ 下的 have / warn / apt_* / write_cfg / write_confd / set_rc_block
#   注意: MOD_* 里的元素不能含空白。

set -uo pipefail   # 故意不用 -e：单个步骤失败不应中断整体

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit 1
readonly ROOT
readonly MODULES_DIR="$ROOT/modules"
readonly PROFILES_DIR="$ROOT/profiles"

# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"
# shellcheck source=lib/apt.sh
source "$ROOT/lib/apt.sh"
# shellcheck source=lib/files.sh
source "$ROOT/lib/files.sh"

# 不要用关联数组 / mapfile：保持 bash 3.2（macOS 自带）也能跑 --list / --dry-run。

usage() {
  cat <<'EOF'
用法: install.sh [选项]

选项:
  --profile NAME   使用 profiles/NAME.list（默认 server）
  --only a,b       仅运行指定模块（依赖会被自动带上）
  --skip a,b       跳过指定模块
  --list           列出所有可用模块后退出
  --dry-run        只打印将执行的步骤，不做任何修改（不需要 sudo）
  -h, --help       显示本帮助

示例:
  install.sh --dry-run
  install.sh --only tmux,fzf
  install.sh --skip uv,shcopy

通过 bootstrap.sh 运行时，选项原样透传；环境变量 DOTFILES_REF 可指定分支/标签/提交（默认 main）。
EOF
}

die()       { warn "$*"; exit 1; }
usage_err() { warn "$*"; warn "用 --help 查看用法"; exit 2; }

############################################
# 参数解析
############################################
PROFILE=server
ONLY=""
SKIP=""
DO_LIST=0
DRY_RUN=0

parse_args() {
  while [ $# -gt 0 ]; do
    case $1 in
      --profile) [ $# -ge 2 ] || usage_err "--profile 需要一个参数"; PROFILE=$2; shift 2 ;;
      --profile=*) PROFILE=${1#*=}; shift ;;
      --only)    [ $# -ge 2 ] || usage_err "--only 需要一个参数";    ONLY=$2;    shift 2 ;;
      --only=*)  ONLY=${1#*=}; shift ;;
      --skip)    [ $# -ge 2 ] || usage_err "--skip 需要一个参数";    SKIP=$2;    shift 2 ;;
      --skip=*)  SKIP=${1#*=}; shift ;;
      --list)    DO_LIST=1; shift ;;
      --dry-run) DRY_RUN=1; shift ;;
      -h|--help) usage; exit 0 ;;
      *) usage_err "未知参数: $1" ;;
    esac
  done
}

############################################
# 工具函数
############################################
valid_name() {  # 模块名 / profile 名只允许小写字母、数字、连字符
  case $1 in
    ''|-*|*[!a-z0-9-]*) return 1 ;;
    *) return 0 ;;
  esac
}

in_words() {  # in_words " a b c " b：判断词是否在以单空格分隔、首尾带空格的字符串里
  case $1 in *" $2 "*) return 0 ;; esac
  return 1
}

# 模块元数据存在 M_<KIND>_<模块名(连字符换成下划线)> 变量里（避免关联数组）
mvar()     { printf 'M_%s_%s' "$1" "${2//-/_}"; }
meta_set() { printf -v "$(mvar "$1" "$2")" '%s' "$3"; }
meta_get() {  # 变量名由 mvar 生成，只含 [A-Za-z0-9_]，eval 是安全的
  local v; v=$(mvar "$1" "$2")
  eval "printf '%s' \"\${$v-}\""
}

all_modules() {
  local d
  for d in "$MODULES_DIR"/*/; do
    [ -f "${d}module.sh" ] && basename "$d"
  done
}

# load_meta <模块名>：在子 shell 里加载 module.sh，把声明读回当前 shell。
# 模块文件只在子 shell 里被 source，所以模块里的函数 / 变量不会污染调度器或其他模块。
load_meta() {
  local name=$1 dir out key val
  valid_name "$name" || { warn "非法模块名: $name"; return 1; }
  dir="$MODULES_DIR/$name"
  [ -f "$dir/module.sh" ] || { warn "找不到模块: $name"; return 1; }
  in_words "$LOADED" "$name" && return 0
  out=$(
    # shellcheck disable=SC2034  # MOD_DIR 供 module.sh 使用
    MOD_DIR=$dir
    # shellcheck source=/dev/null
    source "$dir/module.sh" >&2 || exit 1
    printf 'DESC\t%s\n'    "${MOD_DESC-}"
    printf 'APT\t%s\n'     "${MOD_APT[*]-}"
    printf 'APT_OPT\t%s\n' "${MOD_APT_OPTIONAL[*]-}"
    printf 'DEPS\t%s\n'    "${MOD_DEPS[*]-}"
    printf 'CHECK\t%s\n'   "${MOD_CHECK[*]-}"
    if declare -F mod_install   >/dev/null; then printf 'INSTALL\t1\n';   fi
    if declare -F mod_configure >/dev/null; then printf 'CONFIGURE\t1\n'; fi
    exit 0
  ) || { warn "加载模块失败: $name"; return 1; }
  while IFS=$'\t' read -r key val; do
    case $key in
      DESC|APT|APT_OPT|DEPS|CHECK|INSTALL|CONFIGURE) meta_set "$key" "$name" "$val" ;;
    esac
  done <<<"$out"
  LOADED="$LOADED$name "
}
LOADED=" "

############################################
# profile 与依赖解析
############################################
PROFILE_MODS=()
read_profile() {  # 一行一个模块名；# 开头或行内 # 之后为注释
  local f="$PROFILES_DIR/$PROFILE.list" line
  valid_name "$PROFILE" || { warn "非法 profile 名: $PROFILE"; return 1; }
  [ -f "$f" ] || { warn "找不到 profile: $f"; return 1; }
  PROFILE_MODS=()
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%%#*}
    line=${line//[[:space:]]/}
    [ -n "$line" ] && PROFILE_MODS+=("$line")
  done <"$f"
  return 0
}

RESOLVED=()
DONE=" "
VISITING=" "
visit() {  # 深度优先：先访问依赖再放入自己 → 拓扑序，且尽量保持 profile 里的顺序
  local m=$1 d deps=()
  in_words "$DONE" "$m" && return 0
  in_words "$VISITING" "$m" && die "模块依赖出现循环: $m"
  load_meta "$m" || return 1
  VISITING="$VISITING$m "
  read -r -a deps <<<"$(meta_get DEPS "$m")"
  for d in ${deps[@]+"${deps[@]}"}; do
    visit "$d" || { warn "（被模块 $m 依赖）"; return 1; }
  done
  VISITING=${VISITING/ $m / }
  DONE="$DONE$m "
  RESOLVED+=("$m")
}

PLAN=()
build_plan() {
  local roots=() only=() skip=() m d s deps=() skip_words=" " only_words=" " prof_words=" "
  read_profile || exit 1
  for m in ${PROFILE_MODS[@]+"${PROFILE_MODS[@]}"}; do prof_words="$prof_words$m "; done

  if [ -n "$ONLY" ]; then
    IFS=',' read -r -a only <<<"$ONLY"
    for m in ${only[@]+"${only[@]}"}; do only_words="$only_words$m "; done
    # profile 里的按 profile 顺序，profile 之外的（只要模块存在）追加在后面
    for m in ${PROFILE_MODS[@]+"${PROFILE_MODS[@]}"}; do
      in_words "$only_words" "$m" && roots+=("$m")
    done
    for m in ${only[@]+"${only[@]}"}; do
      [ -n "$m" ] || continue
      in_words "$prof_words" "$m" || roots+=("$m")
    done
  else
    for m in ${PROFILE_MODS[@]+"${PROFILE_MODS[@]}"}; do roots+=("$m"); done
  fi

  for m in ${roots[@]+"${roots[@]}"}; do
    visit "$m" || exit 1
  done

  if [ -n "$SKIP" ]; then
    IFS=',' read -r -a skip <<<"$SKIP"
    for s in ${skip[@]+"${skip[@]}"}; do
      [ -n "$s" ] || continue
      if valid_name "$s" && [ -f "$MODULES_DIR/$s/module.sh" ]; then
        skip_words="$skip_words$s "
      else
        warn "--skip: 没有这个模块，已忽略: $s"
      fi
    done
  fi
  for m in ${RESOLVED[@]+"${RESOLVED[@]}"}; do
    in_words "$skip_words" "$m" || PLAN+=("$m")
  done
  for m in ${PLAN[@]+"${PLAN[@]}"}; do
    read -r -a deps <<<"$(meta_get DEPS "$m")"
    for d in ${deps[@]+"${deps[@]}"}; do
      in_words "$skip_words" "$d" && warn "模块 $m 依赖被跳过的模块 $d，可能无法正常工作"
    done
  done
}

############################################
# 汇总各模块声明
############################################
APT_PKGS=()
APT_OPT=()
CHECK_CMDS=()
collect_lists() {
  local m p c arr seen_apt=" " seen_opt=" " seen_chk=" "
  for m in ${PLAN[@]+"${PLAN[@]}"}; do
    read -r -a arr <<<"$(meta_get APT "$m")"
    for p in ${arr[@]+"${arr[@]}"}; do
      in_words "$seen_apt" "$p" || { seen_apt="$seen_apt$p "; APT_PKGS+=("$p"); }
    done
    read -r -a arr <<<"$(meta_get APT_OPT "$m")"
    for p in ${arr[@]+"${arr[@]}"}; do
      in_words "$seen_opt" "$p" || { seen_opt="$seen_opt$p "; APT_OPT+=("$p"); }
    done
    read -r -a arr <<<"$(meta_get CHECK "$m")"
    for c in ${arr[@]+"${arr[@]}"}; do
      in_words "$seen_chk" "$c" || { seen_chk="$seen_chk$c "; CHECK_CMDS+=("$c"); }
    done
  done
}

############################################
# 执行
############################################
install_apt_packages() {
  local p
  apt_get update -y || warn "apt update 失败，继续尝试安装"
  if [ ${#APT_PKGS[@]} -gt 0 ]; then
    # 旧版脚本里这一步的返回值同样被忽略（失败只在 apt_install_all 内部告警），保持原样
    apt_install_all "${APT_PKGS[@]}"
  fi
  for p in ${APT_OPT[@]+"${APT_OPT[@]}"}; do
    if apt_has "$p"; then apt_install "$p" || warn "apt: $p 安装失败"; fi
  done
  return 0
}

run_mod() {  # run_mod <模块名> <install|configure>：在子 shell 里执行模块的对应函数
  local name=$1 phase=$2
  (
    # shellcheck disable=SC2034  # MOD_DIR 供 module.sh 使用
    MOD_DIR="$MODULES_DIR/$name"
    # shellcheck source=/dev/null
    source "$MOD_DIR/module.sh" || exit 1
    "mod_$phase"
  )
}

print_summary() {
  local c
  echo
  if [ "$DRY_RUN" = 1 ]; then
    log "[dry-run] 结束时将检查这些命令: ${CHECK_CMDS[*]-}"
    log "[dry-run] 未做任何修改。"
    return 0
  fi
  log "安装结果:"
  for c in ${CHECK_CMDS[@]+"${CHECK_CMDS[@]}"}; do
    if have "$c"; then printf '  \033[32m✓\033[0m %s\n' "$c"
    else               printf '  \033[31m✗\033[0m %s\n' "$c"; fi
  done
  if (( ${#FAILED[@]} )); then
    echo
    warn "以下步骤失败: ${FAILED[*]}"
  fi
  echo
  log "完成。执行 'source ~/.bashrc' 或重新登录生效。"
}

list_modules() {
  local m inprof deps
  local prof_words=" " p
  if read_profile; then
    for p in ${PROFILE_MODS[@]+"${PROFILE_MODS[@]}"}; do prof_words="$prof_words$p "; done
  else
    warn "（无法读取 profile '$PROFILE'，下表的 profile 列留空）"
  fi
  printf '%-10s %-8s %-12s %s\n' MODULE "IN:$PROFILE" DEPS DESCRIPTION
  for m in $(all_modules); do
    load_meta "$m" || continue
    if in_words "$prof_words" "$m"; then inprof="yes"; else inprof="-"; fi
    deps=$(meta_get DEPS "$m")
    printf '%-10s %-8s %-12s %s\n' "$m" "$inprof" "${deps:--}" "$(meta_get DESC "$m")"
  done
}

main() {
  local m
  parse_args "$@"

  if [ "$DO_LIST" = 1 ]; then
    list_modules
    exit 0
  fi

  build_plan
  [ ${#PLAN[@]} -gt 0 ] || die "没有要运行的模块"
  collect_lists

  log "profile: $PROFILE${ONLY:+  only: $ONLY}${SKIP:+  skip: $SKIP}"
  log "模块顺序: ${PLAN[*]}"

  if [ "$DRY_RUN" != 1 ]; then
    mkdir -p "$BIN" "$CFG" "$SHELL_DIR"
    export PATH="$BIN:$PATH"
    setup_sudo
  fi

  if [ ${#APT_PKGS[@]} -gt 0 ] || [ ${#APT_OPT[@]} -gt 0 ]; then
    step "apt 软件包" install_apt_packages
    if [ "$DRY_RUN" = 1 ]; then
      [ ${#APT_PKGS[@]} -gt 0 ] && printf '            apt install : %s\n' "${APT_PKGS[*]}"
      [ ${#APT_OPT[@]} -gt 0 ]  && printf '            apt optional: %s（仓库里有才装）\n' "${APT_OPT[*]}"
    fi
  fi
  # 与旧版一致：先把所有模块的安装跑完，再统一写配置
  for m in "${PLAN[@]}"; do
    [ -n "$(meta_get INSTALL "$m")" ] && step "安装 $m" run_mod "$m" install
  done
  for m in "${PLAN[@]}"; do
    [ -n "$(meta_get CONFIGURE "$m")" ] && step "配置 $m" run_mod "$m" configure
  done

  print_summary
}

# main 放在最后调用：下载被截断时不会执行半截脚本
main "$@"
