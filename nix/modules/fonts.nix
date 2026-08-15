{ pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      noto-fonts-cjk-sans
      jetbrains-mono
      jetbrains-mono-nerd
      dejavu_fonts
      liberation_ttf
      carlito
      unifont
      departure-mono
      siji
      freefont_ttf
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrains Mono Nerd Font" "DejaVu Sans Mono" ];
        sansSerif = [ "Noto Sans" "DejaVu Sans" ];
        serif = [ "Noto Serif" "DejaVu Serif" ];
      };
    };
  };
}
