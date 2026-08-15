{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ── Browsers ──
    firefox
    google-chrome
    brave-origin

    # ── Media Players ──
    mpv
    vlc

    # ── Recording ──
    obs-studio
    gpu-screen-recorder
    gpu-screen-recorder-gtk
    peek

    # ── Image Viewers ──
    imv
    feh

    # ── Creative ──
    inkscape
    krita

    # ── Office / Productivity ──
    obsidian
    onlyoffice-bin
    anki

    # ── File Managers ──
    nautilus
    tumbler

    # ── Audio Visualizer ──
    cava

    # ── Thumbnailer ──
    ffmpegthumbnailer
  ];
}
