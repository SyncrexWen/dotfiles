# zoxide 放在最后；--cmd cd 让 cd 本身具备模糊跳转能力
command -v zoxide   >/dev/null && eval "$(zoxide init bash --cmd cd)"
