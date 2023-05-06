#!/bin/sh
NXURL="https://wavevms.com/hanwha/wave-ubuntu-x64-server/"

echo "Updating system using apt-get....."
apt-get update -y
apt-get upgrade -y

echo "-------------------"
echo "Downloading latest version of NX from URL: $NXURL......"
cd /tmp
F=$(wget --content-disposition $NXURL 2>&1 | grep "Saving to:")
F2=`echo "$F" | sed 's/Saving to: ‘//g'`
F2=`echo "$F2" | sed 's/’//g'`
F2=`echo "$F2" | sed 's/ //g'`

echo "Saved download to /tmp/$F2....."
echo "-------------------"
ls -lh $F2
echo "-------------------"
echo "Install updated installer for NX using file: $F2"
dpkg -i $F2
echo "-------------------"
echo "Removing installer files...."
rm -fr $F2
echo "-------------------"
echo "Rebooting server in 60 seconds...."
shutdown -r 1
