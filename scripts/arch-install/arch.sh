#!/usr/bin/env bash
echo "updating mirrorlist and pacman.conf"
sed -i '/\[options\]/a\
Color\
ILoveCandy\
CheckSpace\
ParallelDownloads = 20' /etc/pacman.conf
cp mirrorlist /etc/pacman.d/mirrorlist

pacman -S base base-devel efibootmgr grub linux-zen linux-zen-headers linux-firmware vim nano networkmanager iwd intel-ucode amd-ucode --needed
echo "enter a hostname: "
read -r hostname 
echo "setting hostname $hostname"
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts
echo "$hostname" >> /etc/hostname

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
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "enabling system services"
systemctl enable NetworkManager
systemctl enable iwd

# user settings
echo "set the root password: "
passwd 
echo "Set username to add: "
read -r username
echo "adding user $username"
useradd -m $username
usermod -aG wheel $username
echo "set the password for $username"
passwd $username

#nvidia config
while true; do
    read -p "Do you use nvidia? (yes/no): " nvidia_use
    case $nvidia_use in
        [yY][eE][sS]|[yY])
            # Install nvidia-dkms package
            pacman -S nvidia-dkms

            # Replace MODULES in /etc/mkinitcpio.conf
            sed -i 's/^MODULES=.*$/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf

            # Run mkinitcpio -P
            mkinitcpio -P

            # Replace GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub
            sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*$/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1"/' /etc/default/grub

            # Update grub configuration
            grub-mkconfig -o /boot/grub/grub.cfg
            break
            ;;
        [nN][oO]|[nN])
            echo "You don't use nvidia."
            break
            ;;
        *)
            echo "Invalid answer, please reply with yes or no."
            continue
            ;;
    esac
done
