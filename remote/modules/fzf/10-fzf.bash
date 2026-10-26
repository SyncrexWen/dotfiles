# fzf：Ctrl+R 模糊搜历史，Ctrl+T 搜文件，Alt+C 搜目录
if command -v fzf >/dev/null; then
  if fzf --bash >/dev/null 2>&1; then
    eval "$(fzf --bash)"
  else   # 较老的 Ubuntu LTS 里 apt 版 fzf 低于 0.48，没有 --bash，改用包自带脚本
    for _f in /usr/share/doc/fzf/examples/{key-bindings,completion}.bash; do
      # shellcheck disable=SC1090  # 路径来自通配展开，无法静态跟踪
      [[ -f $_f ]] && source "$_f"
    done
    unset _f
  fi
fi
