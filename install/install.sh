#! /bin/sh

. ./grub-functions.sh
. /opt/functions
. /opt/vars

UPDATED=0
#partition=/dev/`cat /proc/partitions | grep -o -m 1 "[hs]d[a-z]$"`
partition=/dev/`fdisk -l | grep -m1 "^Disk /dev/[hs]d[a-z]" | grep -o "[hs]d[a-z]"`

if [ "${partition}none" == "/dev/none" ]
then
    echo "Can't find any disks"
    exit
fi

echo "partition to install ${partition}. WARNING!!! All data will be lost!!!"

umount /mnt/lin
umount /mnt/hd
umount ${partition}1


#make label (its need for setup partition)
echo "make label on ${partition}"
parted -s ${partition} mklabel msdos

#Setup partition
parted -s ${partition} mkpart p ext3 0 200M
mdev -s
mkfs.ext2 ${partition}1
tune2fs -c 0 -i 0 ${partition}1
parted -s ${partition} set 1 boot on

#Setup filesystem
mount ${partition}1 /mnt/lin
tar --directory=/mnt/lin -xf rootfs.tar
cp -R boot /mnt/lin/
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
get ${VERSIONTXT} -o /tmp/${VERSIONTXT}
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
		## Experimental 2011-08-11 - add downloading file version.txt
	        if [ -r /tmp/${VERSIONTXT} ]
	        then
		    dos2unix /tmp/${VERSIONTXT}
		    . /tmp/${VERSIONTXT}
	        fi
		# check if variables is empty
	        if [ "${KVERSION}" == "" ]
		then
		    KVERSION=0
		fi
	        if [ "${RAMVERSION}" == "" ]
		then
		    RAMVERSION=0
	        fi
		# write info into file
cat > /mnt/lin/boot/curr_version.txt <<EOF
CURR_KVERSION=$KVERSION
CURR_RAMVERSION=$RAMVERSION
EOF
## End Experimental 2011-08-11
echo "kernel and ram download succesfully"
    	    fi
        fi
    ########## END #############
    fi
#umount /mnt/lin
fi
## CD rom probing
if [ "${UPDATED}" -eq "0" ]
then
    CD=`grep "drive name:" /proc/sys/dev/cdrom/info | cut -f 3`
    mount /dev/${CD} /mnt/cdrom
    cp -R /mnt/cdrom/install/boot/* /mnt/lin/boot/
    if [ "$?" -eq "0" ]
    then
	echo "kernel and ram copied from CD rom succesfully"
    fi
#umount /mnt/hd
umount /mnt/cdrom
fi

#Setup grub
rootdir=/mnt/lin
./grub-functions.sh
install_device=`resolve_symlink "$partition"`
echo "INSTALL DEVICE $install_device"
install_drive=`convert "$install_device"`
echo "INSTALL DRIVE $install_drive"
root_device=`find_device ${rootdir}`
echo "ROOT DEVICE $root_device"
installdrive=`echo $install_drive | sed -e "s/(\(.*\))/\1/g"`
ROOTD=`echo $root_device | sed -e "s/\//\\\\\\\\\\//g"`
log_file=/tmp/grub.log
### Experimental 2010-01-28 (--no-floppy added)
grub --no-floppy --batch <<EOF >$log_file
root ($installdrive,0)
setup $install_drive
parttype ($installdrive,0) 0xbc
quit
EOF

#grub-install ${partition}
grub-set-default --root-directory=/mnt/lin 0
cat boot/grub/menu.lst | sed -e "s/{rootdev}/$ROOTD/g" | sed -e "s/{rootdisk}/$installdrive/g" > /mnt/lin/boot/grub/menu.lst
#umount /mnt/hd
mdev -s
info_read

#internal image storage
echo -n "Internal storage size (Press Enter if you will not use internal storage): "
read INTERNALSTORAGE
if [ "${INTERNALSTORAGE}X" != "X" ]
then
    #Setup partition2 (internal storage)
    parted -s ${partition} mkpart p ext3 200 ${INTERNALSTORAGE}
    mdev -s
    mkfs.ext2 ${partition}2
    tune2fs -c 0 -i 0 ${partition}2
    
    # Set partition 2 partition type    
    grub --no-floppy --batch <<EOF >$log_file
parttype ($installdrive,1) 0xbc
quit
EOF
    WORKDEVICE="/dev/sda3"
else
    INTERNALSTORAGE=0
    WORKDEVICE="/dev/sda2"
fi


# hostname
echo -n "hostname (PRORST): "
read HOSTNAME
if [ "${HOSTNAME}X" == "X" ]
then
    HOSTNAME="PRORST"
fi


# FTP server
echo -n "FTP server (ip or hostname)[press enter if no FPT server]: "
read FTPSERVER

FTPUSERNAME=""
FTPPASSWORD=""
if [ "${FTPSERVER}X" != "X" ]
then
    echo -n "FTP server username: "
    read FTPUSERNAME
    
    echo -n "FTP server password: " 
    read FTPPASSWORD
fi


# CIFS server
echo -n "CIFS server (ip or hostname)[press enter if no CIFS server]: "
read CIFSSERVER

CIFSUSERNAME=""
CIFSPASSWORD=""
CIFSSHARE=""
if [ "${CIFSSERVER}X" != "X" ]
then
    echo -n "CIFS server share: "
    read CIFSSHARE

    echo -n "CIFS server username: "
    read CIFSUSERNAME
    
    echo -n "CIFS server password: " 
    read CIFSPASSWORD
fi


# HTTP server
echo -n "HTTP server (ip or hostname): "
read HTTPSERVER

# Work Device




#save settings
info_save

### ASK REBOOT
ANSW="n"
echo "All done."
echo -n "Are you want to reboot now? (y/n): "
read ANSW
if [ ${ANSW} == "y" ]
then
    ## Reboot
    echo "You choose REBOOT. proceed..."
    reboot
else
    ## not reboot
    echo "It's your choice...enjoy Linux"
fi