#!/bin/bash
# Script to install DW Spectrum VMS Client
############################################################################################
export DEBIAN_FRONTEND=noninteractive
############################################
# INSTALL DIRS

DWSPECTRUMDIR="/opt/dwspectrum/client"
DWSPECTRUMDIR2="/opt/digitalwatchdog/client"
############################################
## Exit script if not root
if [[ `id -u` != 0 ]]; then
    echo "Must be root to run script"
    exit
fi
## Exit if not running in bash
BASHCHECK="false"
if [[ "${BASH_VERSINFO:-0}" -ge 4 ]]; then
        BASHCHECK="true"
fi
if [ $BASHCHECK = "false" ]; then
        echo "Script must be ran in BASH... Exiting..."
        exit
fi
############################################
# Check for updated version
SCRIPT=$(realpath "$0")
SCRIPTNAME=$0
SCRIPTMD5=$(md5sum $SCRIPT | cut -d ' ' -f 1)
if [[ "$SCRIPTMD5" != "" ]]; then
echo "Script Path: $SCRIPT"
echo "Script Name: $SCRIPTNAME"
echo "Script Current Version MD5 Hash: $SCRIPTMD5"
wget https://raw.githubusercontent.com/rwhiteside90/NXVMS/main/$SCRIPTNAME -O /tmp/$SCRIPTNAME
NEWSCRIPTMD5=$(md5sum /tmp/$SCRIPTNAME | cut -d ' ' -f 1)
if [[ "$NEWSCRIPTMD5" == "" ]]; then
echo "Unable to calculate updated script MD5 hash. Continuing...."
elif [[ "$NEWSCRIPTMD5" != "" ]] &&  [[ "$NEWSCRIPTMD5" != "$SCRIPTMD5" ]]; then
echo "Script outdated, replacing local file..."
mv -f /tmp/$SCRIPTNAME $SCRIPT
echo "Script needs to be relaunched... Relaunching..."
bash $SCRIPT && exit
exit;
else
echo "No need to update script... Continuing...."
fi
else
echo "Unable to calculate script MD5 hash. Continuing...."
fi
############

FindLatestVersion () {
local $NXBASEURL
local $NXVERSION
local $NXCURRENTVERSION

NXBASEURL=`curl -s $JSON | jq '.packages_urls[]|select(. | contains("beta") | not)' | sed 's/"//g'`
NXVERSION=`curl -s $JSON | jq '.releases[]|select(.publication_type | contains("beta") | not)' | jq '.version' | jq --slurp '.[0]' | sed 's/"//g'`
if [[ "$NXVERSION" == *"4."* ]] && [[ "$NXCURRENTVERSION" != "" ]]; then
echo "Detected legacy version 4.x... Exiting..."
exit;
fi
NXCURRENTVERSION=`cat ${NXDIR}/build_info.json | jq .vmsVersion | sed 's/"//g'`
echo "NX Current Version: $NXCURRENTVERSION"
echo "-------------------------------"
echo "NX Base URL: $NXBASEURL"
echo "NX Latest Version: $NXVERSION"

if [[ "$NXVERSION" == "$NXCURRENTVERSION" ]] && [[ "$NXCURRENTVERSION" != "" ]]; then
echo "Latest version already installed... Exiting..."
exit;
fi
}


echo "Updating system using apt-get....."
apt autoremove -y
apt-get update -y
apt-get install jq -y
apt-get upgrade -y


    NXSW="DWSPECTRUM"
    if [ -d "$DWSPECTRUMDIR" ]; then
        NXDIR=$DWSPECTRUMDIR
    else
        NXDIR=$DWSPECTRUMDIR2
    fi
    JSON="https://updates.vmsproxy.com/digitalwatchdog/releases.json"
    FindLatestVersion
    NXDEBURL="$NXBASEURL/$NXVERSION/linux/dwspectrum-client-$NXVERSION-linux_x64.deb"
    echo "NX DEB URL: $NXDEBURL"



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
echo "Running apt --fix-broken install -y...."
apt --fix-broken install -y
echo "-------------------"
echo "Install updated installer for NX using file: $F2"
dpkg -i $F2
echo "-------------------"
echo "Removing installer files...."
rm -fr $F2
echo "-------------------"
