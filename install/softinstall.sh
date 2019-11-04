#! /bin/sh

#. ./grub-functions.sh
. /opt/functions
. /opt/vars
#partition=/dev/`cat /proc/partitions | grep -o -m 1 "[sh]d[a-z]$"`
partition=/dev/`fdisk -l | grep -m1 "^Disk /dev/[hs]d[a-z]" | grep -o "[hs]d[a-z]"`

umount /mnt/lin
umount /mnt/hd
umount ${partition}1

#Setup filesystem
busybox mount ${partition}1 /mnt/lin
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