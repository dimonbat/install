#!/bin/sh

partition=/dev/`cat /proc/partitions | grep -o -m 1 "[sh]d[a-z]$"`
rootdir=/mnt/lin
. /install/grub-functions.sh
install_device=`resolve_symlink "$partition"`
echo "INSTALL DEVICE $install_device"
install_drive=`convert "$install_device"`
echo "INSTALL DRIVE $install_drive"
root_device=`find_device ${rootdir}`
echo "ROOT DEVICE $root_device"
installdrive=`echo $install_drive | sed -e "s/(\(.*\))/\1/g"`
ROOTD=`echo $root_device | sed -e "s/\//\\\\\\\\\\//g"`
log_file=/tmp/grub.log

grub --no-floppy --batch <<EOF
root ($installdrive,0)
setup $install_drive
parttype ($installdrive,0) 0xbc
quit
EOF
### ASK REBOOT ##EXPERIMENTAL 2009-08-03
ANSW="n"
echo "All done."
echo -n "Are you want to reboot now? (y/n): "
read ANSW
if [ $ANSW == "y" ]
then
echo "You choose REBOOT. proceed..."
reboot
else 
echo "It's your choice...enjoy Linux"
fi