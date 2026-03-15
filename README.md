# SyncrexWen's Dotfiles

个人系统与开发环境配置文件，使用 [GNU Stow](https://www.gnu.org/software/stow/) 进行管理。

## 包含的配置 (Components)

这个仓库包含了以下工具的配置文件：

* **窗口管理 & 终端**
  * `aerospace/`: macOS 平铺式窗口管理器配置
  * `wezterm/`: GPU 加速的跨平台终端模拟器配置
  * `starship/`: 跨 Shell 的定制化命令提示符配置
* **Shell & Git**
  * `zsh/`: Zsh 配置文件 (如 `.zshrc`)
  * `git/`: Git 全局配置 (如 `.gitconfig`)
* **编辑器 & 开发环境**
  * `nvim/`: Neovim 配置文件
  * `vscode/`: Visual Studio Code 用户设置及快捷键
  * `docker/`: Docker 相关配置
* **包管理**
  * `Brewfile`: Homebrew 依赖清单，用于快速恢复安装的软件包
* **脚本**
  * `install_vscode_extensions.sh`: 一键安装 VS Code 常用插件的脚本

## 安装与使用 (Installation)

### 1. 克隆仓库

```bash
git clone [https://github.com/SyncrexWen/dotfiles.git](https://github.com/SyncrexWen/dotfiles.git) ~/.dotfiles
cd ~/.dotfiles
```

### 2. 使用 Stow 建立软链接

使用 `stow` 命令将配置软链接到 Home 目录。例如，应用 `zsh` 和 `git` 的配置：

```bash
stow -d ~/.dotfiles -t ~ zsh
stow -d ~/.dotfiles -t ~ git
```

*如果你想一次性应用所有配置（请先确保 Home 目录下没有冲突的文件）：*

```bash
stow -d ~/.dotfiles -t ~ */
```

### 3. 恢复环境依赖

**恢复 Homebrew 软件包：**

```bash
brew bundle --file=Brewfile
```

**安装 VS Code 插件：**

```bash
chmod +x install_vscode_extensions.sh
./install_vscode_extensions.sh
```


