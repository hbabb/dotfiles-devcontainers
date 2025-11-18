#!/usr/bin/env bash
set -euo pipefail

command_exists() { command -v "$1" >/dev/null 2>&1; }

echo "Updating system and installing base packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget ca-certificates zsh stow unzip

# Neovim (latest unstable)
if ! command_exists nvim; then
  echo "Installing latest Neovim..."
  sudo add-apt-repository -y ppa:neovim-ppa/unstable
  sudo apt update
  sudo apt install -y neovim
fi

# ripgrep (latest .deb)
if ! command_exists rg; then
  echo "Installing ripgrep..."
  RG_VERSION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -oE '"tag_name": "[^"]+"' | cut -d'"' -f4)
  curl -Lo /tmp/rg.deb "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep_${RG_VERSION}_$(dpkg --print-architecture).deb"
  sudo dpkg -i /tmp/rg.deb && rm -f /tmp/rg.deb
fi

# fd (latest .deb)
if ! command_exists fd; then
  echo "Installing fd..."
  FD_VERSION=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep -oE '"tag_name": "[^"]+"' | cut -d'"' -f4)
  curl -Lo /tmp/fd.deb "https://github.com/sharkdp/fd/releases/download/${FD_VERSION}/fd_${FD_VERSION#v}_$(dpkg --print-architecture).deb"
  sudo dpkg -i /tmp/fd.deb && rm -f /tmp/fd.deb
fi

# fzf (latest binary)
if ! command_exists fzf; then
  echo "Installing fzf..."
  FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep -oE '"tag_name": "[^"]+"' | cut -d'"' -f4)
  curl -Lo fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION}-linux_$(dpkg --print-architecture).tar.gz"
  tar xzf fzf.tar.gz fzf
  sudo install fzf /usr/local/bin/fzf
  rm -f fzf fzf.tar.gz
fi

# lazygit
if ! command_exists lazygit; then
  echo "Installing lazygit..."
  LG_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -oE '"tag_name": "[^"]+"' | cut -d'"' -f4)
  ARCH=$(dpkg --print-architecture)
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/${LG_VERSION}/lazygit_${LG_VERSION#v}_Linux_${ARCH}.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin/lazygit
  rm -f lazygit lazygit.tar.gz
fi

# zellij
if ! command_exists zellij; then
  echo "Installing zellij..."
  ARCH=$(dpkg --print-architecture)
  ZJ_ARCH=$( [ "$ARCH" = "amd64" ] && echo "x86_64" || echo "aarch64" )
  curl -Lo zellij.tar.gz "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${ZJ_ARCH}-unknown-linux-musl.tar.gz"
  tar xf zellij.tar.gz zellij
  sudo install zellij /usr/local/bin/zellij
  rm -f zellij zellij.tar.gz
fi

# starship (user-local)
if ! command_exists starship; then
  echo "Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir ~/.local/bin
fi

# FiraCode Nerd Font
if ! fc-list | grep -iq "FiraCode Nerd Font"; then
  echo "Installing FiraCode Nerd Font..."
  mkdir -p ~/.local/share/fonts
  curl -Lo "/tmp/FiraCode.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
  unzip -o "/tmp/FiraCode.zip" -d ~/.local/share/fonts/
  fc-cache -fv
  rm -f "/tmp/FiraCode.zip"
fi

# oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing oh-my-zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended --keep-zshrc
fi

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Setting zsh as default shell..."
  sudo chsh -s "$(which zsh)" "$(whoami)"
fi

echo "Everything installed! Run 'stow .' to apply your dotfiles."
