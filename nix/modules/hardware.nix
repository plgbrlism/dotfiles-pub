{ pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32 = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.intel-media-driver
    ];
  };

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  hardware.enableAllFirmware = true;

  services.xserver.videoDrivers = [ "modesetting" ];

  environment.variables = {
    LIBVA_DRIVER_NAME = "iHD";
    VDPAU_DRIVER = "va_gl";
  };
}
