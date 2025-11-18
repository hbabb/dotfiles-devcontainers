#!/usr/bin/env bash
set -euo pipefail

# Force a safe TERM during the entire install (prevents immediate breakage)
export TERM=xterm-256color

command_exists() { command -v "$1" >/dev/null 2>&1; }

echo "Updating system and installing base packages..."
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    git curl wget ca-certificates zsh stow unzip fuse

# Fix kitty terminfo if the container starts with TERM=xterm-kitty (common in VS Code devcontainers)
if ! infocmp xterm-kitty >/dev/null 2>&1; then
  echo "Installing kitty terminfo..."
  if sudo apt install -y kitty-terminfo 2>/dev/null; then
    true
  else
    # Fallback: download terminfo directly
    curl -fsSL https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/x/xterm-kitty \
      -o /tmp/xterm-kitty
    sudo mkdir -p /usr/share/terminfo/x
    sudo cp /tmp/xterm-kitty /usr/share/terminfo/x/
    rm -f /tmp/xterm-kitty
  fi
fi

# Neovim nightly (AppImage – zero dependency hell on Debian)
if ! command_exists nvim; then
  echo "Installing latest Neovim nightly (AppImage)..."
  curl -Lo /tmp/nvim.appimage https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage
  chmod +x /tmp/nvim.appimage
  sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
fi

# ripgrep
if ! command_exists rg; then
  echo "Installing ripgrep..."
  RG_VER=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -oE '"tag_name": "[^"]+"' | cut -d'"' -f4)
  curl -Lo /tmp/rg.deb "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VER}/ripgrep_${RG_VER}_$(dpkg --print-architecture).deb"
  sudo dpkg -i /tmp/rg.deb && rm -f /tmp/rg.deb
fi

# fd
if ! command_exists fd; then
  echo "Installing fd..."
  FD_VER=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep -oE '"tag_name": "[^"]+"' | cut -d'"' -f4)
  curl -Lo /tmp/fd.deb "https://github.com/sharkdp/fd/releases/download/${FD_VER}/fd_${FD_VER#v}_$(dpkg --print-architecture).deb"
  sudo dpkg -i /tmp/fd.deb && rm -f /tmp/fd.deb
fi

# fzf
if ! command_exists fzf; then
  echo "Installing fzf..."
  FZF_VER=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep -oE '"tag_name": "[^"]+"' | cut -d'"' -f4)
  curl -Lo fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/${FZF_VER}/fzf-${FZF_VER}-linux_$(dpkg --print-architecture).tar.gz"
  tar xzf fzf.tar.gz fzf
  sudo install fzf /usr/local/bin/
  rm -f fzf fzf.tar.gz
fi

# lazygit
if ! command_exists lazygit; then
  echo "Installing lazygit..."
  LG_VER=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -oE '"tag_name": "[^"]+"' | cut -d'"' -f4)
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/${LG_VER}/lazygit_${LG_VER#v}_Linux_$(dpkg --print-architecture).tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin/
  rm -f lazygit lazygit.tar.gz
fi

# zellij
if ! command_exists zellij; then
  echo "Installing zellij..."
  ARCH=$(dpkg --print-architecture | sed 's/amd64/x86_64/;s/arm64/aarch64/')
  curl -Lo zellij.tar.gz "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${ARCH}-unknown-linux-musl.tar.gz"
  tar xf zellij.tar.gz zellij
  sudo install zellij /usr/local/bin/
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
  curl -Lo /tmp/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
  unzip -o /tmp/FiraCode.zip -d ~/.local/share/fonts/
  fc-cache -fv
  rm -f /tmp/FiraCode.zip
fi

# oh-my-zsh
[ -d "$HOME/.oh-my-zsh" ] || RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended --keep-zshrc

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Setting zsh as default shell..."
  sudo chsh -s "$(which zsh)" "$(whoami)"
fi

echo "=============================================================================="
echo "All tools installed successfully!"
echo "Now run: stow .   (or whatever your dotfiles command is)"
echo "You can now safely use nano, nvim, zellij, etc. – kitty terminal is fixed too."
echo "=============================================================================="
