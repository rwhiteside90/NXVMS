#!/bin/bash
#Script to update system using apt-get and update NX Witness Server
#JQ is required to parse JSON FILES FROM NX WITNESS AND WILL BE INSTALLED USING APT-GET
# Todo:
# - API call to backup server before installing new client
# - Skip installing new server is version is the same
#############################################################################################
############################################
# INSTALL DIRS
HANWHADIR="/opt/hanwha/mediaserver"
DWSPECTRUMDIR="/opt/dwspectrum/mediaserver"
############################################
## Exit script if not root
if [[ `id -u` != 0 ]]; then
    echo "Must be root to run script"
    exit
fi
############################################

FindLatestVersion () {
local $NXBASEURL
local $NXVERSION

JSON=$1
NXBASEURL=`curl -s $JSON | jq '.packages_urls[]|select(. | contains("beta") | not)' | sed 's/"//g'`
NXVERSION=`curl -s $JSON | jq '.releases[1]|select(.publication_type | startswith("release"))' | jq '.version' | sed 's/"//g'`
if [[ "$NXVERSION" == *"4."* ]]; then
echo "Detected legacy version 4.x... Exiting..."
exit;
fi
echo "NX Base URL: $NXBASEURL"
echo "NX Version: $NXVERSION"

}

echo "Updating system using apt-get....."
apt autoremove -y
apt-get update -y
apt-get install jq -y
apt-get upgrade -y

if [ -d "$HANWHADIR" ];
then
    NXSW="HANWHA"
    NXDIR=$WAVEDIR
    JSON="https://updates.vmsproxy.com/hanwha/releases.json"
    FindLatestVersion $JSON
    NXDEBURL="$NXBASEURL/$NXVERSION/linux/wave-server-$NXVERSION-linux_x64.deb"
    echo "NX DEB URL: $NXDEBURL"
elif [ -d "$DWSPECTRUMDIR" ];
then
    NXSW="DWSPECTRUM"
    NXDIR=$DWSPECTRUMDIR
    JSON="https://updates.vmsproxy.com/digitalwatchdog/releases.json"
    FindLatestVersion $JSON
    NXDEBURL="$NXBASEURL/$NXVERSION/linux/dwspectrum-server-$NXVERSION-linux_x64.deb"
    echo "NX DEB URL: $NXDEBURL"
else
    echo "No NXVMS software detected... Exiting..."
    exit;
fi


echo "-------------------"
echo "Downloading latest version of NX from URL: $NXDEBURL......"
cd /tmp
F=$(wget --content-disposition $NXDEBURL 2>&1 | grep "Saving to:")
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
