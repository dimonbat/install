#! /bin/sh

#. ./grub-functions.sh
. /opt/functions
. /opt/vars
#partition=/dev/`cat /proc/partitions | grep -o -m 1 "[sh]d[a-z]$"`
partition=/dev/`fdisk -l | grep -m1 "^Disk /dev/[hs]d[a-z]" | grep -o "[hs]d[a-z]"`

umount /mnt/lin
umount /mnt/hd
umount ${partition}1
#Setup partition
#parted -s ${partition} rm 1
#parted -s ${partition} rm 2
#parted -s ${partition} rm 3
#parted -s ${partition} rm 4
#parted -s ${partition} mkpart p ext3 1 100M
#mkfs.ext3 ${partition}1
#tune2fs -c 0 -i 0 ${partition}1
#parted -s ${partition} set 1 boot on
#Setup filesystem
busybox mount ${partition}1 /mnt/lin
#tar --directory=/mnt/lin -xf rootfs.tar
#cp -R boot /mnt/lin/
#CD=`grep "drive name:" /proc/sys/dev/cdrom/info | cut -f 3`
#busybox mount /dev/$CD /mnt/cdrom
UPDATED=0
ping -q -c 1 ${UPDATESERVER} > /dev/null
if [ "$?" -eq "0" ]
then
lftp <<ZZZ
open ftp://${UPDATEADDRESS}
get init.cpio.gz -o /mnt/lin/boot/init1.cpio.gz
get kernel -o /mnt/lin/boot/kernel1
get kernel.md5sum -o /mnt/lin/boot/kernel.md5sum
get init.md5sum -o /mnt/lin/boot/init.md5sum
quit
ZZZ
if [ "$?" -eq "0" -o -r /mnt/lin/boot/kernel1 -o -r /mnt/lin/boot/init1.cpio.gz ]
then
#echo "Update ram & kernel..."
    md5sum -c /mnt/lin/boot/kernel.md5sum
    if [ "$?" -eq "0" ]
    then
        md5sum -c /mnt/lin/boot/init.md5sum
        if [ "$?" -eq "0" ]
        then
mv /mnt/lin/boot/init1.cpio.gz /mnt/lin/boot/init.cpio.gz
mv /mnt/lin/boot/kernel1 /mnt/lin/boot/kernel
UPDATED=1
echo "kernel and ram download succesfully"
        fi
    fi
fi
#umount /mnt/lin
fi
## CD rom probing
if [ "${UPDATED}" -eq "0" ]
then
CD=`grep "drive name:" /proc/sys/dev/cdrom/info | cut -f 3`
busybox mount /dev/$CD /mnt/cdrom
cp -R /mnt/cdrom/install/boot/* /mnt/lin/boot/
if [ "$?" -eq "0" ]
then
    echo "kernel and ram copied from CD rom succesfully"
fi
#umount /mnt/hd
umount /mnt/cdrom
fi
#Modify 2011-08-09 - load only kernel and ram now
#Setup grub
#rootdir=/mnt/lin
#./grub-functions.sh
#install_device=`resolve_symlink "$partition"`
#echo "INSTALL DEVICE $install_device"
#install_drive=`convert "$install_device"`
#echo "INSTALL DRIVE $install_drive"
#root_device=`find_device ${rootdir}`
#echo "ROOT DEVICE $root_device"
#installdrive=`echo $install_drive | sed -e "s/(\(.*\))/\1/g"`
#ROOTD=`echo $root_device | sed -e "s/\//\\\\\\\\\\//g"`
#log_file=/tmp/grub.log
### Experimental 2010-01-28 (--no-floppy added)
#grub --no-floppy --batch <<EOF >$log_file
#root ($installdrive,0)
#setup $install_drive
#parttype ($installdrive,0) 0xbc
#quit
#EOF

#grub-install ${partition}
#grub-set-default --root-directory=/mnt/lin 0
#cat boot/grub/menu.lst | sed -e "s/{rootdev}/$ROOTD/g" | sed -e "s/{rootdisk}/$installdrive/g" > /mnt/lin/boot/grub/menu.lst
#ANSW="n"
echo "All done."
echo -n "Are you want to reboot now? (y/n): "
read ANSW
if [ ${ANSW} == "y" ]
then
echo "You choose REBOOT. proceed..."
reboot
else
echo "It's your choice...enjoy Linux"
fi