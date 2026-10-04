> Machine-specific example, not portable.
Why: hostname `hp`, locale/timezone, hardware config for HP Notebook 14-ck0115tu. See also `nix/modules/build.nix:8-10` LAN `192.168.1.4` + `/root/.ssh` path.
Fix before copy: copy `hosts/hp/` to new host dir, change hardware config.
