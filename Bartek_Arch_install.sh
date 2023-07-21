#!/bin/bash
# Insatlator ArchLinux
# Zakładam że internet działa przed uruchomieniem

# 1 Ustawiam układ klawiatury i czczionkę konsoli
loadkeys pl
setfont Lat2-Terminus16.psfu.gz -m 8859-2

# 2 Aktywuje synchronizacje czasu
timedatectl set-ntp true

# 3 Partycjonowanie dysku NIE DZIAŁA
echo -e "\nPodaj ścieżkę do dysku twardego"
read dysk

# Partycje na dysku
# tworzę tablice partycji typu GPT
parted -s $dysk mklabel gpt

# pomijam początkowe 100 mb ochronny mbr
# 512 mb fat16 /boot/efi
parted -s $dysk mkpart primary fat16 100 612
#parted -s set "$dysk1" boot on #nie działa
mkfs.fat -F 16 "$dysk1"

# 60-80 GB btrfs /
parted -s $dysk mkpart primary btrfs 613 82533
#parted -s set "$dysk2" root on #nie działa
mkfs.btrfs "$dysk2"

# 4 GB swap
parted -s $dysk mkpart primary linux-swap 82534 86629
#parted -s set "$dysk3" swap on #nie działa
mkswap "$dysk3"
swapon "$dysk3"

# reszta ext4 /home
size= (($(lsblk -bno SIZE $dysk | head -1))/1024)/1024

parted -s $dysk mkpart primary ext4 86630 size
mkfst.ext4 "$dysk4"

# 4 montuje system plików
mount "$dysk2" /mnt
mkdir --parents /mnt/boot/EFI
mount "$dysk1" /mnt/boot/EFI
mkdir /mnt/home
mount "$dysk4" /mnt/home

# 5 ustalam serwery do instalacji systemu
reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

# 6.1 ustalam czy potrzebne jest środowisko graficzne
echo -e "\nPodaj preferowane środowisko graficzne(kde/gnome/xfce/*puste*)"
read env

if env == "gnome"; then
    env_pkgs = "gnome gnome-extra gufw"
else if env == "kde"; then
    env_pkgs = "plasma gufw"
else if env == "xfce"; then
    env_pkgs = "xfce4 xfce4-goodies gufw"
else if env == ""; then
    env_pkgs = ""
else

fi

# 6.2 insatluje podstawowe pakiety
pacman -Sy
pacstrap /mnt base linux linux-firmware intel-ucode nano e2fsprogs btrfs-progs grub man-db man-pages texinfo base-devel dhcpcd networkmanager sudo gvfs gvfs-mtp reflector git efibootmgr wpa_supplicant wireless_tools os-prober ufw less xdg-user-dirs wget curl $env_pkgs

# 7 Konfiguracja systemu
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

#strefa czasowa
ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
hwclock --systohc
#język systemu
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "pl_PL.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=pl_PL.UTF-8" > /etc/locale.conf
#układ klawiatury
echo "KEYMAP=pl" > /etc/vconsole.conf
echo "FONT=Lat2-Terminus16" >> /etc/vconsole.conf
echo "FONT_MAP=8859-2" >> /etc/vconsole.conf
#nazwa systemu
echo "arch" > /etc/hostname

#hosts
echo "127.0.0.1	localhost" > /etc/hosts
echo "::1	localhost" >> /etc/hosts
#initramfs
mkinitcpio -P
#brak hasła root
passwd -d root
#boot loader GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
#uzytkownik
useradd -m -G wheel -s "/bin/bash" bkonecki

# 8 koniec i restart systemu
exit
umount -R /mnt
reboot
