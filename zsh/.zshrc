
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.opencode/bin"
  "$HOME/.rbenv/bin"
  $path
)
export PATH

if (( $+commands[rbenv] )); then
  eval "$(rbenv init - zsh)"
fi

if (( $+commands[ruby] )); then
  _gem_dir="$(ruby -r rubygems -e 'print Gem.user_dir' 2>/dev/null)"
  [[ -n "$_gem_dir" ]] && path=("$_gem_dir/bin" $path)
  unset _gem_dir
fi

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INTERACTIVE_COMMENTS
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt COMPLETE_IN_WORD
setopt PROMPT_SUBST

unsetopt BEEP

autoload -Uz colors
colors

autoload -Uz compinit
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

zmodload zsh/complist

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{cyan}%d%f'
zstyle ':completion:*' verbose yes
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion"
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' special-dirs true

if (( $+commands[dircolors] )); then
  eval "$(dircolors -b)"
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

bindkey -e

bindkey '^I' expand-or-complete
bindkey '^[[Z' reverse-menu-complete
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^R' history-incremental-search-backward
bindkey '^?' backward-delete-char

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

alias l='ls -al --color=auto'
alias ls='ls -a --color=auto'
alias e='nvim'
alias tm='tmux'

git_prompt_info() {
  local branch dirty

  (( $+commands[git] )) || return

  branch=$(command git symbolic-ref --quiet --short HEAD 2>/dev/null) ||
    branch=$(command git rev-parse --short HEAD 2>/dev/null) ||
    return

  dirty=""

  if ! command git diff --no-ext-diff --quiet --ignore-submodules -- 2>/dev/null ||
     ! command git diff --no-ext-diff --cached --quiet --ignore-submodules -- 2>/dev/null; then
    dirty="%F{red}⚡"
  fi

  branch=${branch//\%/%%}

  print -r -- "%F{blue}(${branch})%f${dirty} "
}

PROMPT='%{${fg_bold[yellow]}%}%n%{$reset_color%}%{${fg[yellow]}%}@%m%{$reset_color%} $(git_prompt_info)%(?,,%{${fg_bold[white]}%}[%?]%{$reset_color%} )%{$fg[yellow]%}%#%{$reset_color%} '
RPROMPT='%{$fg[green]%}%~%{$reset_color%}'

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=1000

if [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

