# proxy
alias proxy_off='unset http_proxy; unset https_proxy; unset all_proxy'
alias proxy_on='export https_proxy=http://127.0.0.1:9910;export http_proxy=http://127.0.0.1:9910;export all_proxy=socks5://127.0.0.1:9909'

# --- zsh config ---
# starship
eval "$(starship init zsh)"
# autoseggesutions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# zsh-syntax-highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# zsh-completions
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit
fi
# Eza: better ls
alias ls='eza --icons=always'
# zoxide: better cd
eval "$(zoxide init zsh --cmd cd)"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniforge/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniforge/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# mise
eval "$(mise activate zsh)"

# Golang
export PATH="$HOME/go/bin:$PATH"

# bat: batter cat
alias cat='bat'

# Character encoding
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# uv config
export UV_PYTHON_PREFERENCE=only-system
export UV_PYTHON_DOWNLOADS=never

