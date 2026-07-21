{
  pkgs,
  inputs,
  user,
  ...
}:

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
    # llama-cpp (whichever fork the `llama-cpp` input pins) with Vulkan backend.
    # Source hash tracked by flake.lock via the `flake = false` input — no
    # manual fetchFromGitHub/hash maintenance. The local package.nix is pure
    # build-recipe code (upstream's, with the duplicate `spirv-headers` formal
    # arg some forks carry removed); it holds no hashes. We can't use a fork's
    # own flake packaging (dup-arg parse error) nor the ani-cli src-swap pattern
    # (nixpkgs llama-cpp.overrideAttrs returns a function under the chaotic
    # overlay here), so callPackage it directly. Web UI / npm build disabled
    # (unused, and forks' tools/ui lockfile diverges from nixpkgs' npmDepsHash).
    (pkgs.callPackage ./llama-cpp.nix {
      src = inputs.llama-cpp;
      useVulkan = true;
      useWebUi = false;
      optimizeZen4 = true;
      useLto = true;
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

  programs.brave-origin-beta = {
    enable = true;
    commandLineArgs = [
      "--ignore-gpu-blocklist"
      "--enable-zero-copy"
      "--ozone-platform-hint=auto"
      "--enable-features=VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"
    ];
  };

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
      CREATE ROLE ${user} WITH LOGIN PASSWORD 'aiphonepass' CREATEDB;
      CREATE DATABASE aiphone;
      GRANT ALL PRIVILEGES ON DATABASE aiphone TO ${user};
    '';
  };

}
