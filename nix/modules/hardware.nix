{ pkgs, ... }:

{
  #  INTEL CPU MICROCODE
  hardware.cpu.intel.updateMicrocode = true;

  #  FIRMWARE
  hardware.enableAllFirmware = true;

  #  GRAPHICS & HARDWARE ACCELERATION
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # iHD driver for Gen 9.5+ hardware decoding
      libvdpau-va-gl     # VDPAU backend with VA-API
      libva-utils        # Includes 'vainfo' for debugging
    ];
  };

  #  X11 VIDEO DRIVER
  services.xserver.videoDrivers = [ "modesetting" ];

  #  HARDWARE ENVIRONMENT VARIABLES
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    VDPAU_DRIVER = "va_gl";
  };
}
