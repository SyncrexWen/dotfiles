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
