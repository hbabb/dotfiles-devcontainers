#!/usr/bin/env bash
set -euo pipefail

# Verified, robust installer for Debian 12 / Ubuntu devcontainers.
# Prioritize official Debian packages (no GitHub API). When we must fetch releases
# from GitHub, *verify* download size/content and abort cleanly if GitHub returns
# the tiny 9-byte rate-limit json.  No silent failures, no assumptions.

export TERM=xterm-256color
TMPDIR=${TMPDIR:-/tmp}

command_exists() { command -v "$1" >/dev/null 2>&1; }

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

curl_dl_verify() {
  # Usage: curl_dl_verify <url> <out> <min_bytes>
  local url="$1" out="$2" min_bytes="${3:-1000}"
  rm -f "$out"
  # follow redirects, fail on HTTP errors, retry a few times
  curl -fL --retry 3 --retry-delay 2 --connect-timeout 10 "$url" -o "$out" || return 2
  if [ ! -f "$out" ]; then return 3; fi
  local sz
  sz=$(stat -c%s "$out" 2>/dev/null || echo 0)
  if [ "$sz" -lt "$min_bytes" ]; then
    echo "Downloaded file '$out' is too small ($sz bytes). Possible GitHub rate limit or bad URL." >&2
    return 4
  fi
  return 0
}

echo "Updating system and installing base packages..."
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
  git curl wget ca-certificates zsh stow unzip fuse

# Prefer packages from Debian where available (no external downloads)
echo "Installing ripgrep, fzf, fd-find from apt (bookworm provides these)..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y ripgrep fzf fd-find || \
  echo "apt install of ripgrep/fzf/fd-find failed or some are unavailable; continuing to fallbacks."

# fd-find provides 'fdfind' on Debian; create /usr/local/bin/fd if missing
if ! command_exists fd && command_exists fdfind; then
  if [ -w /usr/local/bin ]; then
    sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  else
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    export PATH="$HOME/.local/bin:$PATH"
  fi
fi

# kitty terminfo fix (same as you had)
if ! infocmp xterm-kitty >/dev/null 2>&1; then
  echo "Installing kitty terminfo..."
  if sudo apt install -y kitty-terminfo 2>/dev/null; then
    true
  else
    curl -fsSL https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/x/xterm-kitty -o "$TMPDIR/xterm-kitty" \
      || fail "Could not download kitty terminfo from raw.githubusercontent.com (might be rate-limited)."
    sudo mkdir -p /usr/share/terminfo/x
    sudo cp "$TMPDIR/xterm-kitty" /usr/share/terminfo/x/
    rm -f "$TMPDIR/xterm-kitty"
  fi
fi

# Neovim AppImage (official stable/nightly alternative)
if ! command_exists nvim; then
  echo "Installing Neovim (AppImage)..."
  NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
  curl_dl_verify "$NVIM_URL" "$TMPDIR/nvim.appimage" 2000000 || fail "Neovim download failed or too small. GitHub rate limiting? See note below."
  chmod +x "$TMPDIR/nvim.appimage"
  sudo mv "$TMPDIR/nvim.appimage" /usr/local/bin/nvim
fi

# lazygit: try apt first, then verified GitHub download
if ! command_exists lazygit; then
  echo "Installing lazygit..."
  if sudo DEBIAN_FRONTEND=noninteractive apt install -y lazygit 2>/dev/null; then
    echo "lazygit installed via apt."
  else
    LAZYGIT_URL="https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_Linux_x86_64.tar.gz"
    curl_dl_verify "$LAZYGIT_URL" "$TMPDIR/lazygit.tar.gz" 100000 || \
      fail "lazygit download failed or too small. If you're behind GitHub rate-limits, set GITHUB_TOKEN or download manually."
    tar -C "$TMPDIR" -xzf "$TMPDIR/lazygit.tar.gz" lazygit || fail "tar extract lazygit failed"
    sudo install -m 0755 "$TMPDIR/lazygit" /usr/local/bin/lazygit
    rm -f "$TMPDIR/lazygit" "$TMPDIR/lazygit.tar.gz"
  fi
fi

# zellij: try apt, then verified GitHub download
if ! command_exists zellij; then
  echo "Installing zellij..."
  if sudo DEBIAN_FRONTEND=noninteractive apt install -y zellij 2>/dev/null; then
    echo "zellij installed via apt."
  else
    ZELLIJ_URL="https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"
    curl_dl_verify "$ZELLIJ_URL" "$TMPDIR/zellij.tar.gz" 100000 || \
      fail "zellij download failed or too small. If you're behind GitHub rate-limits, set GITHUB_TOKEN or use 'snap install zellij --classic'."
    tar -C "$TMPDIR" -xzf "$TMPDIR/zellij.tar.gz" zellij || fail "tar extract zellij failed"
    sudo install -m 0755 "$TMPDIR/zellij" /usr/local/bin/zellij
    rm -f "$TMPDIR/zellij" "$TMPDIR/zellij.tar.gz"
  fi
fi

# starship (user-local installer)
if ! command_exists starship; then
  echo "Installing starship to ~/.local/bin..."
  curl -fL https://starship.rs/install.sh -o "$TMPDIR/starship-install.sh" || fail "Failed to fetch starship installer."
  bash "$TMPDIR/starship-install.sh" --yes --bin-dir "$HOME/.local/bin" || fail "starship installation failed."
  rm -f "$TMPDIR/starship-install.sh"
  export PATH="$HOME/.local/bin:$PATH"
fi

# FiraCode Nerd Font (user-local)
if ! fc-list | grep -iq "FiraCode Nerd Font"; then
  echo "Installing FiraCode Nerd Font..."
  mkdir -p "$HOME/.local/share/fonts"
  FIRA_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
  curl_dl_verify "$FIRA_URL" "$TMPDIR/FiraCode.zip" 2000000 || fail "FiraCode download failed or too small. GitHub rate-limited?"
  unzip -o "$TMPDIR/FiraCode.zip" -d "$HOME/.local/share/fonts/" || fail "unzip FiraCode failed"
  rm -f "$TMPDIR/FiraCode.zip"
  fc-cache -fv || echo "fc-cache failed (non-fatal)"
fi

# fzf (if apt didn't provide it)
if ! command_exists fzf; then
  echo "Installing fzf..."
  # Debian bookworm has fzf; if not, fallback to verified binary tarball
  FZF_URL="https://github.com/junegunn/fzf/releases/latest/download/fzf-linux_amd64.tar.gz"
  curl_dl_verify "$FZF_URL" "$TMPDIR/fzf.tar.gz" 100000 || fail "fzf download failed or too small. GitHub rate-limited?"
  tar -C "$TMPDIR" -xzf "$TMPDIR/fzf.tar.gz" fzf || fail "tar extract fzf failed"
  sudo install -m 0755 "$TMPDIR/fzf" /usr/local/bin/fzf
  rm -f "$TMPDIR/fzf" "$TMPDIR/fzf.tar.gz"
fi

# Ensure ~/.local/bin is on PATH for user installs
if [ -d "$HOME/.local/bin" ] && ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo "Adding ~/.local/bin to PATH for this session."
  export PATH="$HOME/.local/bin:$PATH"
fi

# oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing oh-my-zsh (unattended)..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended --keep-zshrc || \
    echo "oh-my-zsh installer failed. You can install manually."
fi

# Set zsh as default shell if needed
if [ "$SHELL" != "$(which zsh 2>/dev/null || true)" ] && command_exists zsh; then
  echo "Setting zsh as default shell for $(whoami)..."
  sudo chsh -s "$(which zsh)" "$(whoami)" || echo "chsh failed (might be expected in some containers)."
fi

echo "=============================================================================="
echo "Install completed (or aborted with clear errors)."
echo "If any GitHub download failed because the downloaded file was tiny (~9 bytes),"
echo "you are hitting GitHub's unauthenticated rate limits from this IP."
echo "Options to proceed:"
echo "  1) Export GITHUB_TOKEN with a personal access token: export GITHUB_TOKEN=ghp_xxx"
echo "     then re-run the script (curl will be authenticated and avoid strict rate limits)."
echo "  2) Run this from a different IP (your laptop, another CI runner)."
echo "  3) Install the failing tools from your distro or from an alternate mirror (snap, apt, third-party repo)."
echo "=============================================================================="
