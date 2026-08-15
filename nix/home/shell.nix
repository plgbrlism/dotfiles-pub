{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = [ "git" "nvm" "zsh-autosuggestions" ];
    };

    initExtra = ''
      fastfetch

      setopt histignorealldups sharehistory
      HISTSIZE=1000
      SAVEHIST=1000
      HISTFILE=~/.zsh_history

      bindkey -e

      alias vault-sync="mega-sync"
      alias vault-status="mega-transfers"
      alias vault-close="mega-quit"
      alias zed="zeditor"
    '';

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
    };
  };
}
