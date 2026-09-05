{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;
    userName = "paul";
    userEmail = "fuzzbuzz@local.ph";

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
      credential.helper = "cache --timeout=3600";
    };

    aliases = {
      s = "status";
      d = "diff";
      co = "checkout";
      cm = "commit";
      lg = "log --oneline --graph --all";
    };
  };

  # Terminal UI for Git (mapped from pacman list)
  programs.lazygit.enable = true;
}
