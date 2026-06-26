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
    # llama-cpp (TurboQuant fork) with Vulkan backend.
    # Source hash tracked by flake.lock via the `flake = false` input — no
    # manual fetchFromGitHub/hash maintenance. The local package.nix is pure
    # build-recipe code (TurboQuant's, with TheTom/llama-cpp-turboquant#194's
    # duplicate `spirv-headers` formal arg removed); it carries no hashes.
    # We can't use TurboQuant's own flake packaging (#194 parse error) nor the
    # ani-cli src-swap pattern (nixpkgs llama-cpp.overrideAttrs returns a
    # function under the chaotic overlay here), so callPackage it directly.
    # Web UI / npm build is disabled (we don't use it, and TurboQuant's
    # tools/ui lockfile diverges from nixpkgs' pinned npmDepsHash).
    (pkgs.callPackage ./llama-cpp-turboquant.nix {
      src = inputs.llama-cpp;
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
