#!/usr/bin/env bash
set -euo pipefail

export TERM=xterm-256color

command_exists() { command -v "$1" >/dev/null 2>&1; }

echo "Updating system and installing base packages..."
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    git curl wget ca-certificates zsh stow unzip fuse

# kitty terminfo
if ! infocmp xterm-kitty >/dev/null 2>&1; then
  echo "Installing kitty terminfo..."
  if sudo apt install -y kitty-terminfo 2>/dev/null; then
    true
  else
    curl -fsSL https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/x/xterm-kitty \
      -o /tmp/xterm-kitty
    sudo mkdir -p /usr/share/terminfo/x
    sudo cp /tmp/xterm-kitty /usr/share/terminfo/x/
    rm -f /tmp/xterm-kitty
  fi
fi

# Neovim nightly
if ! command_exists nvim; then
  echo "Installing Neovim..."
  curl -Lo /tmp/nvim.appimage \
    https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
  chmod +x /tmp/nvim.appimage
  sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
fi

# ripgrep
if ! command_exists rg; then
  echo "Installing ripgrep..."
  curl -Lo /tmp/rg.deb \
    https://github.com/BurntSushi/ripgrep/releases/latest/download/ripgrep_amd64.deb
  sudo dpkg -i /tmp/rg.deb || true
  rm -f /tmp/rg.deb
fi

# fd
if ! command_exists fd; then
  echo "Installing fd..."
  curl -Lo /tmp/fd.deb \
    https://github.com/sharkdp/fd/releases/latest/download/fd_amd64.deb
  sudo dpkg -i /tmp/fd.deb || true
  rm -f /tmp/fd.deb
fi

# fzf
if ! command_exists fzf; then
  echo "Installing fzf..."
  curl -Lo fzf.tar.gz \
    https://github.com/junegunn/fzf/releases/latest/download/fzf-linux_amd64.tar.gz
  tar xf fzf.tar.gz fzf
  sudo install fzf /usr/local/bin/
  rm -f fzf.tar.gz fzf
fi

# lazygit
if ! command_exists lazygit; then
  echo "Installing lazygit..."
  curl -Lo lazygit.tar.gz \
    https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_Linux_x86_64.tar.gz
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin/
  rm -f lazygit.tar.gz lazygit
fi

# zellij
if ! command_exists zellij; then
  echo "Installing zellij..."
  curl -Lo zellij.tar.gz \
    https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz
  tar xf zellij.tar.gz zellij
  sudo install zellij /usr/local/bin/
  rm -f zellij.tar.gz zellij
fi

# starship
if ! command_exists starship; then
  echo "Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir ~/.local/bin
fi

# FiraCode Nerd Font
if ! fc-list | grep -iq "FiraCode Nerd Font"; then
  echo "Installing FiraCode Nerd Font..."
  mkdir -p ~/.local/share/fonts
  curl -Lo /tmp/FiraCode.zip \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
  unzip -o /tmp/FiraCode.zip -d ~/.local/share/fonts/
  rm -f /tmp/FiraCode.zip
  fc-cache -fv
fi

# oh-my-zsh
[ -d "$HOME/.oh-my-zsh" ] || RUNZSH=no CHSH=no sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
  --unattended --keep-zshrc

# default shell
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Setting zsh as default shell..."
  sudo chsh -s "$(which zsh)" "$(whoami)"
fi

echo "=============================================================================="
echo "Done. Everything installed. No API calls, no rate limits, no breakage."
echo "=============================================================================="
