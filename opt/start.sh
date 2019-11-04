#!/bin/sh
. /opt/vars
. /opt/functions
FOUND=0
# defaults
ESS=someessid
INT=eth0
WLAN=0
# its need for dropbear
echo > /var/log/lastlog
#if network card exists
lspci -m -n | grep "..:..\.. \"02" > /dev/null
if [ "$?" -eq "0" ]
then
    busybox mount ${LINUXDEVICE} /mnt/lin
    ### W_NAME = Enterprise name from BIOS or serial from file
    if [ -r /mnt/lin/settings.txt ]
    then
	. /mnt/lin/settings.txt
    fi

    if [ -r /mnt/lin/${LANCONF} ]
    then
	. /mnt/lin/${LANCONF}
    fi
    ifconfig eth0 > /dev/urandom

    hostname ${HOSTNAME}
    WKSNAME="-H ${HOSTNAME}"

    if [ "$WLAN" -eq "0" ]
    then
	udhcpc ${HOSTNAME} -n -t 1 -i ${INT} > /dev/null
	if [ "$?" -eq "0" ]
	then
	    # "Found IP for $INT"
	    . /tmp/dhcpvar.sh
	    FOUND=1
	fi
    else
    if [ "$WLAN" -eq "1" ]
    then
	echo "interface: $INT"
	iwpriv $INT authmode 2
	iwconfig $INT key $WLANKEY
	iwconfig $INT essid $ESS
	ifconfig $INT down
	ifconfig $INT up
	### echo "probing essid: $ESS"
	udhcpc ${HOSTNAME} -n -i $INT > /dev/null
	if [ "$?" -eq "0" ]
	then
	    ### echo "Found IP for $INT"
	    ### echo "ESSID: $ESS"
	    . /tmp/dhcpvar.sh
	    FOUND=1
	fi
    fi
fi
if [ "$FOUND" -eq "0" ]
then
    for i in `cat /proc/net/dev | grep eth | cut -d ":" -f 1`
    do
	for j in 1 2
	do
	    echo "Start DHCPC for $i"
	    udhcpc ${HOSTNAME} -n -t 1 -i $i > /dev/null
	    if [ "$?" -eq "0" ]
	    then
		echo "Found IP for $i"
		. /tmp/dhcpvar.sh
		FOUND=1
		cat > /mnt/lin/${LANCONF} <<EOF
WLAN=0
INT=$i
ESS=$ESS
EOF
break
	    fi
	    if [ ! -z $ip ]
	    then
		break
	    fi
	done
    done
fi
if [ "$FOUND" -eq "0" ]
then
    for i in `cat /proc/net/dev | grep ath | cut -d ":" -f 1`
    do
	echo "interface: $i"
	iwpriv $i authmode 2
	iwconfig $i key $WLANKEY
	for e in "$ESS"
	do
	    iwconfig $i essid $e
	    ifconfig $i down
	    ifconfig $i up
	    echo "probing essid: $e"
	    udhcpc ${HOSTNAME} -n -i $i > /dev/null
	    if [ "$?" -eq "0" ]
	    then
		echo "Found IP for $i"
		echo "ESSID: $e"
		cat > /mnt/lin/${LANCONF} <<EOF
WLAN=1
INT=$i
ESS=$e
EOF
		. /tmp/dhcpvar.sh
		FOUND=1
		break
	    fi
	done
    done
fi
# if dhcp address assigned    
if [ ! -z $ip ]
then

    ### INSTALL
    if [ `cat /proc/cmdline|grep -c "hardinstall"` == "1" ]  ### Make partitions and install linux
    then
	echo "INSTALLING linux..."
        cd /install
	sh ./install.sh
	elif [ `cat /proc/cmdline|grep -c "softinstall"` == "1" ]  ### install only soft. Partitions not deleted
        then
	    echo "INSTALLING linux..."
	    cd /install
	    sh ./softinstall.sh
	fi

    fi
else 
    echo "Can't find ip"
fi
umount /mnt/lin
umount /mnt/hd
#gsd
#reboot > /dev/null
###### END