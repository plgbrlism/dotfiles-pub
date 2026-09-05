{ pkgs, ... }:

{
  # Realtime scheduling daemon for audio threads
  security.rtkit.enable = true;

  # PipeWire service configuration
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Audio mixer GUI
  environment.systemPackages = with pkgs; [
    pavucontrol
  ];
}
