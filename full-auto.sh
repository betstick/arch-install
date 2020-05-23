#!/bin/sh
#this only works if you use qemu vms lul. not making this generic.
dd if=/dev/zero of=/dev/vda count=1000000
parted -a optimal /dev/vda mklabel GPT
parted -a optimal /dev/vda mkpart primary 0% 512
parted -a optimal /dev/vda mkpart primary 512 100%
mkfs.fat -F32 /dev/vda1
mkfs.ext4 /dev/vda2
mount /dev/vda2 /mnt
mkdir /mnt/boot
mount /dev/vda1 /mnt/boot
pacstrap /mnt base linux linux-firmware dhcpcd netctl grub efibootmgr nano bash-completion
genfstab -U /mnt >> /mnt/etc/fstab
echo -e "127.0.0.1	localhost\n::1	localhost\n127.0.1.1	autoarch.localdomain	autoarch" > /mnt/etc/hosts
echo autoarch > /mnt/etc/hostname
echo -e "Interface=enp1s0\nConnection=ethernet\nIP=dhcp" > /mnt/etc/netctl/main
#listen, it was either this nonsense, or i had to create a second script...
arch-chroot /mnt netctl enable main
arch-chroot /mnt systemctl enable dhcpcd
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=ARCH
#enable serial console
echo -e 'GRUB_TERMINAL_INPUT="console serial"' >> /mnt/etc/default/grub
echo -e 'GRUB_TERMINAL_OUTPUT="gfxterm serial"' >> /mnt/etc/default/grub
echo -e 'GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200"' >> /mnt/etc/default/grub
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot /mnt mkinitcpio -P #hehe
echo -e 'echo "root:password" | chpasswd' > /mnt/password
chmod +x /mnt/password
arch-chroot /mnt ./password
rm /mnt/password
