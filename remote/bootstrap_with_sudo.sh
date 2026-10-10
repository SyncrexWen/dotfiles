#!/usr/bin/env bash
# bootstrap_with_sudo.sh — Debian/Ubuntu 服务器一键配置（需要 sudo）
# 用法: bash bootstrap_with_sudo.sh   （可重复执行，幂等）
set -uo pipefail   # 故意不用 -e：单个工具失败不影响其他

BIN="$HOME/.local/bin"
CFG="$HOME/.config"
RC="$HOME/.bashrc"
MARK_CFG="# managed by bootstrap_with_sudo.sh"
export PATH="$BIN:$PATH" DEBIAN_FRONTEND=noninteractive
mkdir -p "$BIN" "$CFG"

log()  { printf '\033[1;34m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi
have apt-get || { warn "仅支持 Debian/Ubuntu (apt)"; exit 1; }
[ -n "$SUDO" ] && { $SUDO -v || { warn "需要 sudo 权限"; exit 1; }; }

# 写配置：已有且非本脚本生成的文件会先备份
write_cfg() {  # $1=目标路径，内容从 stdin 读取
  local dst="$1" tmp; tmp=$(mktemp)
  { echo "$MARK_CFG"; cat; } > "$tmp"
  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ] && ! grep -qF "$MARK_CFG" "$dst"; then
    mv "$dst" "$dst.bak.$(date +%s)"; warn "已备份原文件: $dst"
  fi
  install -m 644 "$tmp" "$dst"; rm -f "$tmp"
}

############################################
# apt packages
############################################
log "apt update & base packages"
$SUDO apt-get update -y
$SUDO apt-get install -y ca-certificates curl wget gpg

APT_PKGS=(tmux ripgrep fd-find bat btop tree pigz pv)
if ! $SUDO apt-get install -y "${APT_PKGS[@]}"; then
  warn "批量安装失败，改为逐个安装"
  for p in "${APT_PKGS[@]}"; do
    $SUDO apt-get install -y "$p" || warn "apt: $p 安装失败"
  done
fi

# Debian/Ubuntu 上 fd、bat 的二进制名不同，建软链
have fdfind && ! have fd  && ln -sf "$(command -v fdfind)" "$BIN/fd"
have batcat && ! have bat && ln -sf "$(command -v batcat)" "$BIN/bat"

############################################
# eza
############################################
install_eza() {
  have eza && return 0
  if apt-cache show eza >/dev/null 2>&1; then
    $SUDO apt-get install -y eza && return 0
  fi
  $SUDO mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | $SUDO gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | $SUDO tee /etc/apt/sources.list.d/gierens.list >/dev/null
  $SUDO chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  $SUDO apt-get update -y && $SUDO apt-get install -y eza
}
install_eza || { warn "eza 安装失败"; $SUDO rm -f /etc/apt/sources.list.d/gierens.list; }

############################################
# shcopy
############################################
install_shcopy() {
  have shcopy && return 0
  echo 'deb [trusted=yes] https://repo.aymanbagabas.com/apt/ /' \
    | $SUDO tee /etc/apt/sources.list.d/aymanbagabas.list >/dev/null
  $SUDO apt-get update -y && $SUDO apt-get install -y shcopy
}
install_shcopy || { warn "shcopy 安装失败"; $SUDO rm -f /etc/apt/sources.list.d/aymanbagabas.list; }

############################################
# zoxide / starship / uv
############################################
have zoxide   || curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh \
  || warn "zoxide 安装失败"
have starship || curl -sSfL https://starship.rs/install.sh | sh -s -- -y -b "$BIN" \
  || warn "starship 安装失败"
have uv       || curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh \
  || warn "uv 安装失败"

############################################
# 配置文件
############################################
log "writing configs"

# ---- tmux ----
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

# ---- starship ----
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

# ---- ripgrep ----
write_cfg "$CFG/ripgrep/config" <<'EOF'
--smart-case
--max-columns=200
--max-columns-preview
EOF

# ---- btop ----
if [ ! -f "$CFG/btop/btop.conf" ]; then
  mkdir -p "$CFG/btop"
  printf 'theme_background = False\nupdate_ms = 1000\n' > "$CFG/btop/btop.conf"
fi

# ---- ~/.bashrc 片段 ----
BEGIN="# >>> dotfiles-remote >>>"
END="# <<< dotfiles-remote <<<"
touch "$RC"
sed -i "\|$BEGIN|,\|$END|d" "$RC"
cat >> "$RC" <<'EOF'
# >>> dotfiles-remote >>>
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

if [[ $- == *i* ]]; then
  HISTSIZE=100000; HISTFILESIZE=200000
  HISTCONTROL=ignoreboth:erasedups
  shopt -s histappend checkwinsize

  # bat 替代 cat（管道/重定向时自动退化为纯文本；需要原版用 \cat）
  command -v bat >/dev/null && alias cat='bat --paging=never --style=plain'

  # eza 替代 ls
  if command -v eza >/dev/null; then
    alias ls='eza --group-directories-first'
    alias ll='eza -lah --git --group-directories-first'
    alias lt='eza --tree --level=2'
  fi

  alias ta='tmux new-session -A -s main'   # 有则 attach，无则新建
  alias gpu='watch -n1 nvidia-smi'

  command -v starship >/dev/null && eval "$(starship init bash)"
  command -v zoxide   >/dev/null && eval "$(zoxide init bash)"
fi
# <<< dotfiles-remote <<<
EOF

############################################
# 结果检查
############################################
echo
log "安装结果:"
for c in tmux rg fd bat eza zoxide starship btop tree shcopy uv pigz pv; do
  if have "$c"; then printf '  \033[32m✓\033[0m %s\n' "$c"
  else               printf '  \033[31m✗\033[0m %s\n' "$c"; fi
done
echo
log "完成。执行 'source ~/.bashrc' 或重新登录生效。"