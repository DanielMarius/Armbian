#!/bin/bash
##################################################################
# A Project of Daniel Marius Gligor
#
# Title:     Armbian Eth Check
# Author:    Daniel Marius Gligor (Mossad)
#            mossadmobile@gmail.com
# Project:   Raspberry Pi and Asus TinkerBoard Stuff
# OS:        Armbian & Raspbian
#
# Copyright: Copyright (c) 2018 Daniel Marius Gligor <mossadmobile@gmail.com>
#            
#
# Purpose:
#
# Script checks to see if WiFi or Ethernet has a network IP and if not
# restart WiFi or Eth
#
# Uses a lock file which prevents the script from running more
# than one at a time.  If lockfile is old, it removes it
#
# Instructions:
#
# o Install where you want to run it from like /usr/local/bin
# o chmod 0755 /usr/local/bin/checketh.sh 
# o Add to crontab (usualy `nano /etc/crontab`)
#
# Run Every 5 mins - Seems like ever min is over kill unless
# this is a very common problem.  If once a min change */5 to *
# once every 2 mins */5 to */2 ... 
#
# */5 * * * * root   bash /usr/local/bin/checketh.sh > /dev/null 
#
##################################################################
# Settings
# Where and what you want to call the Lockfile
lockfile='/var/run/checketh.pid'
# Which Interface do you want to check/fix
utp='eth0'
##################################################################
echo
echo "Starting Eth0 check for $utp $(date)" >> /var/log/routereth.log
echo
echo 

# Check to see if there is a lock file
if [ -e $lockfile ]; then
    # A lockfile exists... Lets check to see if it is still valid
    pid=`cat $lockfile`
    if kill -0 &>1 > /dev/null $pid; then
        # Still Valid... lets let it be...
        #echo "Process still running, Lockfile valid"
        exit 1
    else
        # Old Lockfile, Remove it
        #echo "Old lockfile, Removing Lockfile"
        rm $lockfile
    fi
fi
# If we get here, set a lock file using our current PID#
#echo "Setting Lockfile"
echo $$ > $lockfile

# We can perform check
echo "Performing Network check for $utp"
if ifconfig $utp | grep -q "inet addr:" ; then
    echo "Network is Okay"
else
    echo "Network connection down! Attempting reconnection."
    ifdown $utp
    sleep 5
    ifup --force $utp
    ifconfig $utp | grep "inet addr"
fi

echo 
echo "Current Setting:"
ifconfig $utp | grep "inet addr:"
echo
 
# Check is complete, Remove Lock file and exit
#echo "process is complete, removing lockfile"
rm $lockfile

if ! [ "$(ping -I eth0 -c 1 192.168.1.1)" ]; then
        echo "Warning: connection lost at $(date) -- restart" >> /var/log/routereth.log 
        ifdown $utp
        sleep 5
        ifup --force $utp
else
echo "Connexion is OK at $(date)" >> /var/log/routereth.log
fi

exit 0

##################################################################
# End of Script
##################################################################
