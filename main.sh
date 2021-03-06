#!/bin/sh

#
#disk stuff
#
echo "Install to which disk? (Use full disk path e.g. /dev/sda)"
read diskname
#make the disk a GPT disk
echo "Zeroing disk..."
dd if=/dev/zero of=$diskname count=1024
echo "Disk zeroed"
echo "Making disk GPT..."
parted -a optimal $diskname mklabel GPT
echo "Creating UEFI partition..."
parted -a optimal $diskname mkpart primary 0% 512MB
echo "Creating root partition..."
parted -a optimal $diskname mkpart primary 512 100%
disk1 = "${diskname}1"
disk2 = "${diskname}2"
mkfs.ext4 $disk2
mkfs.fat -F32 $disk1
mount $disk2 /mnt
mkdir /mnt/boot
mount $disk1 /mnt/boot
