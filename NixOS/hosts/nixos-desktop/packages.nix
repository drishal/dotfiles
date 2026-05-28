{ pkgs, inputs, ... }:

{
  # networking.enableIPv6  = false;
  # environment.systemPackages = with pkgs; [
  # inputs.nix-gaming.packages.${pkgs.system}.wine-tkg
  # inputs.nix-gaming.packages.${pkgs.system}.winetricks-git
  # ];

  # services.ollama = {
  #   enable = true;
  #   package = pkgs.ollama-rocm;
  # };
  programs.gamemode.enable = true;
  environment.systemPackages = with pkgs; [
    # llama-cpp-vulkan
    (inputs.llama-cpp.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      useVulkan = true;
      useWebUi = false;
    })
    teams-for-linux
    i2c-tools
    (brave.override {
      commandLineArgs = [
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
        "--ozone-platform-hint=auto"
        "--enable-features=VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"
      ];
    })
  ];

  #postgresql
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE drishal WITH LOGIN PASSWORD 'aiphonepass' CREATEDB;
      CREATE DATABASE aiphone;
      GRANT ALL PRIVILEGES ON DATABASE aiphone TO drishal;
    '';
  };

}
