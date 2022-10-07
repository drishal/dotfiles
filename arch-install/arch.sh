pacman -S base base-devel efibootmgr grub linux linux-headers linux-firmware vim nano networkmanager iwd amd-ucode --needed
echo "setting hostnam"
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain archlinux" >> /etc/hosts
echo "archlinux" >> /etc/hostname

# echo "Fstab"
# genfstab -U /mnt >> /mnt/etc/fstab

echo "setting locale"
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

echo "Setting timezone"
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc

echo "installing grub"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "enabling system services"
systemctl enable NetworkManager
systemctl enable iwd

"Setting root password"
passwd 
