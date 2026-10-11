#!/usr/bin/env bash
# bootstrap_with_sudo.sh — Debian/Ubuntu 服务器一键配置（需要 sudo）
#
# 用法（推荐用进程替换：保留终端 stdin，sudo 密码提示和子安装器更稳）:
#   bash <(curl -fsSL https://raw.githubusercontent.com/SyncrexWen/dotfiles/main/remote/bootstrap_with_sudo.sh)
#
# 特性: 可重复执行（幂等）；单个步骤失败不影响其他；结束时汇总结果。
#
# 如何扩展:
#   加 apt 包                → 往 APT_PKGS 里加名字
#   加需要特殊安装的工具     → 写 install_<name>()，并把 <name> 加进 TOOLS
#   加配置文件               → 写 config_<name>()，并把 <name> 加进 CONFIGS
#   加别名 / 函数            → 改 config_shortcuts 里对应的分区
#   机器私有配置             → 写进 ~/.bashrc.local（脚本不会碰它）

set -uo pipefail   # 故意不用 -e：单个步骤失败不应中断整体

############################################
# 配置区
############################################
readonly BIN="$HOME/.local/bin"
readonly CFG="$HOME/.config"
readonly SHELL_DIR="$CFG/shell"
readonly RC="$HOME/.bashrc"
readonly MARK_CFG="# managed by bootstrap_with_sudo.sh"
readonly BEGIN_MARK="# >>> dotfiles-remote >>>"
readonly END_MARK="# <<< dotfiles-remote <<<"

# 普通 apt 包（批量安装，失败则逐个重试）
readonly APT_PKGS=(tmux ripgrep fd-find bat btop tree pigz pv fzf unzip p7zip-full)
# 可选 apt 包：仓库里有才装（例如新版 Ubuntu 才有的 7zip，提供 7zz 并支持 RAR）
readonly APT_OPTIONAL=(7zip)
# 需要特殊安装方式的工具：每个名字对应一个 install_<name>()
readonly TOOLS=(eza shcopy zoxide starship uv)
# 配置文件：每个名字对应一个 config_<name>()，bashrc 放最后
readonly CONFIGS=(tmux starship ripgrep btop shortcuts bashrc)
# 结束时检查这些命令是否可用
readonly CHECK_CMDS=(tmux rg fd bat eza fzf zoxide starship btop tree shcopy uv pigz pv)

############################################
# 基础工具函数
############################################
log()  { printf '\033[1;34m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

FAILED=()
step() {  # step <描述> <函数> [参数...]：运行一个步骤，失败只记录不中断
  local desc=$1; shift
  log "$desc"
  "$@" || { warn "失败: $desc"; FAILED+=("$desc"); }
}

SUDO=""
setup_sudo() {
  have apt-get || { warn "仅支持 Debian/Ubuntu (apt)"; exit 1; }
  if [ "$(id -u)" -ne 0 ]; then
    have sudo || { warn "非 root 且没有 sudo"; exit 1; }
    SUDO="sudo"
    sudo -v || { warn "需要 sudo 权限"; exit 1; }
  fi
}

# sudo 默认会清空环境变量，所以 DEBIAN_FRONTEND 必须通过 env 传进去
apt_get()     { $SUDO env DEBIAN_FRONTEND=noninteractive apt-get "$@"; }
apt_install() { apt_get install -y "$@"; }
apt_has()     { apt-cache show "$1" >/dev/null 2>&1; }

apt_install_all() {  # 批量安装；失败则逐个重试，只要有一个失败就返回非 0
  apt_install "$@" && return 0
  warn "批量安装失败，改为逐个安装"
  local p rc=0
  for p in "$@"; do
    apt_install "$p" || { warn "apt: $p 安装失败"; rc=1; }
  done
  return $rc
}

# 写配置文件：内容从 stdin 读取。已有且非本脚本生成的文件会先备份
write_cfg() {
  local dst="$1" tmp; tmp=$(mktemp)
  { echo "$MARK_CFG"; cat; } > "$tmp"
  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ] && ! grep -qF "$MARK_CFG" "$dst"; then
    mv "$dst" "$dst.bak.$(date +%s)"; warn "已备份原文件: $dst"
  fi
  install -m 644 "$tmp" "$dst"; rm -f "$tmp"
}

# 维护 ~/.bashrc 里的受管片段：先删旧的再追加，内容从 stdin 读取
set_rc_block() {
  touch "$RC"
  sed -i "\|$BEGIN_MARK|,\|$END_MARK|d" "$RC"
  { echo "$BEGIN_MARK"; cat; echo "$END_MARK"; } >> "$RC"
}

############################################
# apt 软件包
############################################
install_apt_packages() {
  apt_get update -y || warn "apt update 失败，继续尝试安装"
  apt_install ca-certificates curl wget gpg || return 1
  apt_install_all "${APT_PKGS[@]}"
  local p
  for p in "${APT_OPTIONAL[@]}"; do
    if apt_has "$p"; then apt_install "$p" || warn "apt: $p 安装失败"; fi
  done
  return 0
}

# Debian/Ubuntu 上 fd、bat 的二进制名分别是 fdfind、batcat，建软链还原
link_renamed_binaries() {
  have fdfind && ! have fd  && ln -sf "$(command -v fdfind)" "$BIN/fd"
  have batcat && ! have bat && ln -sf "$(command -v batcat)" "$BIN/bat"
  return 0
}

############################################
# 需要特殊安装的工具（install_<name>）
############################################
install_eza() {
  have eza && return 0
  if apt_has eza; then apt_install eza && return 0; fi
  $SUDO mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | $SUDO gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg || return 1
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | $SUDO tee /etc/apt/sources.list.d/gierens.list >/dev/null
  $SUDO chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  apt_get update -y && apt_install eza && return 0
  $SUDO rm -f /etc/apt/sources.list.d/gierens.list   # 失败则回滚，避免污染 apt 源
  return 1
}

install_shcopy() {
  have shcopy && return 0
  echo 'deb [trusted=yes] https://repo.aymanbagabas.com/apt/ /' \
    | $SUDO tee /etc/apt/sources.list.d/aymanbagabas.list >/dev/null
  apt_get update -y && apt_install shcopy && return 0
  $SUDO rm -f /etc/apt/sources.list.d/aymanbagabas.list
  return 1
}

install_zoxide() {
  have zoxide || curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

install_starship() {
  have starship || curl -sSfL https://starship.rs/install.sh | sh -s -- -y -b "$BIN"
}

install_uv() {
  have uv || curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
}

############################################
# 配置文件（config_<name>）
############################################
config_tmux() {
write_cfg "$HOME/.tmux.conf" <<'EOF'
# 前缀改为 C-a：避免与本地 tmux 的 C-b 嵌套冲突
unbind C-b
set -g prefix C-a
bind C-a send-prefix

set -g mouse on
set -g history-limit 100000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -sg escape-time 10
set -g focus-events on
setw -g mode-keys vi

# 颜色（带 -q：旧版 tmux 不认识的选项直接忽略）
set -g default-terminal "tmux-256color"
set -asq terminal-features ',*:RGB'
set -asq terminal-overrides ',*:Tc'

# 剪贴板：tmux 内复制 / shcopy 通过 OSC52 传回本地
set -s set-clipboard on
set -gq allow-passthrough on

# 分屏沿用当前目录
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"
bind r source-file ~/.tmux.conf \; display "reloaded"

# vi 复制模式
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-selection-and-cancel

# 状态栏：显示主机名，和本地 tmux 视觉区分
set -g status-style "bg=colour24,fg=white"
set -g status-left "[#S] "
set -g status-right "#H | %m-%d %H:%M"
EOF
}

config_starship() {
write_cfg "$CFG/starship.toml" <<'EOF'
add_newline = false
command_timeout = 500
format = "$hostname$directory$git_branch$git_status$python$conda$cmd_duration$line_break$character"

[hostname]
ssh_only = false
format = "[$hostname](bold yellow) "

[directory]
truncation_length = 3

[git_branch]
symbol = ""
format = "[$branch]($style) "

[git_status]
format = '([$all_status$ahead_behind]($style) )'

[python]
symbol = "py "
format = '[$symbol(\($virtualenv\) )]($style)'

[conda]
symbol = "conda "
format = '[$symbol$environment]($style) '

[cmd_duration]
min_time = 2000
format = "[$duration]($style) "

[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"
EOF
}

config_ripgrep() {
write_cfg "$CFG/ripgrep/config" <<'EOF'
--smart-case
--max-columns=200
--max-columns-preview
EOF
}

config_btop() {
  [ -f "$CFG/btop/btop.conf" ] && return 0   # 不覆盖 btop 自己生成的配置
  mkdir -p "$CFG/btop"
  printf 'theme_background = False\nupdate_ms = 1000\n' > "$CFG/btop/btop.conf"
}

# ---- 快捷键：别名 / 函数 / bash 行为（Ubuntu 版）----
config_shortcuts() {
write_cfg "$SHELL_DIR/shortcuts.bash" <<'EOF'
# ~/.config/shell/shortcuts.bash —— 别名与函数（bash / Ubuntu）
# 由 ~/.bashrc 的受管片段 source，不要直接执行。

# root 登录时不需要 sudo
if [[ $EUID -eq 0 ]]; then _sudo=""; else _sudo="sudo "; fi

# ============================================================
# 0. 用现代工具替换内置命令（eza / bat）
# ============================================================
# 服务器上默认不加 --icons（需要本地终端装 Nerd Font），要的话自行加 --icons=always
if command -v eza >/dev/null; then
    alias ls='eza --group-directories-first'
    alias ll='eza -l --git --header --group-directories-first'
    alias la='eza -la --git --header --group-directories-first'
    alias l='eza -F --group-directories-first'
    alias lt='eza -l --sort=modified'                 # 最新的在最后
    alias lS='eza -l --sort=size'                     # 最大的在最后
    alias l.='eza -d .*'
    alias tree='eza --tree --git-ignore'
    alias tree2='eza --tree --level=2 --git-ignore'
else
    alias ls='ls --color=auto --group-directories-first'
    alias ll='ls -lh'
    alias la='ls -lAh'
    alias l='ls -CF'
    alias lt='ls -lhtr'
    alias lS='ls -lhSr'
    alias l.='ls -d .*'
fi

# bat 替代 cat（--style=plain 保持接近原版输出，管道里自动退化为纯文本）
command -v bat >/dev/null && alias cat='bat --paging=never --style=plain'
alias rcat='command cat'                              # 需要原版 cat 时用
alias pcat='bat -pp'
bh() { "$@" --help 2>&1 | bat -p -l help; }           # bh git commit → 高亮的 --help

# ============================================================
# 1. 目录跳转（cd 由 zoxide 接管，见 ~/.bashrc 受管片段）
# ============================================================
#   cd proj      模糊跳到最常去的匹配目录
#   cd foo bar   多关键词匹配
#   cdi          fzf 交互式选择
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'

# mkdir + cd 合一（alias 做不到，必须用函数）
mkcd() {
    [[ -n "$1" ]] || { echo "usage: mkcd <directory>"; return 1; }
    mkdir -p -- "$1" && builtin cd -- "$1"
}

cl() { cd "$@" && ls; }                               # 跳转后 ls

up() {                                                # up 3 等价于 cd ../../..
    local n=${1:-1} dots="" i
    for ((i = 0; i < n; i++)); do dots+="../"; done
    builtin cd "$dots"
}

# ============================================================
# 2. 文件与目录管理
# ============================================================
alias mkdir='mkdir -pv'
alias md='mkdir -pv'
alias rd='rmdir'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'                                     # 删多个文件或递归时只问一次
alias ln='ln -iv'
alias chmod='chmod -v'

bak() { cp -iv -- "$1" "$1.bak"; }                    # bak file → file.bak

# 万能解压：tar 系和常见单文件格式用系统工具，其余交给 7zz / 7z
extract() {
    [[ -f "$1" ]] || { echo "'$1' is not a file"; return 1; }
    local sz; sz=$(command -v 7zz || command -v 7z || command -v 7za)
    case "$1" in
        *.tar|*.tar.*|*.tgz|*.tbz2|*.txz|*.tzst) tar xf "$1" ;;
        *.zip) unzip "$1" ;;
        *.gz)  gunzip "$1" ;;
        *.bz2) bunzip2 "$1" ;;
        *.xz)  unxz "$1" ;;
        *)
            [[ -n $sz ]] || { echo "no 7z available: sudo apt install p7zip-full"; return 1; }
            "$sz" x "$1"
            ;;
    esac
}
alias x='extract'

targz() { tar czf "${1%/}.tar.gz" "${1%/}"; }         # targz dir → dir.tar.gz
alias cleands='find . -name ".DS_Store" -type f -delete -print'   # 清理从 Mac 同步来的垃圾文件

# ============================================================
# 3. 查看与搜索
# ============================================================
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias less='less -R'
alias tailf='tail -f'
alias h='history'
alias hg='history | grep -i'
alias j='jobs -l'

ff() { find . -iname "*$1*" 2>/dev/null; }            # 按文件名找
ft() { grep -rniI --color=auto -- "$1" .; }           # 按内容找（find text）

# ============================================================
# 4. 磁盘、网络与系统信息
# ============================================================
alias df='df -h'
alias du='du -h'
alias du1='du -h --max-depth=1 | sort -h'
alias free='free -h'
alias ports="${_sudo}ss -tulnp"                       # 监听端口
alias myip='curl -s ifconfig.me; echo'
alias localip='hostname -I'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'
alias psg='pgrep -fai'                                # psg nginx
alias top10='ps aux --sort=-%mem | head -11'
alias cpu10='ps aux --sort=-%cpu | head -11'
alias gpu='watch -n1 nvidia-smi'
alias reload='source ~/.bashrc && echo "~/.bashrc reloaded."'
paths() { tr ':' '\n' <<<"$PATH"; }                   # 每行一个 PATH 项

# ============================================================
# 5. Ubuntu 专属：apt / systemd / 剪贴板
# ============================================================
alias aup="${_sudo}apt update && ${_sudo}apt upgrade"
alias ai="${_sudo}apt install"
alias arm="${_sudo}apt remove"
alias asr='apt search'
alias ashow='apt show'
alias aclean="${_sudo}apt autoremove --purge -y && ${_sudo}apt clean"

alias sc='systemctl'
alias scs='systemctl status'
alias scr="${_sudo}systemctl restart"
alias jf='journalctl -f -u'                           # jf nginx → 跟踪某个服务的日志
alias flushdns="${_sudo}resolvectl flush-caches"

# shcopy 通过 OSC52 把内容复制到本地剪贴板（SSH / tmux 内也有效）
if command -v shcopy >/dev/null; then
    alias copy='shcopy'                               # cat x | copy
    alias cpwd='pwd | tr -d "\n" | shcopy'            # 复制当前路径
fi

# ============================================================
# 6. Git
# ============================================================
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gca='git commit -am'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate -20'
alias gla='git log --oneline --graph --decorate --all'
alias gp='git push'
alias gpl='git pull --rebase'
alias gf='git fetch --all --prune'
alias gst='git stash'
alias gstp='git stash pop'
alias grs='git restore'
alias gundo='git reset --soft HEAD~1'                 # 撤销上次提交，保留改动

# ============================================================
# 7. Docker（不用可整段删除）
# ============================================================
alias dk='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlogs='docker logs -f --tail 100'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dprune='docker system prune -f'

# ============================================================
# 8. 开发
# ============================================================
alias py='python3'
alias serve='python3 -m http.server 8000'
alias json='python3 -m json.tool'                     # cat x.json | json
alias uvr='uv run'
alias uvs='uv sync'
alias uva='uv add'
venv() {                                              # 创建并激活 .venv（优先 uv）
    if command -v uv >/dev/null; then uv venv .venv; else python3 -m venv .venv; fi \
        && source .venv/bin/activate
}
alias va='source .venv/bin/activate'
if command -v vim >/dev/null; then alias v='vim'; else alias v='vi'; fi
alias e='${EDITOR:-vi}'

# ============================================================
# 9. tmux 与命令行效率
# ============================================================
alias ta='tmux new-session -A -s main'                # 有则 attach，无则新建
alias tl='tmux ls'
alias tk='tmux kill-session -t'
alias c='clear'
alias q='exit'
alias sudo='sudo '                                    # 让 sudo 后面的别名也生效
alias wget='wget -c'
alias mkpass='openssl rand -base64 16'
# 提权重跑上一条命令：sudo !!

# ============================================================
# 10. bash 行为
# ============================================================
for _o in autocd cdspell dirspell globstar histappend cmdhist checkwinsize; do
    shopt -s "$_o" 2>/dev/null
done
unset _o

HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups                      # 去重，空格开头的命令不入历史
HISTTIMEFORMAT='%F %T '
# 每条命令执行后立即写入历史，多个 tmux 窗格 / 终端之间不丢记录
[[ $PROMPT_COMMAND == *"history -a"* ]] || PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

if [[ $- == *i* ]]; then
    # 上下箭头按已输入前缀搜索历史（输入 git 后按 ↑ 只翻 git 开头的命令）
    bind '"\e[A": history-search-backward'
    bind '"\eOA": history-search-backward'
    bind '"\e[B": history-search-forward'
    bind '"\eOB": history-search-forward'
    bind 'set completion-ignore-case on'
    bind 'set show-all-if-ambiguous on'
    bind 'set colored-stats on'
    bind 'set mark-symlinked-directories on'
fi

# ============================================================
# 11. 用 bat 渲染 man 手册
# ============================================================
command -v bat >/dev/null && export MANPAGER="sh -c 'col -bx | bat -l man -p'"
EOF
}

# ---- ~/.bashrc 受管片段：只负责 PATH、环境变量和工具初始化 ----
config_bashrc() {
set_rc_block <<'EOF'
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

if [[ $- == *i* ]]; then
  # 别名 / 函数 / bash 行为
  [[ -f ~/.config/shell/shortcuts.bash ]] && source ~/.config/shell/shortcuts.bash

  # fzf：Ctrl+R 模糊搜历史，Ctrl+T 搜文件，Alt+C 搜目录
  if command -v fzf >/dev/null; then
    if fzf --bash >/dev/null 2>&1; then
      eval "$(fzf --bash)"
    else   # 较老的 Ubuntu LTS 里 apt 版 fzf 低于 0.48，没有 --bash，改用包自带脚本
      for _f in /usr/share/doc/fzf/examples/{key-bindings,completion}.bash; do
        [[ -f $_f ]] && source "$_f"
      done
      unset _f
    fi
  fi

  command -v starship >/dev/null && eval "$(starship init bash)"
  # zoxide 放在最后；--cmd cd 让 cd 本身具备模糊跳转能力
  command -v zoxide   >/dev/null && eval "$(zoxide init bash --cmd cd)"

  # 机器私有配置（不受本脚本管理）
  [[ -f ~/.bashrc.local ]] && source ~/.bashrc.local
fi
EOF
}

############################################
# 结果汇总
############################################
print_summary() {
  local c
  echo
  log "安装结果:"
  for c in "${CHECK_CMDS[@]}"; do
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

############################################
# main（放在最后调用：下载被截断时不会执行半截脚本）
############################################
main() {
  local t c
  mkdir -p "$BIN" "$CFG" "$SHELL_DIR"
  export PATH="$BIN:$PATH"
  setup_sudo

  step "apt 软件包" install_apt_packages
  step "fd / bat 软链" link_renamed_binaries
  for t in "${TOOLS[@]}";   do step "安装 $t" "install_$t"; done
  for c in "${CONFIGS[@]}"; do step "配置 $c"  "config_$c";  done

  print_summary
}

main "$@"
