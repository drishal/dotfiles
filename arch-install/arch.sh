pacman -S base base-devel efibootmgr grub linux linux-headers linux-firmware vim nano networkmanager wpa-supplicant iwd --needed
echo "setting hostnam"
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
echo "setting locale"
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "installing grub"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
enabling system services
systemctl enable NetworkManager
systemctl enable iwd
passwd 
