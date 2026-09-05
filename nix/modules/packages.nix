{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ── Browsers & Communication ──
    firefox
    brave
    vesktop

    # ── Media Players & Visualizers ──
    mpv
    vlc
    cava
    lavat

    # ── Screen Capture & Recording ──
    gpu-screen-recorder
    gpu-screen-recorder-gtk
    peek

    # ── Office, Notes & Flashcards ──
    obsidian
    onlyoffice-desktopeditors
    anki-bin
    bitwarden-desktop

    # ── Vector / Design & Mobile Tools ──
    inkscape
    universal-android-debloater

    # ── File Management & Thumbnails ──
    nautilus
    tumbler
    ffmpegthumbnailer
    xarchiver
  ];
}
