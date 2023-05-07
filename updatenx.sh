#!/bin/sh
#Script to update system using apt-get and update NX Witness Server
# Todo:
# - Add in detecting latest server for all builds from JSON file
# - API call to backup server before installing new client
# - Skip installing new server is version is the same
#############################################################################################
############################################
## Exit script if not root
if [[ `id -u` != 0 ]]; then
    echo "Must be root to run script"
    exit
fi
############################################
# INSTALL DIRS
HANWHADIR="/opt/hanwha/mediaserver"
DWSPECTRUMDIR="/opt/dwspectrum/mediaserver"
############################################

if [ -d "$HANWHADIR" ];
then
    NXSW="HANWHA"
    NXDIR=$WAVEDIR
    NXURL="https://updates.vmsproxy.com/hanwha/releases.json"
elif [ -d "$DWSPECTRUMDIR" ];
then
#https://updates.vmsproxy.com/digitalwatchdog/releases.json
    NXSW="DWSPECTRUM"
    NXDIR=$DWSPECTRUMDIR
    NXURL="https://updates.vmsproxy.com/digitalwatchdog/releases.json"
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
