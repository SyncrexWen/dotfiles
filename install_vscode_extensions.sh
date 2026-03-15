#!/bin/bash
echo "Installing VS Code extensions..."
cat ~/.dotfiles/vscode/extensions.txt | grep -v '^#' | xargs -L 1 code --install-extension
echo "Extensions all installed."
