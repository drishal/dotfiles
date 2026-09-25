# Remmina whose VNC dynamic resolution actually resizes the remote (used by htbvnc).
{
  remmina,
  libvncserver,
  fetchpatch,
}:
(remmina.override {
  # libvncclient 0.9.15 sends SetDesktopSize with an uninitialised screen id/x/y,
  # which servers reject as an invalid layout. Fixed upstream after 0.9.15.
  libvncserver = libvncserver.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (fetchpatch {
        url = "https://github.com/LibVNC/libvncserver/commit/8ea6ed0629cc9aeee2f1447c029cc7cc5be5602d.patch";
        hash = "sha256-Fa23Xon5IPn0o3rTgbJe/3ObkKETyLJvws9fUvLVPCA=";
      })
      (fetchpatch {
        url = "https://github.com/LibVNC/libvncserver/commit/041ea576c3dddd6c7169935aaf8889673024fbfc.patch";
        hash = "sha256-XWEhoGBYdW4k4mUK95iSWuCSgEaBcn4rgacMnEUHpj8=";
      })
    ];
  });
}).overrideAttrs
  (old: {
    # Without this a new session keeps the previous session's remote size until the window is resized.
    patches = (old.patches or [ ]) ++ [ ./vnc-dynres-sync.patch ];
  })
