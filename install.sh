#!/usr/bin/env bash
# Installs Oh My Zsh, Powerlevel10k and the zsh plugins, links the configs in this repo into $HOME,
# and makes zsh the login shell.
# Safe to re-run: anything already installed is skipped, and files it replaces go to ~/.dotfiles-backup/.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMZ="$HOME/.oh-my-zsh"
OMZ_CUSTOM="$OMZ/custom"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

for cmd in zsh git curl; do
  if ! command -v "$cmd" >/dev/null; then
    echo "Missing '$cmd'. Install the prerequisites first:"
    echo "  sudo apt update && sudo apt install -y zsh git curl"
    exit 1
  fi
done

if [ -d "$OMZ" ]; then
  echo "Oh My Zsh already installed"
else
  echo "Installing Oh My Zsh..."
  KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

clone() {
  local url="$1" dest="$2"
  if [ -d "$dest" ]; then
    echo "Already installed: $dest"
  else
    git clone --depth=1 "$url" "$dest"
  fi
}
clone https://github.com/romkatv/powerlevel10k.git             "$OMZ_CUSTOM/themes/powerlevel10k"
clone https://github.com/zsh-users/zsh-autosuggestions.git     "$OMZ_CUSTOM/plugins/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting"

link() {
  local src="$REPO/$1" dest="$2"
  if [ "$(readlink "$dest" 2>/dev/null)" = "$src" ]; then
    echo "Already linked: $dest"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP"
    mv "$dest" "$BACKUP/"
    echo "Backed up $dest to $BACKUP/"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "Linked $dest -> $src"
}
link shell/zshrc           "$HOME/.zshrc"
link shell/p10k.zsh        "$HOME/.p10k.zsh"
link shell/dircolors       "$HOME/.dircolors"
link shell/bashrc          "$HOME/.bashrc"
link oh-my-zsh/aliases.zsh "$OMZ_CUSTOM/aliases.zsh"

ZSH_PATH="$(command -v zsh)"
if [ "$(getent passwd "$USER" | cut -d: -f7)" = "$ZSH_PATH" ]; then
  echo "Login shell is already zsh"
else
  echo "Making zsh the login shell (asks for your password)..."
  chsh -s "$ZSH_PATH" || echo "chsh failed. Run it yourself: chsh -s $ZSH_PATH"
fi

echo
echo "Done. Close this terminal and open a new one."
