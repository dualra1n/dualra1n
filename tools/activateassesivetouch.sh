#!/usr/bin/env bash


version="2.0"
os=$(uname)
dir="$(pwd)/binaries/$os"
max_args=1
arg_count=0
disk=8

remote_cmd() {
    sleep 1
    "$dir"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "$@"
    sleep 1
}

remote_cp() {
    sleep 1
    "$dir"/sshpass -p 'alpine' scp -r -o StrictHostKeyChecking=no -P2222 "$@"
    sleep 1
}

   # Execute the commands once the rd is booted
    if [ "$os" = 'Linux' ]; then
        sudo "$dir"/iproxy 2222 22 &
    else
        "$dir"/iproxy 2222 22 &
    fi

    if ! ("$dir"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "echo connected" &> /dev/null); then
        echo "[*] Waiting for the ramdisk to finish booting"
    fi

    while ! ("$dir"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "echo connected" &> /dev/null); do
        sleep 1
    done

    
    echo "[*] Testing for baseband presence"
    if [ "$(remote_cmd "/usr/bin/mgask HasBaseband | grep -E 'true|false'")" = "true" ] && [[ "${cpid}" == *"0x700"* ]]; then # checking if your device has baseband 
        disk=7
    elif [ "$(remote_cmd "/usr/bin/mgask HasBaseband | grep -E 'true|false'")" = "false" ]; then
        if [[ "${cpid}" == *"0x700"* ]]; then
            disk=6
        else
            disk=7
        fi
    fi
dataB=$((disk + 1))

remote_cmd "/sbin/mount_apfs /dev/disk0s1s${dataB} /mnt9/"

remote_cp root@localhost:/mnt9/mobile/Library/Preferences/com.apple.Accessibility.plist work/com.apple.Accessibility.plist
sleep 1

if [ "$os" = "Linux" ]; then
    activated=$(/binaries/Linux/PlistBuddy work/com.apple.Accessibility.plist -c "Print AssistiveTouchEnable")
else
    activated=$(/usr/bin/plutil -extract "AssistiveTouchEnable" xml1 -o - work/com.apple.Accessibility.plist)
fi 

case "${activated}" in
0)
    if [ "$os" = "Linux" ]; then
        binaries/Linux/PlistBuddy work/com.apple.Accessibility.plist -c "Set AssistiveTouchEnabled 1"
    else
        /usr/bin/plutil -replace AssistiveTouchEnabled -string 1  work/com.apple.Accessibility.plist
    fi 
    
;;
*)
    if [ "$os" = "Darwin" ]; then
        /usr/bin/plutil -insert AssistiveTouchEnabled -string 1 work/com.apple.Accessibility.plist
    else
        binaries/Linux/PlistBuddy work/com.apple.Accessibility.plist -c "Add AssistiveTouchEnabled string 1" 
    fi
    
    
;;
esac
