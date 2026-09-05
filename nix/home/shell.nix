{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    # Oh-My-Zsh Configuration
    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [
        "git"
        "sudo"
      ];
    };

    # History & Keybinds
    history = {
      size = 10000;
      save = 10000;
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
    initExtra = ''
      # Run fastfetch on interactive shell start
      if [[ $- == *i* ]]; then
        fastfetch
      fi

      bindkey -e
    '';
  };

  # Modern Starship Prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
