#!/bin/sh
#this only works if you use qemu vms lul. not making this generic.
dd if=/dev/zer of=/dev/vda count=512
parted -a optimal /dev/vda mklabel GPT
parted -a optimal /dev/vda mkpart primary 0% 512
parted -a optimal /dev/vda mkpart primary 512 100%
mkfs.fat -F32 /dev/vda1
mkfs.ext4 /dev/vda2
mount /dev/vda2 /mnt
mkdir /mnt/boot
mount /dev/vda1 /mnt/boot
pacstrap /mnt base linux linux-firmware dhcpcd netctl
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
echo $'127.0.0.1	localhost\n::1	localhost\n127.0.1.1	autoarch.localdomain	autoarch' > /etc/hosts
echo autoarch >  /etc/hostname
echo $'Interface=enp1s0\nConnection=ethernet\nIP=dhcp' > /etc/netctl/main
netctl enable main
pacman -S  grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=ARCH
mkinitcpio -P
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -P #hehe
#TODO FINISH THE FILE
