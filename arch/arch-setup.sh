#/!bin/bash

echo "arch linux quick setup script" ; echo

# set ROOT_DEVICE
read -p "enter the device to write the os to (ex. /dev/sda): " ROOT_DEVICE

# set ROOT_DEVICE mount point
read -p "enter the path to mount the device to on the current system: " ROOT_MOUNT

# set size for new boot partition
read -p "enter size for new grub bootloader partition (ex. 1M, 1G): " BOOT_SIZE

#set size for partition to install arch to
read -p "enter size for new arch installation partition (recommend at least 6G): " ARCH_PARTITION_SIZE

# update system clock
timedatectl set-ntp true

# create boot and root partitions
echo "34,$BOOT_SIZE,U" | sfdisk $ROOT_DEVICE
echo " ,$ARCH_PARTITION_SIZE" | sfdisk $ROOT_DEVICE 1

# format boot partition as fat32
mkfs.fat -F32 "$ROOT_DEVICE"1

# format root partition as ext4
mkfs.ext4 -F "$ROOT_DEVICE"2

# mount new partitions
mount "$ROOT_DEVICE"2 $ROOT_MOUNT

# generate fstab
genfstab -U $ROOT_MOUNT >> "$ROOT_MOUNT"/etc/fstab

mkdir $ROOT_MOUNT/efi
mount "$ROOT_DEVICE"1 $ROOT_MOUNT/efi

# move network setup script to new partition
mv network-setup /mnt/network-setup

# firmware/base installation
pacstrap -i $ROOT_MOUNT base linux linux-firmware vim man-db sudo grub efibootmgr neofetch openssh --noconfirm

# grub installation & set root password
arch-chroot $ROOT_MOUNT /bin/bash -c "grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB && \
grub-mkconfig -o /boot/grub/grub.cfg && \
echo 'root:password' | chpasswd && \
# locale configuration
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime && \
hwclock --systohc && \
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
locale-gen && \
echo "LANG=_en\_US.UTF-8" > /etc/locale.conf"

umount -R /mnt
