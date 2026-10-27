# proxy
alias proxy_off='unset http_proxy; unset https_proxy; unset all_proxy'
alias geph_proxy_on='export https_proxy=http://127.0.0.1:9910;export http_proxy=http://127.0.0.1:9910;export all_proxy=socks5://127.0.0.1:9909'
alias walless_proxy_on='export https_proxy=http://127.0.0.1:7897;export http_proxy=http://127.0.0.1:7897;export all_proxy=socks5://127.0.0.1:7897'
walless_proxy_on

# --- zsh config ---
# starship
eval "$(starship init zsh)"
# autoseggesutions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# zsh-completions
FPATH=/opt/homebrew/share/zsh-completions:$FPATH
autoload -Uz compinit && compinit

# mise
eval "$(mise activate zsh)"

# Golang
export PATH="$HOME/go/bin:$PATH"

# Character encoding
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# uv config
export UV_PYTHON_PREFERENCE=only-system
export UV_PYTHON_DOWNLOADS=never

# gpg config
export GPG_TTY=$(tty)

# my-aliases
[[ -f ~/.my_aliases ]] && source ~/.my_aliases

# activate zoxide
eval "$(zoxide init zsh --cmd cd)"

# replace original sed with gnu-sed (gnu-sed required)
if command -v gsed >/dev/null 2>&1; then
  alias sed='gsed'
else
  echo "gnu-sed not installed; using macOS /usr/bin/sed" >&2
fi

# shortcuts
[[ -f ~/.shortcuts.zsh ]] && source ~/.shortcuts.zsh

# zsh-syntax-highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/kcwen/.lmstudio/bin"
# End of LM Studio CLI section

# Local private config ~/.zshrc.local
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

