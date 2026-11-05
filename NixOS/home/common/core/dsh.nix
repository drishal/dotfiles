{ config, inputs, lib, pkgs, ... }:

let
  dsh = inputs.deepseek-harness.packages.${pkgs.stdenv.hostPlatform.system}.dsh;
  profile = "${config.home.homeDirectory}/.dsh/profiles/acp";
  acpBundle = "@deepseek-ai/dsh-acp-app";
in
{
  # The ACP surface awui drives. Profiles, models and keys live hand-managed in
  # ~/.dsh like the web profile, so only this profile's user patch layer is
  # declarative. The activation below installs the ACP bundle pinned to the dsh
  # in this flake and reinstalls it when a flake update moves dsh.
  home.file.".dsh/profiles/acp/cordis.patch.yml" = {
    # The profile is mutable for dsh plugin, but this one file is ours: a
    # hand-written copy (the one-time setup before the first switch) is
    # replaced by the managed symlink rather than clobbering the activation.
    force = true;
    text = ''
    # Managed by ~/dotfiles/NixOS/home/common/core/dsh.nix.
    #
    # The ACP profile can only resume a session whose recorded model route has
    # a provider here. These are the web profile's provider rows, so awui can
    # open the sessions the DSH web UI already made. The awui service needs
    # OPENCODE_GO_API_KEY in its environment for this route; otherwise pick
    # DeepSeek's saved credentials in the model picker.
    - id: llm-pi-ai
      name: "@deepseek-ai/dsh-llm-pi-ai"
      config:
        providers:
          opencode-go:
            apiKeyEnv: OPENCODE_GO_API_KEY
    - id: agent-default-model
      name: "@deepseek-ai/dsh-agent-default-model"
      config:
        provider: opencode-go
        model: deepseek-v4.1-flash
        reasoningEffort: max
  '';
  };

  # `dsh plugin` owns package.json and node_modules, so the profile template is
  # written only when the profile does not exist yet; the bundle install is
  # idempotent and keyed by the version `dsh --version` reports.
  home.activation.dshAcpProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    profile="${profile}"
    bundle="$profile/node_modules/@deepseek-ai/dsh-acp-app"
    ${pkgs.coreutils}/bin/mkdir -p "$profile"

    if [ ! -f "$profile/package.json" ]; then
      ${pkgs.coreutils}/bin/cat > "$profile/package.json" <<'EOF'
{
  "name": "dsh-profile-acp",
  "private": true,
  "dependencies": {},
  "dsh": {
    "profile": {
      "bundles": [
        "@deepseek-ai/dsh-base",
        "@deepseek-ai/dsh-acp-app"
      ]
    }
  }
}
EOF
    fi
    if [ ! -f "$profile/pnpm-workspace.yaml" ]; then
      ${pkgs.coreutils}/bin/cat > "$profile/pnpm-workspace.yaml" <<'EOF'
packages:
  - .

nodeLinker: hoisted
autoInstallPeers: false
EOF
    fi

    version="$(${dsh}/bin/dsh --version 2>/dev/null | ${pkgs.coreutils}/bin/head -n1 || true)"
    installed=""
    if [ -f "$bundle/package.json" ]; then
      installed="$(${pkgs.jq}/bin/jq -r '.version // empty' "$bundle/package.json" 2>/dev/null || true)"
    fi
    if [ -n "$version" ] && [ "$installed" != "$version" ]; then
      echo "dsh: installing ${acpBundle}@$version for the acp profile"
      ${dsh}/bin/dsh plugin --profile acp add "${acpBundle}@$version" || \
        echo "dsh: could not install ${acpBundle}@$version (offline or not published); run this by hand: ${dsh}/bin/dsh plugin --profile acp add ${acpBundle}@$version" >&2
    fi
  '';
}
