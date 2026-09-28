{ lib, pkgs, ... }:

# CPU-only embedding server for pi-book, pi's memory (the ~/.pi repo,
# SETUP.md step 8).
#
# This machine's pi provider (OpenCode Go) serves no embedding models, so
# pi-book's embedder points here: EmbeddingGemma-300M behind llama-server's
# OpenAI-compatible /v1/embeddings on 127.0.0.1:8090. It won a CPU benchmark
# of memory recall against Qwen3-Embedding-0.6B, granite-97m-r2, nomic v1.5
# and jina-v5-nano (run for mem0, pi-book's predecessor, on raw text), at
# ~500 MB RSS and ~9 ms a query. pi-book also adds EmbeddingGemma's own
# query/document prefixes.
#
# The GPU stays free for the big local models. PrivateDevices hides /dev/dri,
# so this Vulkan build finds no GPU at all (it logs "no usable GPU found");
# --device none / -ngl 0 / --no-op-offload keep it CPU-only even without the
# sandbox. -t 4 caps a request at 4 cores (~17% of the machine for a few ms,
# and the Nice keeps it behind interactive work); idle it uses no CPU.

let
  model = pkgs.fetchurl {
    url = "https://huggingface.co/ggml-org/embeddinggemma-300M-GGUF/resolve/0f741b5a6585bd53aeb15cd1372c56f2a0f65e12/embeddinggemma-300M-Q8_0.gguf";
    hash = "sha256-tc6dd6P8Szs5zLVkPDZ3eRHMTrRqZpYurfo/X2BJDWM=";
  };
in
{
  systemd.user.services.llama-embed = {
    Unit = {
      Description = "EmbeddingGemma embedding server for pi-book (CPU only)";
    };
    Service = {
      Type = "simple";
      # The system's llama.cpp (hosts/nixos-desktop/packages.nix): its
      # derivation lives in the NixOS config, which home-manager cannot see.
      ExecStart = lib.escapeShellArgs [
        "/run/current-system/sw/bin/llama-server"
        "--model"
        "${model}"
        "--alias"
        "embeddinggemma"
        "--embeddings"
        "--device"
        "none"
        "-ngl"
        "0"
        "--no-op-offload"
        "-t"
        "4"
        # pi-book embeds chunks of at most 1,400 characters; 2048 tokens fits them.
        "-c"
        "2048"
        "-b"
        "2048"
        "-ub"
        "2048"
        "--host"
        "127.0.0.1"
        "--port"
        "8090"
      ];
      PrivateDevices = true;
      Nice = 10;
      # "always", not "on-failure": a teardown that kills llama-server by name
      # (bench harnesses, 2026-09-27) terminates this one cleanly with SIGTERM,
      # which "on-failure" treats as success and leaves pi's memory dead.
      Restart = "always";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
