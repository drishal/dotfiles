{
  config,
  pkgs,
  lib,
  ...
}:

# ─────────────────────────────────────────────────────────────
#  Bit-perfect audio: Audiocular Spark DAC + Truthear Gate IEMs
#
#  The Gate IEMs are analog — they plug into the Spark's 3.5mm
#  headphone jack.  Only the Spark is a USB audio device, so only
#  it needs PipeWire node configuration.  The sample rate that
#  reaches the Gate is determined entirely by the Spark's hardware
#  clock.
#
#  WirePlumber switches the Spark's hardware clock to match each
#  stream's native rate (44.1 / 48 / 96 / 192 kHz) via
#  `audio.allowed-rates`.  When multiple streams at different rates
#  are active simultaneously (e.g. mpv + YouTube), the device locks
#  to one rate and the others are resampled at SoXR quality 15
#  (perceptually transparent).
#
#  Shared between nixos-work and nixos-desktop via
#  hosts/common/default.nix — both machines carry the same
#  Spark + Gate combo.
#
#  References:
#    VolodiaPG/nixos-configs    modules/nixos/hifi.nix
#    Ramblurr/nixcfg            hosts/quine/wireplumber.nix
#    matteo-pacini/nixos-configs hosts/Brightfalls/audio/default.nix
#    ixaxaar/pipewire-high-res-arch README.md
# ─────────────────────────────────────────────────────────────

{
  # ── PipeWire server ───────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;

    # PipeWire server-level config (→ /etc/pipewire/pipewire.conf.d/)
    extraConfig.pipewire."10-clock" = {
      "context.properties" = {
        # Start the graph at 44.1 kHz — 188 of 194 library files are
        # 44.1 kHz FLAC.  With allowed-rates below, the graph switches
        # to match each stream's native rate automatically.
        "default.clock.rate" = 44100;
        "default.clock.allowed-rates" = [ 44100 48000 96000 192000 ];
      };
      "stream.properties" = {
        # SoXR maximum quality — only invoked when multi-stream mixing
        # forces resampling (e.g. mpv at 44.1k + YouTube at 48k).
        # Single-stream playback is bit-perfect: no resampler runs.
        "resample.quality" = 15;
      };
    };

    # ── WirePlumber session manager ─────────────────────────
    wireplumber = {
      enable = true;

      # Each key → /etc/wireplumber/wireplumber.conf.d/<key>.conf
      extraConfig = {
        # ── Bluetooth: auto-switch to HFP when a call starts ──
        "50-bluez" = {
          "monitor.bluez.properties" = {
            "bluez5.autoswitch-profile" = true;
          };
        };

        # ── Fifine microphone: force 48 kHz / S16LE / mono ──
        "10-fifine-mic" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                { "node.name" = "alsa_input.usb-3142_Fifine_Microphone-00.mono-fallback"; }
              ];
              actions.update-props = {
                "audio.format" = "S16LE";
                "audio.rate" = 48000;
                "audio.channels" = 1;
                "channelmix.upmix" = false;
                "channelmix.normalize" = false;
              };
            }
          ];
        };

        # ── Audiocular Spark DAC: bit-perfect rate switching ──
        # node.name: alsa_output.usb-TTGK_Technology_Co._Ltd_Audiocular_Spark-00.analog-stereo
        # Hardware: 44.1/48/96/192/384 kHz, 16/24/32-bit, no DSD
        "51-audiocular-spark" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                { "node.name" = "~alsa_output.usb-TTGK_Technology_Co._Ltd_Audiocular_Spark.*"; }
              ];
              actions.update-props = {
                # Rates the Spark hardware can natively clock at.
                # WirePlumber switches to the incoming stream's rate
                # if it appears in this list — no resampling.
                "audio.allowed-rates" = [ 44100 48000 96000 192000 384000 ];
                # 0 = follow the graph rate instead of pinning a default;
                #     lets WirePlumber switch to the source rate immediately.
                "audio.rate" = 0;
                # S32LE is the Spark's native container format.
                # 16/24-bit sources are zero-padded — lossless.
                "audio.format" = "S32LE";
                # Let the ALSA driver handle rate switching internally
                # (the Spark supports hardware multirate).
                "api.alsa.multirate" = true;
                # Keep the device warm between tracks — prevents the
                # click/pop that occurs on USB DAC re-init during
                # rate transitions.  0 = never auto-suspend.
                "session.suspend-timeout-seconds" = 0;
                # Skip ALSA Card Profiles — the Spark is a simple
                # stereo DAC, ACP just adds profile-switching noise.
                "api.alsa.use-acp" = false;
              };
            }
          ];
        };
      };
    };
  };

  # Disable legacy PulseAudio — PipeWire provides the PulseAudio API.
  services.pulseaudio.enable = false;

  # Realtime scheduling for PipeWire/WirePlumber — must be enabled
  # for glitch-free audio.  Moved here from base.nix since it's
  # exclusively used by the audio stack.
  security.rtkit.enable = true;
}
