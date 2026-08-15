{ pkgs, ... }:

{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    settings = {
      max_connections = 20;
      shared_buffers = "256MB";
      effective_cache_size = "768MB";
      work_mem = "4MB";
      maintenance_work_mem = "64MB";
    };
    authentication = pkgs.lib.mkOverride 10 ''
      local all all peer
      host all all 127.0.0.1/32 md5
      host all all ::1/128 md5
    '';
    initialScript = pkgs.writeText "init.sql" ''
      CREATE USER paul WITH SUPERUSER PASSWORD 'changeme';
      CREATE DATABASE paul OWNER paul;
    '';
  };
}
