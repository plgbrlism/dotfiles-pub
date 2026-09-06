
{ pkgs, inputs, ... }:

{
  environment.systemPackages = [
  	# Desktop Shell for niri+wayland
  	inputs.noctalia.packages.${pkgs.system}.default  	
  ] ++ (with pkgs; [
    # Browsers & Communication
    firefox
    brave
    vesktop # discord for linux

    #  Media Players & Visualizers
    mpv
    vlc
    cava
    lavat

    #  Screen Capture & Recording
    gpu-screen-recorder
    gpu-screen-recorder-gtk
    peek

    #  Office, Notes & Flashcards
    obsidian
    onlyoffice-desktopeditors
    anki-bin
    bitwarden-desktop

    #  Vector / Design & Mobile Tools
    inkscape
    universal-android-debloater

    #  File Management & Thumbnails
    nautilus
    tumbler
    ffmpegthumbnailer
    xarchiver
  ]);
}
