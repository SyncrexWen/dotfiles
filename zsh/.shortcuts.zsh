# ~/.shortcuts.zsh —— zsh shortcuts (source only, do not execute)

# ============================================================
# 0. replace builtin commands with modern alternatives (ls->eza, cat->bat)
# ============================================================
if command -v eza >/dev/null; then
    alias ls='eza --icons=always'
else
    alias ls='ls -G'
fi
command -v bat >/dev/null && alias cat='bat'

alias rcat='command cat'
alias pcat='bat -pp'
bh() { "$@" --help 2>&1 | bat -p -l help; }

# ============================================================
# 1. directory listing
# ============================================================
alias ll='eza -l --icons=always --git --header --group-directories-first'
alias la='eza -la --icons=always --git --header --group-directories-first'
alias l='eza -F --icons=always --group-directories-first'
alias lt='eza -l --icons=always --sort=modified'
alias lS='eza -l --icons=always --sort=size'
alias l.='eza -d --icons=always .*'
alias tree='eza --tree --icons=always --git-ignore'
alias tree2='eza --tree --level=2 --icons=always --git-ignore'

# ============================================================
# 2. zoxide navigation
# ============================================================
# zoxide usage (alias cd):
#   cd proj      cd to a fzf directory
#   cd foo bar   multi-word search
#   cdi          fzf itereactive search
#   cd -         cd to previous directory
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'
alias d='dirs -v'

mkcd() {
    [[ -n "$1" ]] || { echo "usage: mkcd <directory>"; return 1; }
    mkdir -p -- "$1" && builtin cd -- "$1"
}

cl() { cd "$@" && ls; }

# ============================================================
# 3. file and directory management
# ============================================================
alias mkdir='mkdir -pv'
alias md='mkdir -pv'
alias rd='rmdir'
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -Iv'
alias ln='ln -iv'
alias chmod='chmod -v'

bak() { cp -iv -- "$1" "$1.bak"; }

# general extract (brew install unrar sevenzip)
extract() {
    [[ -f "$1" ]] || { echo "'$1' is not a file"; return 1; }
    local keka=/Applications/Keka.app/Contents/MacOS/Keka

    case "$1" in
        *.tar|*.tar.*|*.tgz|*.tbz2|*.txz)
            tar xf "$1"
            ;;
        *)
            if (( $+commands[7zz] )); then
                7zz x "$1"
            elif [[ -x $keka ]]; then
                "$keka" --cli 7zz x "$1"
            else
                echo "no available extraction tools, brew install sevenzip is recommanded"; return 1
            fi
            ;;
    esac
}
alias x='extract'

targz() { tar czf "${1%/}.tar.gz" "${1%/}"; }

# ============================================================
# 4. inspection and search
# ============================================================
alias grep='grep --color=auto'
alias less='less -R'
alias tailf='tail -f'
alias h='history 1'
alias hg='history 1 | grep -i'
alias j='jobs -l'

ff() { find . -iname "*$1*" 2>/dev/null; }
ft() { grep -rniI --color=auto -- "$1" .; }

# ============================================================
# 5. disk, network, and system info
# ============================================================
alias df='df -h'
alias du='du -h'
alias du1='du -h -d 1 | sort -h'
alias paths='print -l ${(s/:/)PATH}'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'
alias psg='pgrep -fil'
alias top10='ps -Amo pid,%mem,%cpu,comm | head -11'
alias cpu10='ps -Aro pid,%cpu,%mem,comm | head -11'
alias reload='source ~/.zshrc && echo "~/.zshrc reloaded."'

# ============================================================
# 6. macOS features
# ============================================================
alias o='open'
alias oo='open .'
alias copy='pbcopy'
alias paste='pbpaste'
alias cpwd='pwd | tr -d "\n" | pbcopy'
alias caff='caffeinate -d'
alias lock='pmset displaysleepnow'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
alias cleands='find . -name ".DS_Store" -type f -delete -print'
alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'

# Homebrew
alias bi='brew install'
alias bci='brew install --cask'
alias bs='brew search'
alias bup='brew update && brew upgrade && brew cleanup'
alias bu='brew uninstall'

# ============================================================
# 7. Git
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
alias gundo='git reset --soft HEAD~1'

# ============================================================
# 8. development
# ============================================================
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv .venv && source .venv/bin/activate'
alias va='source .venv/bin/activate'
alias serve='python3 -m http.server 8000'
alias json='python3 -m json.tool'             # cat x.json | json
alias v='vim'
alias e='${EDITOR:-vim}'

# ============================================================
# 9. cli tools
# ============================================================
alias c='clear'
alias q='exit'
alias sudo='sudo '
alias wget='wget -c'
alias mkpass='openssl rand -base64 16'

# ============================================================
# 10. zsh configuration
# ============================================================
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTSIZE=50000
SAVEHIST=100000
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select

if [[ -o interactive ]]; then
    autoload -U up-line-or-beginning-search down-line-or-beginning-search
    zle -N up-line-or-beginning-search
    zle -N down-line-or-beginning-search
    bindkey '^[[A' up-line-or-beginning-search
    bindkey '^[OA' up-line-or-beginning-search
    bindkey '^[[B' down-line-or-beginning-search
    bindkey '^[OB' down-line-or-beginning-search
fi

# ============================================================
# 11. bat reader for man pages
# ============================================================
command -v bat >/dev/null && export MANPAGER="sh -c 'col -bx | bat -l man -p'"

command -v fzf >/dev/null && source <(fzf --zsh)
