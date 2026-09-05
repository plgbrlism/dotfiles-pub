{ pkgs, ... }:

{
  #  CORE PROGRAM MODULES
  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  # Enable interactive shell system-wide hooks
  programs.zsh.enable = true;

  #  CLI & UTILITY PACKAGES
  environment.systemPackages = with pkgs; [
    # Terminal Multiplexers & Editors
    neovim
    micro
    tmux
    vim
    nano

    # CLI Navigation & Modern Coreutils
    fzf
    jq
    bat
    ripgrep
    yazi
    dust
    tree
    stow
    fastfetch
    btop
    glow
    systemctl-tui
    peaclock

    # Downloaders & Archive Tools
    wget
    curl
    unzip
    p7zip
    man-db

    # Terminal Screen Recording & ASCII Toys
    vhs
    cmatrix
    figlet

    # Build Tools, Compilers & Runtimes
    just
    rustup
    nodejs
    python3
    clang
    gcc
    gnumake
    pkg-config
    openssl
    meson
    scdoc

    # Shell Essentials (config lives in home/shell.nix)
    starship
    zsh-autosuggestions
    zsh-syntax-highlighting

    # Libraries & Format Parsing Headers
    nlohmann_json
    tomlplusplus
    stb
    sassc
    dart-sass
    poppler
    libical
    libqalculate
    sdbus-cpp
  ];
}
