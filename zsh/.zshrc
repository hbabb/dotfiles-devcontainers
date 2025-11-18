# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Path to your Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# Plugins
plugins=(git docker npm pep8 pip pyenv systemd zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# Load default config files (like Omarchy)
source ~/dotfiles/zsh/.config/zsh/shell
source ~/dotfiles/zsh/.config/zsh/aliases
source ~/dotfiles/zsh/.config/zsh/functions
source ~/dotfiles/zsh/.config/zsh/envs
source ~/dotfiles/zsh/.config/zsh/init

# Persona overrides
# aliases
alias lg='lazygit'
alias vim='nvim'
alias vi='nvim'

# Editor
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

