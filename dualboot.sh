#!/usr/bin/env bash

mkdir -p logs
mkdir -p boot
set -e

log="last".log
cd logs
touch "$log"
cd ..

{

echo "[*] Command ran:`if [ $EUID = 0 ]; then echo " sudo"; fi` ./dualboot.sh $@"

# =========
# Variables
# ========= 
ipsw="ipsw/*.ipsw" # put your ipsw 
version="2.0"
os=$(uname)
dir="$(pwd)/binaries/$os"
max_args=1
arg_count=0
disk=8
extractedIpsw="ipsw/extracted/"

# =========
# Functions
# =========
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

step() {
    for i in $(seq "$1" -1 0); do
        if [ "$(get_device_mode)" = "dfu" ]; then
            break
        fi
        printf '\r\e[K\e[1;36m%s (%d)' "$2" "$i"
        sleep 1
    done
    printf '\e[0m\n'
}

print_help() {
    cat << EOF
Usage: $0 [Options] [ subcommand | iOS version which are you] remember you need to have 10 gb free, no sean brurros y vean primero. (put your ipsw in the directory ipsw)
iOS 15 - 14 Dualboot tool ./dualboot --dualboot 15.7 (the ios of your device) 
put iPSW file of iOS 14 into the iPSW directory, you must make sure that this is the correct ipsw for the iphone. only ios 14 - 14.8.1

Options:
    --dualboot          Dualboot your iOS 15 device with iOS 14 
    --jail-palera1n     Use only if you have the palera1n jailbreak installed, it will create partition on disk + 1 because palera1n create a new partition. disk0s1s8 however if you jailbreaked with palera1n the disk would be disk0s1s9"
    --get-ipsw          Sometimes this does not work well ,using this will download a ipsw of your version which you want to dualboot. its better that you download the ipsw manually. if you will use this ,use it alone and the version --get-ipsw 14.2.
    --jailbreak         Jailbreak your second ios. you can use it when your device boot correctly the second ios
    --taurine           this will install the jailbreak of Taurine. ./dualboot.sh --jailbreak 14.3 --taurine 
    --help              Print this help
    --fix-hb            This command will fix the home button on a10 and a11 devices or well try it. please dont use this.
    --dfuhelper         A helper to help get A11 devices into DFU mode from recovery mode
    --boot              Boot your second iOS  
    --dont-create-part  Don't create the partitions if you have already created 
    --restorerootfs     Remove the partitions of the dualbooted iOS
    --fix-preboot       Restores the preboot partition with the prebootBackup
    --debug             Debug the script

Subcommands:
    clean               Deletes the created boot files
help:
    In case that the iDevice does not boot use: ./dualboot.sh --dualboot 14.3 --debug --dont-create-part --fix-boot 



The iOS version argument should be the iOS version of your device.
It is required when starting from DFU mode.
EOF
}

parse_opt() {
    case "$1" in
        --)
            no_more_opts=1
            ;;
        --dualboot)
            dualboot=1
            ;;
        --boot)
            boot=1
            ;;
        --fix-boot)
            fixBoot=1
            ;;
        --fix-hb)
            fixHB=1
            ;;
        --fixhardware)
            fixhardware=1
            ;;
        --get-ipsw)
            getIpsw=1
            ;;
        --fix-preboot)
            fix_preboot=1
            ;;
        --jail-palera1n)
            jail_palera1n=1
            ;;
        --jailbreak)
            jailbreak=1
            ;;
        --taurine)
            taurine=1
            ;;
        --dfuhelper)
            dfuhelper=1
            ;;
        --dont-create-part)
            dont_createPart=1
            ;;
        --restorerootfs)
            restorerootfs=1
            ;;
        --debug)
            debug=1
            ;;
        --help)
            print_help
            exit 0
            ;;
        *)
            echo "[-] Unknown option $1. Use $0 --help for help."
            exit 1;
    esac
}

parse_arg() {
    arg_count=$((arg_count + 1))
    case "$1" in
        dfuhelper)
            dfuhelper=1
            ;;
        clean)
            clean=1
            ;;
        *)
            version="$1"
            ;;
    esac
}

parse_cmdline() {
    for arg in $@; do
        if [[ "$arg" == --* ]] && [ -z "$no_more_opts" ]; then
            parse_opt "$arg";
        elif [ "$arg_count" -lt "$max_args" ]; then
            parse_arg "$arg";
        else
            echo "[-] Too many arguments. Use $0 --help for help.";
            exit 1;
        fi
    done
}

recovery_fix_auto_boot() {
    "$dir"/irecovery -c "setenv auto-boot true"
    "$dir"/irecovery -c "saveenv"
}

_info() {
    if [ "$1" = 'recovery' ]; then
        echo $("$dir"/irecovery -q | grep "$2" | sed "s/$2: //")
    elif [ "$1" = 'normal' ]; then
        echo $("$dir"/ideviceinfo | grep "$2: " | sed "s/$2: //")
    fi
}

_pwn() {
    pwnd=$(_info recovery PWND)
    if [ "$pwnd" = "" ]; then
        echo "[*] Pwning device"
        "$dir"/gaster pwn
        sleep 2
        #"$dir"/gaster reset
        #sleep 1
    fi
}

_reset() {
        echo "[*] Resetting DFU state"
        "$dir"/gaster reset
}

get_device_mode() {
    if [ "$os" = "Darwin" ]; then
        apples="$(system_profiler SPUSBDataType 2> /dev/null | grep -B1 'Vendor ID: 0x05ac' | grep 'Product ID:' | cut -dx -f2 | cut -d' ' -f1 | tail -r)"
    elif [ "$os" = "Linux" ]; then
        apples="$(lsusb | cut -d' ' -f6 | grep '05ac:' | cut -d: -f2)"
    fi
    local device_count=0
    local usbserials=""
    for apple in $apples; do
        case "$apple" in
            12a8|12aa|12ab)
            device_mode=normal
            device_count=$((device_count+1))
            ;;
            1281)
            device_mode=recovery
            device_count=$((device_count+1))
            ;;
            1227)
            device_mode=dfu
            device_count=$((device_count+1))
            ;;
            1222)
            device_mode=diag
            device_count=$((device_count+1))
            ;;
            1338)
            device_mode=checkra1n_stage2
            device_count=$((device_count+1))
            ;;
            4141)
            device_mode=pongo
            device_count=$((device_count+1))
            ;;
        esac
    done
    if [ "$device_count" = "0" ]; then
        device_mode=none
    elif [ "$device_count" -ge "2" ]; then
        echo "[-] Please attach only one device" > /dev/tty
        kill -30 0
        exit 1;
    fi
    if [ "$os" = "Linux" ]; then
        usbserials=$(cat /sys/bus/usb/devices/*/serial)
    elif [ "$os" = "Darwin" ]; then
        usbserials=$(system_profiler SPUSBDataType 2> /dev/null | grep 'Serial Number' | cut -d: -f2- | sed 's/ //')
    fi
    if grep -qE '(ramdisk tool|SSHRD_Script) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{1,2} [0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}' <<< "$usbserials"; then
        device_mode=ramdisk
    fi
    echo "$device_mode"
}

_wait() {
    if [ "$(get_device_mode)" != "$1" ]; then
        echo "[*] Waiting for device in $1 mode"
    fi

    while [ "$(get_device_mode)" != "$1" ]; do
        sleep 1
    done

    if [ "$1" = 'recovery' ]; then
        recovery_fix_auto_boot;
    fi
}

_dfuhelper() {
    local step_one;
    deviceid=$( [ -z "$deviceid" ] && _info normal ProductType || echo $deviceid )
    if [[ "$1" = 0x801* && "$deviceid" != *"iPad"* ]]; then
        step_one="Hold volume down + side button"
    else
        step_one="Hold home + power button"
    fi
    echo "[*] To get into DFU mode, you will be guided through 2 steps:"
    echo "[*] Press any key when ready for DFU mode"
    read -n 1 -s
    step 3 "Get ready"
    step 4 "$step_one" &
    sleep 3
    "$dir"/irecovery -c "reset" &
    sleep 1
    if [[ "$1" = 0x801* && "$deviceid" != *"iPad"* ]]; then
        step 10 'Release side button, but keep holding volume down'
    else
        step 10 'Release power button, but keep holding home button'
    fi
    sleep 1

    if [ "$(get_device_mode)" = "recovery" ]; then
        _dfuhelper
    fi

    if [ "$(get_device_mode)" = "dfu" ]; then
        echo "[*] Device entered DFU!"
    else
        echo "[-] Device did not enter DFU mode, rerun the script and try again"
       exit;
    fi
}

_kill_if_running() {
    if (pgrep -u root -x "$1" &> /dev/null > /dev/null); then
        # yes, it's running as root. kill it
        sudo killall $1 &> /dev/null
    else
        if (pgrep -x "$1" &> /dev/null > /dev/null); then
            killall $1 &> /dev/null
        fi
    fi
}

_boot() {
    _pwn
    sleep 1
    _reset
    sleep 1
    
    echo "[*] Booting device"

    "$dir"/irecovery -f "blobs/"$deviceid"-"$version".der"
    sleep 1

    "$dir"/irecovery -f "boot/${deviceid}/iBSS.img4"
    sleep 1

    "$dir"/irecovery -f "boot/${deviceid}/iBEC.img4"
    sleep 3
    
    if [ "$fixHB" = "1" ]; then
        "$dir"/irecovery -c "dorwx"
        if [[ "$deviceid" == iPhone9,[1-4] ]] || [[ "$deviceid" == "iPhone10,"* ]]; then # i put this however that does not work because ibootpath2 is not working on ios 14 
            "$dir"/irecovery -f other/payload/payload_t8010.bin
        else
            "$dir"/irecovery -f other/payload/payload_t8015.bin
        fi
        sleep 3
        "$dir"/irecovery -c "go"
        sleep 1
        "$dir"/irecovery -c "go xargs -v"
        sleep 1
        "$dir"/irecovery -c "go xfb"
        sleep 1
        "$dir"/irecovery -c "go boot disk0s1s8"
    else
        if [[ "$cpid" == *"0x801"* ]]; then
            "$dir"/irecovery -c "go"
            sleep 2
        else
           "$dir"/irecovery -c "bootx"
            sleep 2
        
        fi
    fi


    "$dir"/irecovery -f "boot/${deviceid}/devicetree.img4"
    sleep 1 

    "$dir"/irecovery -c "devicetree"
    sleep 1

   if [ -d "boot/${deviceid}/FUD" ]; then # that will load the files which are located on fud directory of ios 15 preboot however that does not change anthing ? well idk
        for i in $(ls boot/$deviceid/FUD/*.img4)
        do
            "$dir"/irecovery -f $i
            sleep 1
            "$dir"/irecovery -c "firmware"
        done        
    fi
    
    "$dir"/irecovery -v -f "boot/${deviceid}/trustcache.img4"    

    "$dir"/irecovery -c "firmware"
    sleep 1

    "$dir"/irecovery -f "boot/${deviceid}/kernelcache.img4"
    sleep 1

    "$dir"/irecovery -c "bootx"
    exit;
}

_exit_handler() {
    [ $? -eq 0 ] && exit
    echo "[-] An error occurred"

    if [ -d "logs" ]; then
        cd logs
        mv "$log" FAIL_${log}
        cd ..
    fi

    echo "[*] A failure log has been made. If you're going ask for help, please attach the latest log."
}
trap _exit_handler EXIT

# ===========
# Fixes
# ===========

# Prevent Finder from complaning
if [ "$os" = 'Darwin' ]; then
    defaults write -g ignore-devices -bool true
    defaults write com.apple.AMPDevicesAgent dontAutomaticallySyncIPods -bool true
    killall Finder
fi

# ============
# Dependencies
# ============
if [ "$os" = "Linux"  ]; then
    chmod +x getSSHOnLinux.sh
    sudo bash ./getSSHOnLinux.sh &
    if command -v darling &>/dev/null; then
        echo "darling is installed"
    else 
        sudo wget https://github.com/darlinghq/darling/releases/download/v0.1.20220704/darling_0.1.20220704.focal_amd64.deb -P other/
        sudo dpkg -i other/darling_0.1.20220704.focal_amd64.deb
    fi
fi

if [ "$os" = 'Linux' ]; then
    linux_cmds='lsusb'
fi

for cmd in curl unzip python3 git ssh scp killall sudo grep pgrep ${linux_cmds}; do
    if ! command -v "${cmd}" > /dev/null; then
        echo "[-] Command '${cmd}' not installed, please install it!";
        cmd_not_found=1
    fi
done
if [ "$cmd_not_found" = "1" ]; then
    exit 1
fi


# Download gaster
if [ -e "$dir"/gaster ]; then
    "$dir"/gaster &> /dev/null > /dev/null | grep -q 'usb_timeout: 5' && rm "$dir"/gaster
fi

if [ ! -e "$dir"/gaster ]; then
    curl -sLO https://static.palera.in/deps/gaster-"$os".zip
    unzip gaster-"$os".zip
    mv gaster "$dir"/
    rm -rf gaster gaster-"$os".zip
fi

# Check for pyimg4
if ! python3 -c 'import pkgutil; exit(not pkgutil.find_loader("pyimg4"))'; then
    echo '[-] pyimg4 not installed. Press any key to install it, or press ctrl + c to cancel'
    read -n 1 -s
    python3 -m pip install pyimg4
fi

# Update submodules
git submodule update --init --recursive

# Re-create work dir if it exists, else, make it
if [ -e work ]; then
    rm -rf work
    mkdir work
else
    mkdir work
fi

chmod +x "$dir"/*

# ============
# Start
# ============

echo "dualboot | Version 2.0"
echo "Written by edwin and some code of palera1n :) | Some code also from the ramdisk of Nathan | thanks MatthewPierson, Ralph0045, and all people creator of path file boot"
echo ""

version="beta"
parse_cmdline "$@"

if [ "$debug" = "1" ]; then
    set -o xtrace
fi

if [ "$clean" = "1" ]; then
    rm -rf  work blobs/ boot/"$deviceid"/  ipsw/*
    echo "[*] Removed the created boot files"
    exit
fi


# Get device's iOS version from ideviceinfo if in normal mode
echo "[*] Waiting for devices"
while [ "$(get_device_mode)" = "none" ]; do
    sleep 1;
done
echo $(echo "[*] Detected $(get_device_mode) mode device" | sed 's/dfu/DFU/')

if grep -E 'pongo|checkra1n_stage2|diag' <<< "$(get_device_mode)"; then
    echo "[-] Detected device in unsupported mode '$(get_device_mode)'"
    exit 1;
fi

if [ "$(get_device_mode)" != "normal" ] && [ -z "$version" ] && [ "$dfuhelper" != "1" ]; then
    echo "[-] You must pass the version your device is on when not starting from normal mode"
    exit
fi

if [ "$(get_device_mode)" = "ramdisk" ]; then
    # If a device is in ramdisk mode, perhaps iproxy is still running?
    _kill_if_running iproxy
    echo "[*] Rebooting device in SSH Ramdisk"
    if [ "$os" = 'Linux' ]; then
        sudo "$dir"/iproxy 2222 22 &
    else
        "$dir"/iproxy 2222 22 &
    fi
    sleep 1
    remote_cmd "/sbin/reboot"
    _kill_if_running iproxy
    _wait recovery
fi

if [ "$(get_device_mode)" = "normal" ]; then
    version=${version:-$(_info normal ProductVersion)}
    arch=$(_info normal CPUArchitecture)
    if [ "$arch" = "arm64e" ]; then
        echo "[-] dualra1n doesn't, and never will, work on non-checkm8 devices"
        exit
    fi
    echo "Hello, $(_info normal ProductType) on $version!"

    echo "[*] Switching device into recovery mode..."
    "$dir"/ideviceenterrecovery $(_info normal UniqueDeviceID)
    _wait recovery
fi

# Grab more info
echo "[*] Getting device info..."
cpid=$(_info recovery CPID)
model=$(_info recovery MODEL)
deviceid=$(_info recovery PRODUCT)

echo "$cpid"
echo "$model"
echo "$deviceid"

if [ "$dfuhelper" = "1" ]; then
    echo "[*] Running DFU helper"
    _dfuhelper "$cpid"
    exit
fi

ipswurl=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$dir"/jq '.firmwares | .[] | select(.version=="'$version'")' | "$dir"/jq -s '.[0] | .url' --raw-output)


if [ "$restorerootfs" = "1" ]; then
    rm -rf "blobs/"$deviceid"-"$version".shsh2" "boot-$deviceid" .tweaksinstalled
fi

# Have the user put the device into DFU
if [ "$(get_device_mode)" != "dfu" ]; then
    recovery_fix_auto_boot;
    _dfuhelper "$cpid" || {
        echo "[-] failed to enter DFU mode, run dualboot.sh again"
        exit -1
    }
fi
sleep 2


if [ "$boot" = "1" ]; then # call boot in order to boot it 
    _boot
fi

if [ "$getIpsw" = "1" ]; then # download specific ipsw for your device however the problem is that you will have to install ipsw
    if  command -v ipsw &>/dev/null; then
        cd ipsw/
        echo "You already have installed iPSW"
        ipsw download ipsw --device $deviceid --version $version
        sleep 1
        cd ..
        exit;
    else 
        if [ "$os" = "Darwin" ]; then
            brew install blacktop/tap/ipsw
        else
            sudo apt-get install ipsw
        fi
    fi
fi

    # =========
    # extract ipsw 
    # =========

# extracting ipsw
echo "Extracting iPSW, hang on please ..." # this will extract the ipsw into ipsw/extracted
unzip -n $ipsw -d "ipsw/extracted"
if [ "$fixBoot" = "1" ]; then
    cd work/
    "$dir"/pzb -g BuildManifest.plist "$ipswurl"
    cd ..
else
    cp -rv "$extractedIpsw/BuildManifest.plist" work/
fi

if [ "$os" = 'Darwin' ]; then
    if [ ! -f "ipsw/out.dmg" ]; then # this would create a dmg file which can be mounted an restore a patition
        asr -source "$extractedIpsw$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" -target ipsw/out.dmg --embed -erase -noprompt --chunkchecksum --puppetstrings
    fi
else 
    dmgfile="$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')" # that is to know what is the name of rootfs
    echo "$dmgfile"
fi


# ============
# Ramdisk
# ============

# Dump blobs, and install pogo if needed 
if [ true ]; then
    mkdir -p blobs

    cd ramdisk
    chmod +x sshrd.sh
    echo "[*] Creating ramdisk"
    tweaks=1
    ./sshrd.sh 15.6 

    echo "[*] Booting ramdisk"
    ./sshrd.sh boot
    cd ..
    # remove special lines from known_hosts
    if [ -f ~/.ssh/known_hosts ]; then
        if [ "$os" = "Darwin" ]; then
            sed -i.bak '/localhost/d' ~/.ssh/known_hosts
            sed -i.bak '/127\.0\.0\.1/d' ~/.ssh/known_hosts
        elif [ "$os" = "Linux" ]; then
            sed -i '/localhost/d' ~/.ssh/known_hosts
            sed -i '/127\.0\.0\.1/d' ~/.ssh/known_hosts
        fi
    fi

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

    echo $disk
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

    # that is in order to know the partitions needed
    if [ "$jail_palera1n" = "1" ]; then
        disk=$(($disk + 1)) # if you have the palera1n jailbreak that will create + 1 partition for example your jailbreak is installed on disk0s1s8 that will create a new partition on disk0s1s9 so only you have to use it if you have palera1n
    fi
    echo $disk
    dataB=$(($disk + 1))
    prebootB=$(($dataB + 1))
    echo $dataB
    echo $prebootB

    remote_cmd "/usr/bin/mount_filesystems"

    has_active=$(remote_cmd "ls /mnt6/active" 2> /dev/null)
    if [ ! "$has_active" = "/mnt6/active" ]; then
        echo "[!] Active file does not exist! Please use SSH to create it"
        echo "    /mnt6/active should contain the name of the UUID in /mnt6"
        echo "    When done, type reboot in the SSH session, then rerun the script"
        echo "    ssh root@localhost -p 2222"
        exit
    fi
    active=$(remote_cmd "cat /mnt6/active" 2> /dev/null)
    echo "Backing up preboot partition... please dont delete directory prebootBackup" # this will backup your perboot parition in case that was deleted by error 
    mkdir -p "prebootBackup"
    if [ ! -d "prebootBackup/${deviceid}" ]; then
        mkdir -p "prebootBackup/${deviceid}"
        if [ ! $(remote_cp root@localhost:/mnt6/ "prebootBackup/${deviceid}") ]; then # that had a error so in case the error the script wont stop 
            echo "Finished backup"
        fi
    fi
    
    mkdir -p "boot/${deviceid}"
    mkdir -p "boot/${deviceid}"
    if [ "$fixhardware" = "1" ]; then
        cp -rv "prebootBackup/${deviceid}/mnt6/${active}/usr/standalone/firmware/FUD" "boot/${deviceid}/" # load the fud in order to load file like touch or homebutton, idk know if that work because i just have iphone6s but you can do it 
    fi

    if [ "$fix_preboot" = "1" ]; then
        remote_cp "prebootBackup/${deviceid}/mnt6" root@localhost:/
        echo "finish to bring back preboot:)" # that will restore preboot
        exit;
    fi


    if [ "$restorerootfs" = "1" ]; then
        echo "[*] Removing dualboot"
        if [ "$(remote_cmd "/System/Library/Filesystems/apfs.fs/apfs.util -p /dev/disk0s1s${disk}")" == 'Update' ]; then # that will check if the partition is correct in order to dont delete a partition of the system
            echo "error partition, maybe that partition is important so it could be deleted by apfs_deletefs, that is bad"
            exit; 
        fi
        # this eliminate dualboot paritions 
        remote_cmd "/sbin/apfs_deletefs disk0s1s${disk} > /dev/null || true"
        remote_cmd "/sbin/apfs_deletefs disk0s1s${dataB} > /dev/null || true"
        remote_cmd "/sbin/apfs_deletefs disk0s1s${prebootB} > /dev/null || true"
        remote_cmd "/usr/sbin/nvram auto-boot=true"
        echo "[*] Done! Rebooting your device"
        remote_cmd "/sbin/reboot"
        exit;
    fi

    #if [ ! -e blobs/"$deviceid"-"$version".shsh2 ]; then
    #    remote_cmd "cat /dev/rdisk1" | dd of=dump.raw bs=256 count=$((0x4000)) 
    #    "$dir"/img4tool --convert -s blobs/"$deviceid"-"$version".shsh2 dump.raw
    #    echo "[*] Converting blob"
    #    sleep 3
    #fi
    #"$dir"/img4tool -e -s $(pwd)/blobs/"$deviceid"-"$version".shsh2 -m work/IM4M
    #rm dump.raw
    remote_cp root@localhost:/mnt6/"$active"/System/Library/Caches/apticket.der blobs/"$deviceid"-"$version".der
    cp -av blobs/"$deviceid"-"$version".der work/IM4M

    if [ "$jailbreak" = "1" ]; then
        echo "patching kernel" # this will send and patch the kernel
        cp -r "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
        cp -rv work/"$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" work/kernelcache 
        
        if [[ "$deviceid" == "iPhone8"* ]] || [[ "$deviceid" == "iPad6"* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw --extra work/kpp.bin
        else
            python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw
        fi
        
        remote_cmd "/sbin/mount_apfs /dev/disk0s1s${disk} /mnt8/"
        remote_cmd "/sbin/umount /dev/disk0s1s2"
        remote_cmd "/sbin/mount_apfs /dev/disk0s1s${dataB} /mnt2/"
        remote_cmd "/sbin/mount_apfs /dev/disk0s1s${prebootB} /mnt4/"
        remote_cp work/kcache.raw root@localhost:/mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw
        remote_cp boot/"${deviceid}"/kernelcache.img4 "root@localhost:/mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kernelcache"
        remote_cp binaries/Kernel15Patcher.ios root@localhost:/mnt8/private/var/root/Kernel15Patcher.ios
        remote_cmd "/usr/sbin/chown 0 /mnt8/private/var/root/Kernel15Patcher.ios"
        remote_cmd "/bin/chmod 755 /mnt8/private/var/root/Kernel15Patcher.ios"
        sleep 1
        if [ ! $(remote_cmd "/mnt8/private/var/root/Kernel15Patcher.ios /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched") ]; then
            echo "you have the kernelpath already installed "
        fi
        sleep 2
        remote_cp root@localhost:/mnt4/"$active"/System/Library/Caches/com.apple.kernelcaches/kcache.patched work/ # that will return the kernelpatcher in order to be patched again and boot with it 
        "$dir"/Kernel64Patcher work/kcache.patched work/kcache.patchedB -f -s $(if [[ "$version" = "15."* ]]; then echo "-e"; fi) $(if [ ! "$taurine" = "1" ]; then echo "-l"; fi)

        if [[ "$deviceid" == *'iPhone8'* ]] || [[ "$deviceid" == *'iPad6'* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/kcache.im4p -f rkrn --extra work/kpp.bin --lzss
        elif [ "$tweaks" = "1" ]; then
            python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/kcache.im4p -f rkrn --lzss
        fi

        remote_cp work/kcache.im4p root@localhost:/mnt4/"$active"/System/Library/Caches/com.apple.kernelcaches/
        remote_cmd "img4 -i /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.im4p -o /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kernelcache -M /mnt4/$active/System/Library/Caches/apticket.der"
        remote_cmd "rm -f /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.im4p"
        python3 -m pyimg4 img4 create -p work/kcache.im4p -o work/kernelcache.img4 -m work/IM4M

        #"$dir"/kerneldiff work/kcache.raw work/kcache.patchedB work/kc.bpatch
        #"$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o work/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [ "$os" = 'Linux' ]; then echo "-J"; fi`
        #remote_cp root@localhost:/mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kernelcachd work/kernelcache.img4
        cp -rv "work/kernelcache.img4" "boot/${deviceid}"
        
        echo "Installing Pogo into Tips and TrollStore on apple TV app"
        unzip -n other/pogoMod14.ipa -d "other/"
        remote_cmd "/bin/mkdir -p /mnt8/Applications/Pogo.app && /bin/mkdir -p /mnt8/Applications/trollstore.app" # thank opa you are a tiger xd 
        echo "Copying Pogo and TrollStore so hang on please ..."
        remote_cp other/trollstore.app root@localhost:/mnt8/Applications/
        if [ ! $(remote_cmd "trollstoreinstaller TV") ]; then
            echo "You have to install TrollStore in order to intall Taurine"
        fi

        remote_cp other/Payload/Pogo.app root@localhost:/mnt8/Applications/
        echo "Copying Jailbreak Files"
        remote_cmd "chmod +x /mnt8/Applications/Pogo.app/Pogo* && /usr/sbin/chown 33 /mnt8/Applications/Pogo.app/Pogo && /bin/chmod 755 /mnt8/Applications/Pogo.app/PogoHelper && /usr/sbin/chown 0 /mnt8/Applications/Pogo.app/PogoHelper" 

        if [ "$taurine" = 1 ]; then
            echo "Installing Taurine"
            remote_cp other/taurine/* root@localhost:/mnt8/
            echo "Task finished, it will now reboot"
            remote_cmd "/sbin/reboot"
            exit;
        fi
        remote_cp other/Payload/Pogo.app root@localhost:/mnt8/Applications/
        echo "Copying Jailbreak files..."
        remote_cmd "chmod +x /mnt8/Applications/Pogo.app/Pogo* && /usr/sbin/chown 33 /mnt8/Applications/Pogo.app/Pogo && /bin/chmod 755 /mnt8/Applications/Pogo.app/PogoHelper && /usr/sbin/chown 0 /mnt8/Applications/Pogo.app/PogoHelper" 

        if [ ! $(remote_cmd "trollstoreinstaller TV") ]; then
            echo "you have to install trollstore in order to intall taurine"
        fi
        echo "installing palera1n jailbreak, thanks palera1n team"
        echo "[*] Copying files to rootfs"
        remote_cmd "rm -rf /mnt8/jbin /mnt8/.installed_palera1n"
        sleep 1
        remote_cmd "mkdir -p /mnt8/jbin/binpack /mnt8/jbin/loader.app"
        sleep 1

        # download jbinit files
        cd other/rootfs/jbin
        rm -f jb.dylib jbinit jbloader launchd
        curl -L https://static.palera.in/deps/rootfs.zip -o rfs.zip
        unzip rfs.zip -d .
        unzip rootfs.zip -d .
        rm rfs.zip rootfs.zip
        cd ../../..

        sleep 1
        # this is the jailbreak of palera1n being installing 
        curl -L https://static.palera.in/binpack.tar -o other/rootfs/jbin/binpack/binpack.tar        
        cp -v other/post.sh other/rootfs/jbin/
        remote_cp -r other/rootfs/* root@localhost:/mnt8/
        remote_cmd "ldid -s /mnt8/jbin/launchd /mnt8/jbin/jbloader /mnt8/jbin/jb.dylib"
        remote_cmd "chmod +rwx /mnt8/jbin/launchd /mnt8/jbin/jbloader /mnt8/jbin/post.sh"
        remote_cmd "tar -xvf /mnt8/jbin/binpack/binpack.tar -C /mnt8/jbin/binpack/"
        sleep 1
        remote_cmd "rm /mnt8/jbin/binpack/binpack.tar"
        remote_cmd "/usr/sbin/nvram auto-boot=true"
        echo "[*] DONE ... now reboot and boot again"        
        remote_cmd "/sbin/reboot"
        exit;

    fi
    

    if [ "$dualboot" = "1" ]; then
        if [ -z "$dont_createPart" ]; then # if you have already your second ios you can omited with this
            echo "[*] Creating partitions"
            
        	if [ ! $(remote_cmd "/sbin/newfs_apfs -o role=i -A -v SystemB /dev/disk0s1") ] && [ ! $(remote_cmd "/sbin/newfs_apfs -o role=0 -A -v DataB /dev/disk0s1") ] && [ ! $(remote_cmd "/sbin/newfs_apfs -o role=D -A -v PrebootB /dev/disk0s1") ]; then # i put this in case that resturn a error the script can continuing
                echo "[*] partitions created, continuing..."
	        fi
		    
            echo "partitions are already created"
            echo "mounting filesystems "
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${disk} /mnt8/"
            sleep 1
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${dataB} /mnt9/" # this mount partitions which are needed by dualboot
            sleep 1
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${prebootB} /mnt4/"
            sleep 1
            
            if [ ! $(remote_cmd "cp -av /mnt2/keybags /mnt9/") ]; then # this are keybags without this the system wont work 
                echo "copied keybags"
            fi
             

            echo "Copying filesystem...(This may take up to 20 minutes because its trough SSH)"
            if command -v rsync &>/dev/null; then
                echo "rsync installed"
            else 
                echo "you dont have rsync installed so the script will take much more time to copy the rootfs file, so install rsync in order to be faster, on mac brew install rsync on linux apt install rsync"
            fi
            
            echo "Copying RootFS..."
            if [ "$os" = "Darwin" ]; then
                if [ ! $("$dir"/sshpass -p 'alpine' rsync -rvz -e 'ssh -p 2222' --progress ipsw/out.dmg root@localhost:/mnt8) ]; then
                    remote_cp ipsw/out.dmg root@localhost:/mnt8 # this will copy the root file in order to it is mounted and restore partition      
                fi
            else 
                if [ ! $("$dir"/sshpass -p 'alpine' rsync -rvz -e 'ssh -p 2222' --progress "$extractedIpsw$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')" root@localhost:/mnt8) ]; then
                    remote_cp "$extractedIpsw$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')" root@localhost:/mnt8 # this will copy the root file in order to it is mounted and restore partition      
                fi
                # on linux this will be different because asr. this just mount the rootfs and copying all files to partition 
                sleep 2
                dmg_disk=$(remote_cmd "/usr/sbin/hdik /mnt8/${dmgfile} | head -3 | tail -1 | sed 's/ .*//'")
                remote_cmd "/sbin/mount_apfs -o ro $dmg_disk /mnt5/"
                echo "it is extracting the files so please hang on ......."
                remote_cmd "cp -na /mnt5/* /mnt8/"
                sleep 2
                remote_cmd "/sbin/umount $dmg_disk"
                remote_cmd "rm -rv /mnt8/${dmgfile}"
            fi
            # that reboot is strange because i can continue however when i want to use apfs_invert that never work so i have to reboot on linux is ineccessary but i have to let it to avoid problems 
            remote_cmd "/usr/sbin/nvram auto-boot=false"
            remote_cmd "/sbin/reboot"
            _wait recovery
            sleep 4
            _dfuhelper "$cpid"
            cd ramdisk 
            ./sshrd.sh boot
            cd ..
            sleep 10
            while ! (remote_cmd "echo connected" &> /dev/null); do
                sleep 1
            done
            if [ "$os" = "Darwin" ]; then
                remote_cmd "/System/Library/Filesystems/apfs.fs/apfs_invert -d /dev/disk0s1 -s ${disk} -n out.dmg" # this will mount the root file system and would restore the partition 
            fi
            sleep 1
            echo "[*] doing some configuration"
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${disk} /mnt8/"
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${dataB} /mnt9/"
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${prebootB} /mnt4/"
            remote_cmd "cp -na /mnt8/private/var/. /mnt9/" # this will copy all file which is needed by dataB
            remote_cmd "mount_filesystems"
            remote_cmd "cp -na /mnt6/. /mnt4/" # copy preboot to prebootB
            if [ ! $(remote_cmd "cp -a /mnt2/mobile/Library/Preferences/com.apple.Accessibility* /mnt9/mobile/Library/Preferences/") ]; then
                echo "Error activating AssistiveTouch"
            fi
            

        fi
        remote_cmd "/usr/sbin/nvram auto-boot=false"
        remote_cmd "/sbin/reboot"
        _wait recovery
        sleep 4
        _dfuhelper "$cpid"
        sleep 3

        echo "copying files to work"
        if [ "$fixBoot" = "1" ]; then # i put it because my friend tested on his ipad and that does not boot so when we download all file from the internet so not extracting ipsw that boot fine idk why 
            cd work
            #that will download the files needed
            sleep 1
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/iBSS[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/DeviceTree[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"

            if [ "$os" = 'Darwin' ]; then
                "$dir"/pzb -g Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache "$ipswurl"
            else
                "$dir"/pzb -g Firmware/"$(../binaries/Linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')".trustcache "$ipswurl"
            fi
            cd ..
        else
            #that will extract the files needed
            cp -r "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/iBSS[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            cp -r "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/iBEC[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            cp -r "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/DeviceTree[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            cp -r "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"

            if [ "$os" = 'Darwin' ]; then
                cp -r "$extractedIpsw"/Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache work/
            else
                cp -r "$extractedIpsw"/Firmware/"$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:RestoreRamDisk:Info:Path" | sed 's/"//g')".trustcache work/
            fi
        fi
        echo "patching file boots ..."
        if [ ! "$fixhardware" = "1" ]; then
            "$dir"/img4 -i work/*.trustcache -o work/trustcache.img4 -M work/IM4M -T rtsc
        fi

        "$dir"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBSS[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]dfu[/]//')" work/iBSS.dec
        "$dir"/iBoot64Patcher work/iBSS.dec work/iBSS.patched
        "$dir"/img4 -i work/iBSS.patched -o work/iBSS.img4 -M work/IM4M -A -T ibss

        if [ "$fixBoot" = "1" ]; then # fixboot will download the boot files, sometimes that fix most of boot 
            "$dir"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" work/iBEC.dec
        else
            "$dir"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBEC[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]dfu[/]//')" work/iBEC.dec
        fi
        "$dir"/iBoot64Patcher work/iBEC.dec work/iBEC.patched -b "rd=disk0s1s${disk} wdt=-1 keepsyms=1 debug=0x2014e -v `if [ "$cpid" = '0x8960' ] || [ "$cpid" = '0x7000' ] || [ "$cpid" = '0x7001' ]; then echo "-restore"; fi`" -n 
        
        if [ "$fixHB" = "1" ]; then # that work fine on ios 14.5 up but the boot procces should be different if some one want to try it go ahead because i dont have a a10 or a11 :)
           if [[ "$deviceid" == iPhone9,[1-4] ]] || [[ "$deviceid" == "iPhone10,"* ]]; then
                "$dir"/iBootpatch2 --t8010 work/iBEC.patched work/iBEC.patched2
            else
                "$dir"/iBootpatch2 --t8015 work/iBEC.patched work/iBEC.patched2
            fi
            "$dir"/img4 -i work/iBEC.patched2 -o work/iBEC.img4 -M work/IM4M -A -T ibec
        else 
            "$dir"/img4 -i work/iBEC.patched -o work/iBEC.img4 -M work/IM4M -A -T ibec
        fi

        "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o work/kcache.raw
        "$dir"/Kernel64PatcherA work/kcache.raw work/kcache.patched -a -f `if [ "$fixBoot" = "1" ]; then echo "-s"; fi` # that sometimes fix some problem on the boot also i put kernel64patcherA because that fix the problem on the kerneldiff on kernel of iphone 7
        "$dir"/kerneldiff work/kcache.raw work/kcache.patched work/kc.bpatch
        "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o work/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [ "$os" = 'Linux' ]; then echo "-J"; fi`

        "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/DeviceTree[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" -o work/dtree.raw
        if [ "$os" = "Linux" ]; then
            echo "devicetree patcher is fall down, not work on linux, however you can use https://github.com/darlinghq/darling.git to execute binary dtree_patcher"
            # that will use darling because dtreepatcher have problem on linux and noone want to help me 
            /usr/bin/darling shell binaries/Darwin/dtree_patcher work/dtree.raw work/dtree.patched -d -p
            "$dir"/img4 -i work/dtree.patched -o work/devicetree.img4 -A -M work/IM4M -T rdtr
        else 
            "$dir"/dtree_patcher work/dtree.raw work/dtree.patched -d -p
            "$dir"/img4 -i work/dtree.patched -o work/devicetree.img4 -A -M work/IM4M -T rdtr
        fi

        cp -rv work/*.img4 "boot/${deviceid}" # copying all file img4 to boot
      # echo "so we finish, now you can execute './dualboot boot' to boot to second ios after that we need that you record a video when your iphone is booting to see what is the uuid and note that name of the uuid"       
        _boot
    fi
fi

} 2>&1 | tee logs/${log}
