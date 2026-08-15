{ config, pkgs, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./dotfiles.nix
  ];

  home = {
    username = "paul";
    homeDirectory = "/home/paul";
    stateVersion = "25.05";

    sessionVariables = {
      TERMINAL = "foot";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
    ];

    packages = with pkgs; [
      tree-sitter-grammars.tree-sitter-markdown
      tree-sitter-grammars.tree-sitter-c
      tree-sitter-grammars.tree-sitter-lua
      tree-sitter-grammars.tree-sitter-vim
    ];
  };

  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
