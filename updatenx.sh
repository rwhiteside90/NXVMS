#!/bin/sh
HANWHADIR="/opt/hanwha/mediaserver"
DWSPECTRUMDIR="/opt/dwspectrum/mediaserver"
if [ -d "$HANWHADIR" ];
then
    NXSW="HANWHA"
    NXDIR=$WAVEDIR
    NXURL="https://wavevms.com/hanwha/wave-ubuntu-x64-server/"
elif [ -d "$DWSPECTRUMDIR" ];
then
#https://updates.vmsproxy.com/digitalwatchdog/releases.json
    NXSW="DWSPECTRUM"
    NXDIR=$DWSPECTRUMDIR
    NXURL="https://updates.networkoptix.com/digitalwatchdog/5.0.0.36634/linux/dwspectrum-server-5.0.0.36634-linux_x64.deb"
else
	echo "No NXVMS software detected... Exiting..."
  exit;
fi


echo "Updating system using apt-get....."
apt autoremove -y
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
