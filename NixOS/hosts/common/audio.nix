{
  config,
  pkgs,
  lib,
  ...
}:

# Bit-perfect audio for the Audiocular Spark USB DAC (drives analog Truthear Gate IEMs).
# WirePlumber clocks the Spark to each stream's native rate; mixed-rate streams resample at SoXR 15.
# Refs: VolodiaPG/nixos-configs, Ramblurr/nixcfg, matteo-pacini/nixos-configs, ixaxaar/pipewire-high-res-arch

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;

    # → /etc/pipewire/pipewire.conf.d/
    extraConfig.pipewire."10-clock" = {
      "context.properties" = {
        # Start at 44.1 kHz — most of the library is 44.1 kHz FLAC
        "default.clock.rate" = 44100;
        "default.clock.allowed-rates" = [ 44100 48000 96000 192000 ];
      };
      "stream.properties" = {
        # Only invoked when multi-stream mixing forces resampling
        "resample.quality" = 15;
      };
    };

    wireplumber = {
      enable = true;

      # Each key → /etc/wireplumber/wireplumber.conf.d/<key>.conf
      extraConfig = {
        "50-bluez" = {
          "monitor.bluez.properties" = {
            # Switch to HFP when a call starts
            "bluez5.autoswitch-profile" = true;
          };
        };

        "10-fifine-a6v" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                {
                  "alsa.components" = "USB3142:a601";
                  "media.class" = "Audio/Source";
                }
              ];
              actions.update-props = {
                "node.description" = "FIFINE AmpliGame A6V";
                "audio.format" = "S24LE";
                "audio.rate" = 48000;
                "audio.channels" = 1;
              };
            }
          ];
        };

        # Spark hardware: 44.1/48/96/192/384 kHz, 16/24/32-bit, no DSD
        "51-audiocular-spark" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                { "node.name" = "~alsa_output.usb-TTGK_Technology_Co._Ltd_Audiocular_Spark.*"; }
              ];
              actions.update-props = {
                # WirePlumber switches to the stream's rate if listed — no resampling
                "audio.allowed-rates" = [ 44100 48000 96000 192000 384000 ];
                # 0 = follow the graph rate rather than pinning a default
                "audio.rate" = 0;
                # Spark's native container; 16/24-bit sources are zero-padded, lossless
                "audio.format" = "S32LE";
                # The Spark supports hardware multirate
                "api.alsa.multirate" = true;
                # 0 = never auto-suspend; avoids the click on USB DAC re-init
                "session.suspend-timeout-seconds" = 0;
                # Simple stereo DAC — ACP only adds profile-switching noise
                "api.alsa.use-acp" = false;
              };
            }
          ];
        };
      };
    };
  };

  # PipeWire provides the PulseAudio API
  services.pulseaudio.enable = false;

  # Required for glitch-free audio
  security.rtkit.enable = true;
}
