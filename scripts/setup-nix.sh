nix run --no-write-lock-file --impure github:nix-community/home-manager -- switch   --flake ~/dotfiles
sudo nixos-rebuild switch --flake ~/dotfiles -L
home-manager switch --flake ~/dotfiles
