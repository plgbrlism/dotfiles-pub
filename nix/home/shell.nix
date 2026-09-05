{ pkgs, ... }:

{
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/.bun/bin"
    "$HOME/scripts"
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Oh-My-Zsh Configuration
    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins = [
        "git"
        "sudo"
        "nvm"
      ];
    };

    # History & Keybinds
    history = {
      size = 100;
      save = 100;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      share = true;
    };

    # Shell Aliases (Declaratively mapped)
    shellAliases = {
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log";
      cat = "bat --paging=never";
      grep = "rg";

      # Mega Cloud Storage CLI (from megacmd)
      vault-sync = "mega-sync";
      vault-status = "mega-transfers";
      vault-close = "mega-quit";
    };

    # Extra Interactive Shell Initialization
    initContent = ''
      # Run fastfetch on interactive shell start
      if [[ $- == *i* ]]; then
        fastfetch
      fi

      bindkey -e

      # Autosuggestion keybindings
      bindkey '^ ' autosuggest-accept  # ctrl+space → accept full suggestion

      # Right arrow clears suggestion instead of accepting it
      clear-autosuggest-and-move() {
        zle autosuggest-clear
        zle forward-char
      }
      zle -N clear-autosuggest-and-move
      bindkey '^[[C' clear-autosuggest-and-move
      bindkey '^[OC' clear-autosuggest-and-move
    '';
  };

  # Modern Starship Prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # Atuin — shell history sync
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--disable-up-arrow" ];
  };
}
