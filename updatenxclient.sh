#!/bin/bash
# Script to update system using apt-get and update NX Witness Client
# Can be run directly from internet using: curl -s https://raw.githubusercontent.com/rwhiteside90/NXVMS/main/updatenxclient.sh | sudo bash
# JQ is required to parse JSON FILES FROM NX WITNESS AND WILL BE INSTALLED USING APT-GET
# Todo:
# - API call to backup server before installing new client
# Changes:
# Added DEBIAN_FRONTEND=noninteractive
# Added logic to prevent installing older version than what's installed
# Fixed query to select latest version from JSON
#############################################################################################
export DEBIAN_FRONTEND=noninteractive
############################################
# INSTALL DIRS
HANWHADIR="/opt/hanwha/client"
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
#Comment Line out to disable auto update/don't have URL end in / 
DOWNLOADURL="https://raw.githubusercontent.com/rwhiteside90/NXVMS/main" 
### Check if MD5 Hash is blank & download URL set
if [[ "$SCRIPTMD5" != "" ]] && [ -v DOWNLOADURL ]; then
    echo "Script Path: $SCRIPT"
    echo "Script Name: $SCRIPTNAME"
    echo "Script Current Version MD5 Hash: $SCRIPTMD5"
    DOWNLOADFILE=$(wget -NS --content-on-error=off $DOWNLOADURL/$SCRIPTNAME -O /tmp/$SCRIPTNAME --quiet > /dev/null 2>&1)
    RESULT=$?
    #echo $RESULT ONLY CONTINUE IF FILE DOWNLOADED WITH HTTP 200
    if [[ $RESULT -eq 0 ]]; then
        echo "File downloaded..."
        NEWSCRIPTMD5=$(md5sum /tmp/$SCRIPTNAME | cut -d ' ' -f 1)
        if [[ "$NEWSCRIPTMD5" == "" ]]; then
            echo "Unable to calculate updated script MD5 hash. Continuing...."
        elif [[ "$NEWSCRIPTMD5" != "" ]] &&  [[ "$NEWSCRIPTMD5" != "$SCRIPTMD5" ]]; then
            echo "Script outdated, replacing local file..."
            mv -f /tmp/$SCRIPTNAME $SCRIPT
            echo "Script needs to be relaunched... Relaunching..."
            bash $SCRIPT && exit
        else
        echo "No need to update script... Continuing...."
        fi
    fi
else
echo "Unable to calculate script MD5 hash or download URL not set. Continuing...."
fi
############

FindLatestVersion () {
local $NXVERSION
local $NXVERSION2
local $NXCURRENTVERSION
local $NXCURRENTVERSION2

NXBASEURL=`curl -s $JSON | jq '.packages_urls[]|select(. | contains("beta") | not)' | sed 's/"//g'`
NXVERSION=`curl -s $JSON | jq '.releases[]|select(.publication_type | contains("beta") | not)' | jq '.version' | jq --slurp '.[0]' | sed 's/"//g'`
if [[ "$NXVERSION" == *"4."* ]] && [[ "$NXCURRENTVERSION" != "" ]]; then
echo "Detected legacy version 4.x... Exiting..."
exit;
fi
NXCURRENTVERSION=`cat ${NXDIR}/*.*/build_info.json | jq .vmsVersion | sed 's/"//g'`
echo "NX Client Current Version: $NXCURRENTVERSION"
echo "-------------------------------"
echo "NX Base URL: $NXBASEURL"
echo "NX Latest Version: $NXVERSION"

if [[ "$NXVERSION" == "$NXCURRENTVERSION" ]]; then
echo "Latest version already installed... Exiting..."
exit;
fi

NXVERSION2=`echo $NXVERSION | sed -r 's/[.]//g'`
NXCURRENTVERSION2=`echo $NXCURRENTVERSION | sed -r 's/[.]//g'`

if [[ $(($NXVERSION2)) -lt $(($NXCURRENTVERSION2)) ]] && [[ "$NXCURRENTVERSION" != "" ]]; then
echo "Newer version already installed... Exiting..."
exit;
fi
}


echo "Updating system using apt-get....."
apt autoremove -y
apt-get update -y
apt-get install jq -y
apt-get upgrade -y

if [ -d "$HANWHADIR" ];
then
    NXSW="HANWHA"
    NXDIR=$HANWHADIR
    JSON="https://updates.vmsproxy.com/hanwha/releases.json"
    FindLatestVersion
    NXDEBURL="$NXBASEURL/$NXVERSION/linux/wave-client-$NXVERSION-linux_x64.deb"
    echo "NX DEB URL: $NXDEBURL"
elif [ -d "$DWSPECTRUMDIR" ];
then
    NXSW="DWSPECTRUM"
    NXDIR=$DWSPECTRUMDIR
    JSON="https://updates.vmsproxy.com/digitalwatchdog/releases.json"
    FindLatestVersion
    NXDEBURL="$NXBASEURL/$NXVERSION/linux/dwspectrum-client-$NXVERSION-linux_x64.deb"
    echo "NX DEB URL: $NXDEBURL"
elif [ -d "$DWSPECTRUMDIR2" ];
then
    NXSW="DWSPECTRUM"
    NXDIR=$DWSPECTRUMDIR2
    JSON="https://updates.vmsproxy.com/digitalwatchdog/releases.json"
    FindLatestVersion
    NXDEBURL="$NXBASEURL/$NXVERSION/linux/dwspectrum-client-$NXVERSION-linux_x64.deb"
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
echo "Install updated installer for NX Client using file: $F2"
dpkg -i $F2
echo "-------------------"
echo "Removing installer files...."
rm -fr $F2
