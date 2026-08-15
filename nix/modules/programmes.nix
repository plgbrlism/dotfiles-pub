{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  environment.systemPackages = with pkgs; [
    tmux
    neovim
    micro
    vim
    fzf
    jq
    bat
    ripgrep
    yazi
    btop
    fastfetch
    glow
    vhs
    stow
    tree
    cmatrix
    figlet
    peaclock
    systemctl-tui
    zenith
    unzip
    p7zip
    wget
    curl
    man-db
    nano
    scdoc
    meson
    nlohmann-json
    tomlplusplus
    stb
    sassc
    dart-sass
    poppler
    libical
    libqalculate
    sdbus-cpp
    just
    git
    rustup
    nodejs
    python3
    clang
    gcc
    gnumake
    pkg-config
    openssl
  ];

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "agnoster";
      plugins = [ "git" "nvm" ];
    };
    shellInit = ''
      setopt histignorealldups sharehistory
      HISTSIZE=1000
      SAVEHIST=1000
      HISTFILE=~/.zsh_history
    '';
  };
}
