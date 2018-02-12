#!/bin/bash
##################################################################
# A Project of Daniel Marius Gligor
#
# Title:     Armbian & Raspbian Eth0 Check
# Author:    Daniel Marius Gligor (Mossad)
#            mossadmobile@gmail.com
# Project:   Raspberry Pi and Asus TinkerBoard Stuff
# OS:        Armbian & Raspbian
#
# Copyright: Copyright (c) 2018 Daniel Marius Gligor <mossadmobile@gmail.com>
#
# Purpose:
# Script checks to see if WiFi or Ethernet has a network IP and if not
# restart WiFi or Ethernet
#
# Uses a lock file which prevents the script from running more
# than one at a time.  If lockfile is old, it removes it
#
# Instructions:
# o Install where you want to run it from like /usr/local/bin
# o chmod 0755 /usr/local/bin/checkwifi.sh 
# o Add to crontab (usualy `nano /etc/crontab` and read below...)
#
# Run Every 5 mins - Seems like ever min is over kill unless
# this is a very common problem.  If once a min change */5 to *
# once every 2 mins */5 to */2 ... 
#
# Ad this line to your crontab line if you want this script running 
# at every 5 minutes.
# */5 * * * * root   bash /usr/local/bin/checkwifi.sh > /dev/null 
#
##################################################################
# Settings
# Where and what you want to call the Lockfile
lockfile='/var/run/checkwifi.pid'
# Which Interface do you want to check/fix
utp='wlan0'
# Log file
logfile='/var/log/checkwifi.log'
##################################################################

### Check if log files are in place.
if [ ! -e $logfile ]; then
touch $logfile
fi

echo
echo "Starting script check for $utp $(date)" >> $logfile
echo

# Check to see if there is a lock file
if [ -e $lockfile ]; then
    # A lockfile exists... Lets check to see if it is still valid
    pid=`cat $lockfile`
    if kill -0 &>1 > /dev/null $pid; then
        # Still Valid... lets let it be...
        exit 1
    else
        # Old Lockfile, Remove it
        rm $lockfile
    fi
fi
# If we get here, set a lock file using our current PID#
echo $$ > $lockfile

# We can perform check
echo "Performing Network check for $utp" >> $logfile
if ifconfig $utp | grep -q "inet addr:" ; then
    echo "Interface $utp is connected..." >> $logfile
else
    echo "Network connection down! Attempting reconnection." >> $logfile
    ifdown $utp
    sleep 5
    ifup --force $utp
    sleep 10
fi
 
# Check is complete, Remove Lock file and exit
rm $lockfile

if [ ! "$(fping -I$utp -c1 -t300 192.168.1.1)" ]; then
        echo "Warning: connection lost at $(date) -- restart" >> $logfile 
        ifdown $utp
        sleep 5
        ifup --force $utp
        sleep 10
        echo
        echo "----------------------------------------------------" >> $logfile
else
        echo "Connexion is OK at $(date)" >> $logfile
        echo
        echo "----------------------------------------------------" >> $logfile
fi

exit 0

##################################################################
# End of Script
##################################################################
