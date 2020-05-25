#!/bin/sh
#this only works if you run it on arch lul. not making this generic. its for personal use, steal parts if you want them.
echo "GIMME NAMES"
read vmname
echo "domain? (.local is a sane default)"
read domain
echo "disk size in MB?(2048MB IS THE MINIMUM"
read size

mkdir "$vmname"
cd "$vmname"

dir=$(pwd)

#make a sparse disk of custom size
dd if=/dev/zero of="$vmname".img  bs=1k seek="$size" count=1

#partition the disks, disk can be made arbitrary size
parted -a optimal "$vmname".img mklabel GPT
parted -a optimal "$vmname".img mkpart primary 0% 512
parted -a optimal "$vmname".img mkpart primary 512 100%

#mount the boot dir onto a loop dev
loop1=$(losetup -f) #we'll need this to unmount later!
echo $loop1
losetup -f -P --offset 1048576 --sizelimit 511704576 "$vmname".img

#mount the root dir onto a loop dev
loop2=$(losetup -f)
echo $loop2
losetup -f -P --offset 511705088 "$vmname".img

#make the filesystems
mkfs.fat -F32 "$loop1"
mkfs.ext4 "$loop2"

#mount everything to real directories
mkdir mont
mount "$loop2" mont/
mkdir mont/boot
mount "$loop1" mont/boot

#start the actual install on our image
pacstrap mont/ base linux linux-firmware dhcpcd netctl grub efibootmgr nano bash-completion
genfstab -U mont/ >> mont/etc/fstab

#set up the network
echo -e "127.0.0.1	localhost\n::1	localhost\n127.0.1.1	$vmname.localdomain	$vmname" > mont/etc/hosts
echo "$vmname" > mont/etc/hostname
echo -e "Interface=enp1s0\nConnection=ethernet\nIP=dhcp" > mont/etc/netctl/main

#listen, it was either this nonsense, or i had to create a second script...
arch-chroot mont/ netctl enable main
arch-chroot mont/ systemctl enable dhcpcd
arch-chroot mont/ grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=ARCH

#enable serial console
echo -e 'GRUB_TERMINAL_INPUT="console serial"' >> mont/etc/default/grub
echo -e 'GRUB_TERMINAL_OUTPUT="gfxterm serial"' >> mont/etc/default/grub
echo -e 'GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200"' >> mont/etc/default/grub

#finish grub setup and initramfs
arch-chroot mont/ grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot mont/ mkinitcpio -P #hehe

#set root password to password, im lazy
echo -e 'echo "root:password" | chpasswd' > mont/password
chmod +x mont/password
arch-chroot mont/ ./password
rm mont/password
#install is done.

#cleanup time!
#release the loops and delete mont
umount "$vmname"/mont/boot
umount "$vmname"/mont
rm -rf mont
