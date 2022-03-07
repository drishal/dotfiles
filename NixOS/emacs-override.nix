# with (import <nixpkgs> {});
#{ config, pkgs,inputs, lib ,... }:

(emacsGit.override {
     nativeComp = true;
}).overrideAttrs (old : {
     pname = "emacs";
     version = "head";
     src = fetchFromGitHub {
        owner = "emacs-mirror";
        repo = "emacs";
	rev = "75a15141303bcce89018820b1480bd84136c8df4";
        sha256 = "00vxb83571r39r0dbzkr9agjfmqs929lhq9rwf8akvqghc412apf";
     };
     patches = [];
     configureFlags = old.configureFlags ++ ["--with-pgtk -fuse-ld=gold --enable-link-time-optimization --with-native-compilation"];
     preConfigure = "./autogen.sh";
     buildInputs = old.buildInputs ++ [ autoconf texinfo ];
})

