#!/usr/bin/env bash
#-------------------------------------------------------------------------
#   ██████╗ ██╗   ██╗ █████╗  ██████╗██╗  ██╗     ██████╗ ███████╗
#  ██╔═══██╗██║   ██║██╔══██╗██╔════╝██║ ██╔╝    ██╔═══██╗██╔════╝
#  ██║   ██║██║   ██║███████║██║     █████╔╝     ██║   ██║███████╗
#  ██║▄▄ ██║██║   ██║██╔══██║██║     ██╔═██╗     ██║   ██║╚════██║
#  ╚██████╔╝╚██████╔╝██║  ██║╚██████╗██║  ██╗    ╚██████╔╝███████║
#   ╚══▀▀═╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝ 
#-------------------------------------------------------------------------
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm pacman-contrib terminus-font
setfont ter-v22b
sed -i 's/^#Para/Para/' /etc/pacman.conf
pacman -S --noconfirm reflector rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -e "-------------------------------------------------------------------------"
echo -e " ██████╗ ██╗   ██╗ █████╗  ██████╗██╗  ██╗     ██████╗ ███████╗"
echo -e "██╔═══██╗██║   ██║██╔══██╗██╔════╝██║ ██╔╝    ██╔═══██╗██╔════╝"
echo -e "██║   ██║██║   ██║███████║██║     █████╔╝     ██║   ██║███████╗"
echo -e "██║▄▄ ██║██║   ██║██╔══██║██║     ██╔═██╗     ██║   ██║╚════██║"
echo -e "╚██████╔╝╚██████╔╝██║  ██║╚██████╗██║  ██╗    ╚██████╔╝███████║"
echo -e " ╚══▀▀═╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝     ╚═════╝ ╚══════╝"
echo -e "-------------------------------------------------------------------------"
echo -e "-Setting up $iso mirrors for faster downloads"
echo -e "-------------------------------------------------------------------------"

reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt

echo -e "\nInstalling prereqs...\n$HR"
pacman -S --noconfirm gptfdisk btrfs-progs

echo "-------------------------------------------------"
echo "---------------Select your disk------------------"
echo "-------------------------------------------------"
lsblk -f
echo "Please enter disk to work on: (example /dev/sda)"
read DISK

function format_disk {
  echo "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"
  read -p "are you sure you want to continue (Y/N):" formatdisk
  case $formatdisk in
    y|Y|yes|Yes|YES)
      echo "--------------------------------------"
      echo -e "\nFormatting disk...\n$HR"
      echo "--------------------------------------"

      # disk prep
      sgdisk -Z ${DISK} # zap all on disk
      sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

      # create partitions
      sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
      sgdisk -n 2::+100M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
      sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
      if [[ ! -d "/sys/firmware/efi" ]]; then
          sgdisk -A 1:set:2 ${DISK}
      fi

      # make filesystems
      echo -e "\nCreating Filesystems...\n$HR"
      if [[ ${DISK} =~ "nvme" ]]; then
      mkfs.vfat -F32 -n "EFIBOOT" "${DISK}p2"
      mkfs.btrfs -L "ROOT" "${DISK}p3" -f
      mount -t btrfs "${DISK}p3" /mnt
      else
      mkfs.vfat -F32 -n "EFIBOOT" "${DISK}2"
      mkfs.btrfs -L "ROOT" "${DISK}3" -f
      mount -t btrfs "${DISK}3" /mnt
      fi
      ;;
    *)
      echo "Rebooting in 3 Seconds ..." && sleep 1
      echo "Rebooting in 2 Seconds ..." && sleep 1
      echo "Rebooting in 1 Second ..." && sleep 1
      reboot now
      ;;
  esac
}

function dual_boot {
  local efipart=$(fdisk -l ${DISK} | grep -e 'EFI System' | head -n 1 | awk '{print $1;}')
  local partnum=$(fdisk -l ${DISK} | grep -e '${DISK}' | wc -l)

  # Change EFI partition label
  fatlabel ${efipart} EFIBOOT

  # Create partition
  sgdisk -n ${partnum}::-0 --typecode=${partnum}:8300 --change-name=${partnum}:'ROOT' ${DISK} # partition N+1 (Root), default start, remaining

  # Create filesystems
  echo -e "\nCreating Filesystems...\n$HR"
  if [[ ${DISK} =~ "nvme" ]]; then
    mkfs.btrfs -L "ROOT" "${DISK}p${partnum}" -f
    mount -t btrfs "${DISK}p${partnum}" /mnt
  else
    mkfs.btrfs -L "ROOT" "${DISK}${partnum}" -f
    mount -t btrfs "${DISK}${partnum}" /mnt
  fi
}

echo "-------------------------------------------------"
echo "----------------Dual booting---------------------"
echo "-------------------------------------------------" 
echo "This will assume an existing EFI partition exists, and that there is unallocated space. No data will be wiped! (Y/N):"
read dualboot

case $dualboot in
  y|Y|yes|Yes|YES)
    dual_boot
    ;;
  n|N|no|No|NO)
    format_disk
    ;;
  *)
    exit
    ;;
esac

ls /mnt | xargs btrfs subvolume delete
btrfs subvolume create /mnt/@
umount /mnt

# mount target
mount -t btrfs -o subvol=@ -L ROOT /mnt
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi

echo "--------------------------------------"
echo "-- Arch Install on Main Drive       --"
echo "--------------------------------------"
pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed
genfstab -U /mnt >> /mnt/etc/fstab
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt/root/QuackOS
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
echo "--------------------------------------"
echo "--GRUB BIOS Bootloader Install&Check--"
echo "--------------------------------------"
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot ${DISK} --force
fi
echo "--------------------------------------"
echo "-- Check for low memory systems <8G --"
echo "--------------------------------------"
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -lt 8000000 ]]; then
    #Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
    mkdir /mnt/opt/swap #make a dir that we can apply NOCOW to to make it btrfs-friendly.
    chattr +C /mnt/opt/swap #apply NOCOW, btrfs needs that.
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile #set permissions.
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    #The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the sysytem itself.
    echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab #Add swap to fstab, so it KEEPS working after installation.
fi
echo "--------------------------------------"
echo "--   SYSTEM READY FOR 1-setup       --"
echo "--------------------------------------"
