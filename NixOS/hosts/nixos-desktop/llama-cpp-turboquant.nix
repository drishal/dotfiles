# Local copy of TheTom/llama-cpp-turboquant's .devops/nix/package.nix
# with one fix: upstream lists `spirv-headers` twice in the formal arguments
# (a parse-time error in Nix), which breaks `inputs.llama-cpp.packages.*.default`.
# This file is the corrected derivation, parameterized by `src` (the TurboQuant
# flake outPath) so we can callPackage it directly.
#
# importNpmLock defaults to null because we build with useWebUi=false; the
# `webui` attr is never forced in that case. If you flip useWebUi to true,
# add the `import-npm-lock` flake input and pass the real helper here.
{
  lib,
  glibc,
  config,
  stdenv,
  stdenvNoCC,
  runCommand,
  cmake,
  ninja,
  pkg-config,
  git,
  mpi,
  blas,
  cudaPackages,
  autoAddDriverRunpath,
  darwin,
  rocmPackages,
  vulkan-headers,
  vulkan-loader,
  spirv-headers,
  openssl,
  shaderc,
  nodejs,
  importNpmLock ? null,
  src,
  useBlas ?
    builtins.all (x: !x) [
      useCuda
      useMetalKit
      useRocm
      useVulkan
    ]
    && blas.meta.available,
  useCuda ? config.cudaSupport,
  useMetalKit ? stdenv.isAarch64 && stdenv.isDarwin,
  # Increases the runtime closure size by ~700M
  useMpi ? false,
  useRocm ? config.rocmSupport,
  rocmGpuTargets ? builtins.concatStringsSep ";" rocmPackages.clr.gpuTargets,
  useVulkan ? false,
  useRpc ? false,
  llamaVersion ? "0.0.0", # Arbitrary version, substituted by the flake

  # It's necessary to consistently use backendStdenv when building with CUDA support,
  # otherwise we get libstdc++ errors downstream.
  effectiveStdenv ? if useCuda then cudaPackages.backendStdenv else stdenv,
  enableStatic ? effectiveStdenv.hostPlatform.isStatic,
  precompileMetalShaders ? false,
  useWebUi ? true,
}:

let
  inherit (lib)
    cmakeBool
    cmakeFeature
    optionalAttrs
    optionals
    strings
    ;

  stdenv = throw "Use effectiveStdenv instead";

  suffices =
    lib.optionals useBlas [ "BLAS" ]
    ++ lib.optionals useCuda [ "CUDA" ]
    ++ lib.optionals useMetalKit [ "MetalKit" ]
    ++ lib.optionals useMpi [ "MPI" ]
    ++ lib.optionals useRocm [ "ROCm" ]
    ++ lib.optionals useVulkan [ "Vulkan" ];

  pnameSuffix =
    strings.optionalString (suffices != [ ])
      "-${strings.concatMapStringsSep "-" strings.toLower suffices}";
  descriptionSuffix = strings.optionalString (
    suffices != [ ]
  ) ", accelerated with ${strings.concatStringsSep ", " suffices}";

  xcrunHost = runCommand "xcrunHost" { } ''
    mkdir -p $out/bin
    ln -s /usr/bin/xcrun $out/bin/xcrun
  '';

  # apple_sdk is supposed to choose sane defaults, no need to handle isAarch64
  # separately
  darwinBuildInputs =
    with darwin.apple_sdk.frameworks;
    [
      Accelerate
      CoreVideo
      CoreGraphics
    ]
    ++ optionals useMetalKit [ MetalKit ];

  cudaBuildInputs = with cudaPackages; [
    cuda_cudart
    cuda_cccl # <nv/target>
    libcublas
  ];

  rocmBuildInputs = with rocmPackages; [
    clr
    hipblas
    rocblas
  ];

  vulkanBuildInputs = [
    vulkan-headers
    vulkan-loader
    shaderc
    spirv-headers
  ];
in

effectiveStdenv.mkDerivation (finalAttrs: {
  pname = "llama-cpp${pnameSuffix}";
  version = llamaVersion;

  # Source is the TurboQuant flake outPath, passed in by the caller.
  # Mirror upstream's cleanSourceWith filtering so *.nix/*.md/hidden/flake.lock
  # changes don't needlessly rebuild.
  src = lib.cleanSourceWith {
    filter =
      name: type:
      let
        noneOf = builtins.all (x: !x);
        baseName = baseNameOf name;
      in
      noneOf [
        (lib.hasSuffix ".nix" name)
        (lib.hasSuffix ".md" name)
        (lib.hasPrefix "." baseName)
        (baseName == "flake.lock")
      ];
    src = lib.cleanSource src;
  };

  # Builds the webui locally, taking care not to require updating any sha256 hash.
  # Only evaluated when useWebUi=true (postPatch forces finalAttrs.webui).
  webui = stdenvNoCC.mkDerivation {
    pname = "webui";
    version = llamaVersion;
    src = lib.cleanSource (src + "/tools/ui");

    nativeBuildInputs = [
      nodejs
      importNpmLock.linkNodeModulesHook
    ];

    # no sha256 required when using buildNodeModules
    npmDeps = importNpmLock.buildNodeModules {
      npmRoot = src + "/tools/ui";
      inherit nodejs;
    };

    installPhase = ''
      LLAMA_UI_OUT_DIR=$out npm run build --offline
    '';
  };

  postPatch = lib.optionalString useWebUi ''
    cp -r ${finalAttrs.webui} tools/ui/dist
    chmod -R u+w tools/ui/dist
  '';

  # With PR#6015 https://github.com/ggml-org/llama.cpp/pull/6015,
  # `default.metallib` may be compiled with Metal compiler from XCode
  # and we need to escape sandbox on MacOS to access Metal compiler.
  # `xcrun` is used find the path of the Metal compiler, which is varible
  # and not on $PATH
  # see https://github.com/ggml-org/llama.cpp/pull/6118 for discussion
  __noChroot = effectiveStdenv.isDarwin && useMetalKit && precompileMetalShaders;

  nativeBuildInputs =
    [
      cmake
      ninja
      pkg-config
      git
    ]
    ++ optionals useCuda [
      cudaPackages.cuda_nvcc

      autoAddDriverRunpath
    ]
    ++ optionals (effectiveStdenv.hostPlatform.isGnu && enableStatic) [ glibc.static ]
    ++ optionals (effectiveStdenv.isDarwin && useMetalKit && precompileMetalShaders) [ xcrunHost ];

  buildInputs =
    optionals effectiveStdenv.isDarwin darwinBuildInputs
    ++ optionals useCuda cudaBuildInputs
    ++ optionals useMpi [ mpi ]
    ++ optionals useRocm rocmBuildInputs
    ++ optionals useBlas [ blas ]
    ++ optionals useVulkan vulkanBuildInputs
    ++ [ openssl ];

  cmakeFlags =
    [
      (cmakeBool "LLAMA_BUILD_SERVER" true)
      (cmakeBool "LLAMA_BUILD_WEBUI" useWebUi)
      (cmakeBool "BUILD_SHARED_LIBS" (!enableStatic))
      (cmakeBool "CMAKE_SKIP_BUILD_RPATH" true)
      (cmakeBool "GGML_NATIVE" false)
      (cmakeBool "GGML_BLAS" useBlas)
      (cmakeBool "GGML_CUDA" useCuda)
      (cmakeBool "GGML_HIP" useRocm)
      (cmakeBool "GGML_METAL" useMetalKit)
      (cmakeBool "GGML_VULKAN" useVulkan)
      (cmakeBool "GGML_STATIC" enableStatic)
      (cmakeBool "GGML_RPC" useRpc)
    ]
    ++ optionals useCuda [
      (
        with cudaPackages.flags;
        cmakeFeature "CMAKE_CUDA_ARCHITECTURES" (
          builtins.concatStringsSep ";" (map dropDot cudaCapabilities)
        )
      )
    ]
    ++ optionals useRocm [
      (cmakeFeature "CMAKE_HIP_COMPILER" "${rocmPackages.llvm.clang}/bin/clang")
      (cmakeFeature "CMAKE_HIP_ARCHITECTURES" rocmGpuTargets)
    ]
    ++ optionals useMetalKit [
      (lib.cmakeFeature "CMAKE_C_FLAGS" "-D__ARM_FEATURE_DOTPROD=1")
      (cmakeBool "GGML_METAL_EMBED_LIBRARY" (!precompileMetalShaders))
    ];

  # Environment variables needed for ROCm
  env = optionalAttrs useRocm {
    ROCM_PATH = "${rocmPackages.clr}";
    HIP_DEVICE_LIB_PATH = "${rocmPackages.rocm-device-libs}/amdgcn/bitcode";
  };

  # TODO(SomeoneSerge): It's better to add proper install targets at the CMake level,
  # if they haven't been added yet.
  postInstall = ''
    mkdir -p $out/include
    cp $src/include/llama.h $out/include/
  '';

  meta = {
    # Configurations we don't want even the CI to evaluate. Results in the
    # "unsupported platform" messages. This is mostly a no-op, because
    # cudaPackages would've refused to evaluate anyway.
    badPlatforms = optionals useCuda lib.platforms.darwin;

    # Configurations that are known to result in build failures. Can be
    # overridden by importing Nixpkgs with `allowBroken = true`.
    broken = (useMetalKit && !effectiveStdenv.isDarwin);

    description = "Inference of LLaMA model in pure C/C++${descriptionSuffix}";
    homepage = "https://github.com/TheTom/llama-cpp-turboquant/";
    license = lib.licenses.mit;

    # Accommodates `nix run` and `lib.getExe`
    mainProgram = "llama-cli";

    # These people might respond, on the best effort basis, if you ping them
    # in case of Nix-specific regressions or for reviewing Nix-specific PRs.
    # Consider adding yourself to this list if you want to ensure this flake
    # stays maintained and you're willing to invest your time. Do not add
    # other people without their consent. Consider removing people after
    # they've been unreachable for long periods of time.

    # Note that lib.maintainers is defined in Nixpkgs, but you may just add
    # an attrset following the same format as in
    # https://github.com/NixOS/nixpkgs/blob/f36a80e54da29775c78d7eff0e628c2b4e34d1d7/maintainers/maintainer-list.nix
    maintainers = with lib.maintainers; [
      philiptaron
      SomeoneSerge
    ];

    # Extend `badPlatforms` instead
    platforms = lib.platforms.all;
  };
})
