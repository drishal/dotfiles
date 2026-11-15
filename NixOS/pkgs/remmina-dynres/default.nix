# Remmina whose VNC dynamic resolution actually resizes the remote (used by htbvnc).
# nixpkgs' libvncserver carries the libvncclient SetDesktopSize fixes itself now.
{ remmina }:
remmina.overrideAttrs (old: {
  # Without this a new session keeps the previous session's remote size until the window is resized.
  patches = (old.patches or [ ]) ++ [ ./vnc-dynres-sync.patch ];
})
