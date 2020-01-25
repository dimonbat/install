#!/bin/sh

grub --no-floppy --batch <<EOF
root (hd0,0)
setup (hd0)
quit
EOF
### ASK REBOOT 
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