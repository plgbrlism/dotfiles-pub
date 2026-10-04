#./zshrc

# ~~ themes ~~
fastfetch

# ~~ Oh-My-Zsh Setup ~~
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(
	git 
	nvm
	zsh-autosuggestions
)

	# ~~ Completions ~~
	ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
	ZSH_AUTOSUGGEST_USE_ASYNC=true
		
source $ZSH/oh-my-zsh.sh

	if command -v atuin &>/dev/null; then
	    eval "$(atuin init zsh --disable-up-arrow)"
	fi

# use starship instead
eval "$(starship init zsh)"

# ~~ history ~~
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000
setopt histignorealldups sharehistory

# ~~ keybindings ~~
bindkey -e 
bindkey '^ ' autosuggest-accept # accept entire suggestion with ctrl + space
# make right arrow move the cursor and dismiss the ghost text
clear-autosuggest-and-move() {
    zle autosuggest-clear
    zle forward-char
}
zle -N clear-autosuggest-and-move
bindkey '^[[C' clear-autosuggest-and-move
bindkey '^[OC' clear-autosuggest-and-move

# ~~ bun completions ~~
[ -s "\(HOME/.local/share/bun/_bun" ] && source "\)HOME/.local/share/bun/_bun"

# ~~ workflows aliases ~~
alias zed="zeditor"
# mega-cli
	alias vault-sync="mega-sync"
	alias vault-status="mega-transfers"
	alias vault-close="mega-quit"
#alias mactahoe-gtk-reload="$HOME/scripts/mactahoe-gtk-reload/reload.sh"
#alias 9router="BUN_RUNTIME_ESCAPE=1 bunx --bun 9router"

alias omniroute="/home/paul/apps/omniroute/node_modules/.bin/omniroute"

# anki-mcq-builder
alias py-anki-mcq-builder="source ~/projects/anki-mcq-builder/.venv/bin/activate"

# image curator
alias image-curate="$HOME/scripts/images-curator/.venv/bin/python $HOME/scripts/images-curator/img-curate.py"
