{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation {
  pname = "batdistrack";
  version = "unstable";

  src = fetchFromGitHub {
    owner = "oliver-machacik";
    repo = "batdistrack";
    rev = "master";
    sha256 = "sha256-IHDSxUv5UUYilQJsf8oT0oiU9vmDpiUYcLXXPdM66o4=";
  };

  doBuild = false;

  installPhase = ''
    mkdir -p $out/bin/
    cp batdistrack $out/bin/batdistrack
  '';
}
