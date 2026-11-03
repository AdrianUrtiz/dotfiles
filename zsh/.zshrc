# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="powerlevel10k/powerlevel10k"
ZSH_THEME="awesomepanda"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-history-substring-search
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"



[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# pnpm
export PNPM_HOME="/home/adrian/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# fnm
FNM_PATH="/home/adrian/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/adrian/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi

eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

PATH=~/.console-ninja/.bin:$PATH

unalias ant 2>/dev/null
ant() {
  nohup antigravity-ide "$@" > /dev/null 2>&1 &|
}
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"


# Added by Antigravity CLI installer
export PATH="/home/adrian/.local/bin:$PATH"

# Shift+Flechas estilo Warp: seleccionar texto del comando (Ghostty deja
# pasar estas teclas cuando no hay selección activa en el terminal)
shift-select-left() {
  ((REGION_ACTIVE)) || zle set-mark-command
  zle backward-char
}
shift-select-right() {
  ((REGION_ACTIVE)) || zle set-mark-command
  zle forward-char
}
# Shift+Arriba/Abajo: extiende por líneas lógicas solo si el comando
# es multilínea. En una sola línea no hay a dónde subir/bajar (zsh no
# tiene líneas visuales como Warp), así que no hace nada en vez de
# traerse una entrada del historial y pisar lo que escribiste.
shift-select-up() {
  [[ "$BUFFER" == *$'\n'* ]] || return 0
  ((REGION_ACTIVE)) || zle set-mark-command
  zle up-line
}
shift-select-down() {
  [[ "$BUFFER" == *$'\n'* ]] || return 0
  ((REGION_ACTIVE)) || zle set-mark-command
  zle down-line
}
zle -N shift-select-left
zle -N shift-select-right
zle -N shift-select-up
zle -N shift-select-down
bindkey "^[[1;2D" shift-select-left    # shift+izquierda
bindkey "^[[1;2C" shift-select-right   # shift+derecha
bindkey "^[[1;2A" shift-select-up      # shift+arriba
bindkey "^[[1;2B" shift-select-down    # shift+abajo
# Alt+Shift+Flechas: seleccionar por palabras (rápido para texto largo).
# (Ctrl+Shift+flechas ya son cambio de tab en Ghostty, por eso Alt.)
shift-select-word-left() {
  ((REGION_ACTIVE)) || zle set-mark-command
  zle backward-word
}
shift-select-word-right() {
  ((REGION_ACTIVE)) || zle set-mark-command
  zle forward-word
}
zle -N shift-select-word-left
zle -N shift-select-word-right
bindkey "^[[1;4D" shift-select-word-left   # alt+shift+izquierda
bindkey "^[[1;4C" shift-select-word-right  # alt+shift+derecha
# Shift+Enter: salto de línea sin ejecutar el comando
insert-newline-noexec() {
  LBUFFER+=$'\n'
}
zle -N insert-newline-noexec
bindkey "^[[27;2;13~" insert-newline-noexec  # shift+enter (confirmado con cat -v)
bindkey "^[[13;2u" insert-newline-noexec     # shift+enter (Kitty, cuando el protocolo está activo)

# Edición estilo Warp sobre la selección del comando:
# - Backspace/Supr borran la selección completa (no solo 1 char)
# - Escribir reemplaza la selección
# - Ctrl+A selecciona todo el comando
# - Alt+C copia la selección al portapapeles del sistema
_warp-backward-delete() {
  if ((REGION_ACTIVE)); then
    zle kill-region
  else
    zle .backward-delete-char
  fi
}
_warp-delete-char() {
  if ((REGION_ACTIVE)); then
    zle kill-region
  else
    zle .delete-char
  fi
}
_warp-self-insert() {
  ((REGION_ACTIVE)) && zle kill-region
  zle .self-insert
}
select-all-buffer() {
  CURSOR=0
  zle set-mark-command
  CURSOR=${#BUFFER}
}
copy-command-selection() {
  if ((REGION_ACTIVE)); then
    zle copy-region-as-kill
    if command -v wl-copy >/dev/null; then
      print -rn -- "$CUTBUFFER" | wl-copy
    else
      print -rn -- "$CUTBUFFER" | xsel --clipboard --input
    fi
  fi
}
zle -N backward-delete-char _warp-backward-delete
zle -N delete-char _warp-delete-char
zle -N self-insert _warp-self-insert
zle -N select-all-buffer
zle -N copy-command-selection
bindkey "^A" select-all-buffer  # ctrl+a (antes: inicio de línea; Home sigue funcionando)
bindkey "^[c" copy-command-selection  # alt+c
# Ctrl+Shift+C sin selección de terminal: Ghostty lo deja pasar al shell
# como secuencia Kitty ("...;6u"). Si hay selección del comando la copia,
# si no, se traga la secuencia para que no ensucie el prompt.
copy-or-swallow-csi-u() {
  if ((REGION_ACTIVE)); then
    zle copy-region-as-kill
    if command -v wl-copy >/dev/null; then
      print -rn -- "$CUTBUFFER" | wl-copy
    else
      print -rn -- "$CUTBUFFER" | xsel --clipboard --input
    fi
  fi
}
zle -N copy-or-swallow-csi-u
# Secuencia confirmada con `cat -v`: ^[[99;6u (más variante con evento explícito)
bindkey "^[[99;6u" copy-or-swallow-csi-u
bindkey "^[[99;6:1u" copy-or-swallow-csi-u


# Título de Ghostty: solo la ruta actual, abreviando HOME como ~.
_ghostty_prompt_title() {
  local title="${PWD/#$HOME/~}"
  printf "\e]0;%s\a" "$title"
}
add-zsh-hook -d precmd _ghostty_prompt_title 2>/dev/null
add-zsh-hook -d chpwd _ghostty_prompt_title 2>/dev/null
add-zsh-hook precmd _ghostty_prompt_title
add-zsh-hook chpwd _ghostty_prompt_title
