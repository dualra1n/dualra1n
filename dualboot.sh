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
os=$(uname)
dir="$(pwd)/binaries/$os"
max_args=1
arg_count=0
disk=8
extractedIpsw="ipsw/extracted/"

if [ ! -d "ramdisk/" ]; then
    echo "[*] Please wait patiently; it is currently cloning the ramdisk..."
    git clone https://github.com/dualra1n/ramdisk.git
fi

# =========
# Functions
# =========
remote_cmd() {
    sleep 1
    "$dir"/sshpass -p 'alpine' ssh -ostricthostkeychecking=false -ouserknownhostsfile=/dev/null -o StrictHostKeyChecking=no -q -p2222 root@localhost "$@"
    sleep 1
}

remote_cp() {
    sleep 1
    "$dir"/sshpass -p 'alpine' scp -q -r -ostricthostkeychecking=false -ouserknownhostsfile=/dev/null -o StrictHostKeyChecking=no -P2222 "$@"
    sleep 1
}


step() {
    rm -f .entered_dfu
    for i in $(seq "$1" -1 0); do
        if [[ -e .entered_dfu ]]; then
            rm -f .entered_dfu
            break
        fi
        if [[ $(get_device_mode) == "dfu" || ($1 == "10" && $(get_device_mode) != "none") ]]; then
            touch .entered_dfu
        fi &
        printf '\r\e[K\e[1;36m%s (%d)' "$2" "$i"
        sleep 1
    done
    printf '\e[0m\n'
}

print_help() {
    cat << EOF
Usage: $0 [options] [ subcommand | iOS version that you're on ]
You must have around 15 GB of free storage, and the .iPSW file of the iOS which you wish to dualboot to in dualra1n/ipsw/.
Currently, only iOS 14 and 15 are supported. Downgrading from or upgrading to iOS 16 is not and will likely never be supported.

Options:
    --dualboot              Dualboot your iDevice.
    --jail-palera1n         Use this when you are already jailbroken with semi-tethered palera1n to avoid disk errors. 
    --jailbreak             Jailbreak dualbooted iOS with Pogo. Usage :  ./dualboot.sh --jailbreak 14.3
    --taurine               Jailbreak dualbooted iOS with Taurine. (currently ***NOT RECOMMENDED***). Usage: ./dualboot.sh --jailbreak 14.3 --taurine 
    --help                  Print this help.
    --dfuhelper             A helper to help you enter DFU if you are struggling to do it manually.
    --boot                 Boots your iDevice into the dualbooted iOS. Use this when you already have the dualbooted iOS installed. Usage : ./dualboot.sh --boot
    --dont-create-part      Skips creating a new disk partition if you have them already, so using this this downloads the boot files. Usage : ./dualboot.sh --dualboot 14.3 --dont-create-part.
    --bootx                 this option will force to this script create and boot as bootx proccess.
    --restorerootfs         Deletes the dualbooted iOS. (also add --jail-palera1n if you are jailbroken semi-tethered with palera1n)
    --recoveryModeAlways    Fixes the main iOS when it is recovery looping.
    --debug                 Makes the script significantly more verbose. (meaning it will output exactly what command it is running)
Subcommands:
    clean                   clean everything for a new dualboot.

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
        --recoveryModeAlways)
            recoveryModeAlways=1
            ;;
        --fixHard)
            fixHard=1
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
        --bootx)
            bootx=1
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
        "$dir"/gaster reset >/dev/null
}

get_device_mode() {
    if [ "$os" = "Darwin" ]; then
        sp="$(system_profiler SPUSBDataType 2> /dev/null)"
        apples="$(printf '%s' "$sp" | grep -B1 'Vendor ID: 0x05ac' | grep 'Product ID:' | cut -dx -f2 | cut -d' ' -f1 | tail -r)"
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
        usbserials=$(printf '%s' "$sp" | grep 'Serial Number' | cut -d: -f2- | sed 's/ //')
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
    if [ "$(get_device_mode)" = "dfu" ]; then
        echo "[*] Device already on dfu mode"
        return;
    fi

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
        echo "[-] Device did not enter DFU mode, try again"
       _detect
       _dfuhelper
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

_detect() {
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
            sudo "$dir"/iproxy 2222 22 >/dev/null &
        else
            "$dir"/iproxy 2222 22 >/dev/null &
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
            echo "[-] dualboot doesn't, and never will, work on non-checkm8 devices"
            exit
        fi
        echo "Hello, $(_info normal ProductType) on $version!"

        echo "[*] Switching device into recovery mode..."
        "$dir"/ideviceenterrecovery $(_info normal UniqueDeviceID)
        _wait recovery
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

    if [[ ! "$cpid" == *"0x801"* ]]; then
        "$dir"/irecovery -f "boot/${deviceid}/iBSS.img4"
        sleep 4
    fi

    "$dir"/irecovery -f "boot/${deviceid}/iBEC.img4"
    echo "[*] the device should show some line of words, it means that it is booting, if it doesn't finish booting, doesn't show apple logo or it enter recoverymode please try --boot again, if it is still please report this issue in my discord server."
    exit;
}

_bootx() {
    _pwn
    sleep 1
    _reset
    sleep 1
    
    echo "[*] Booting device"

    "$dir"/irecovery -f "blobs/"$deviceid"-"$version".der"
    sleep 1

    if [[ ! "$cpid" == *"0x801"* ]]; then
        "$dir"/irecovery -f "boot/${deviceid}/iBSS.img4"
        sleep 1
    fi
    
    "$dir"/irecovery -f "boot/${deviceid}/iBEC.img4"
    sleep 2
    
    if [[ "$cpid" == *"0x801"* ]]; then
        "$dir"/irecovery -c "go"
        sleep 3
    else
       "$dir"/irecovery -c "bootx"
        sleep 1
    
    fi


    "$dir"/irecovery -f "boot/${deviceid}/devicetree.img4"
    sleep 1 

    "$dir"/irecovery -c "devicetree"
    sleep 1

    "$dir"/irecovery -f "boot/${deviceid}/trustcache.img4"    

    "$dir"/irecovery -c "firmware"
    sleep 1

    "$dir"/irecovery -f "boot/${deviceid}/kernelcache.img4"
    sleep 1

    "$dir"/irecovery -c "bootx"
    exit;
}

_exit_handler() {
    if [ "$os" = "Darwin" ]; then
        killall -CONT AMPDevicesAgent AMPDeviceDiscoveryAgent MobileDeviceUpdater || true
    fi

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

# ============
# Dependencies
# ============
if [ "$os" = "Linux"  ]; then
    chmod +x getSSHOnLinux.sh
    sudo bash ./getSSHOnLinux.sh &
fi

if [ "$os" = 'Linux' ]; then
    linux_cmds='lsusb'
fi

for cmd in unzip python3 git ssh scp killall sudo grep pgrep ${linux_cmds}; do
    if ! command -v "${cmd}" > /dev/null; then
        echo "[-] Command '${cmd}' not installed, please install it!";
        cmd_not_found=1
    fi
done
if [ "$cmd_not_found" = "1" ]; then
    exit 1
fi

# Check for pyimg4
packages=("pyimg4")
for package in "${packages[@]}"; do
    if ! python3 -c "import pkgutil; exit(not pkgutil.find_loader('$package'))"; then
        echo "[-] $package not installed. Press any key to install it, or press ctrl + c to cancel"
        read -n 1 -s
        python3 -m pip install -U "$package"
    fi
done

# Update submodules
#git submodule update --init --recursive 
#git submodule foreach git pull origin main

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

echo "dualboot | Version: 8.0"
echo "Created by edwin :) | Some code of palera1n, thanks Nathan because the ramdisks | thanks MatthewPierson, Ralph0045, and all people creator of path file boot"
echo ""

parse_cmdline "$@"

if [ "$debug" = "1" ]; then
    set -o xtrace
fi

if [ "$clean" = "1" ]; then
    rm -rf  work/* blobs/* boot/"$deviceid"/  ipsw/extracted ipsw/out.dmg
    echo "[*] Removed the created boot files"
    exit
fi

if [[ -z "$version" ]]; then
    echo "[-] ERROR, YOU DIDN'T SPECIFY THE VERSION WHICH YOU WANT TO DUALBOOT. PLEASE ADD THE VERSION, FOR EXAMPLE: ./dualboot.sh --dualboot 14.3"
fi

if [[ "$version" = "13."* ]]; then
    echo -e "YOU CAN'T DUALBOOT IOS 13.6-13.7 USING THIS BRANCH YET. USE THIS COMMAND TO CHAMGE to THE ios13 BRANCH: \033[0;37mgit checkout ios13\033[0m"
    exit
fi

_detect

# Grab more info
echo "[*] Getting device info..."
cpid=$(_info recovery CPID)
model=$(_info recovery MODEL)
deviceid=$(_info recovery PRODUCT)

echo "Detected cpid, your cpid is $cpid"
echo "Detected model, your model is $model"
echo "Detected deviceid, your deviceid is $deviceid"

if [ "$dfuhelper" = "1" ]; then
    echo "[*] Running DFU helper"
    _dfuhelper "$cpid"
    exit
fi

ipswurl=$(curl -sL "https://api.ipsw.me/v4/device/$deviceid?type=ipsw" | "$dir"/jq '.firmwares | .[] | select(.version=="'$version'")' | "$dir"/jq -s '.[0] | .url' --raw-output)

if [ "$recoveryModeAlways" = "1" ]; then
    "$dir"/irecovery -n 
    echo "DONE"
    exit;
fi

if [ "$restorerootfs" = "1" ]; then
    rm -rf "blobs/"$deviceid"-"$version".der" "boot/$deviceid" 
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
    if [ ! -e boot/"$deviceid"/iBEC.img4 ]; then
        echo "[-] you don't have the boot files created, Please try to dualboot or if you are already dualbooted try to --dualboot (VERS) --dont-create-part that's will create only the boot files."
        exit;
    fi
    if [ -e boot/"$deviceid"/kernelcache.img4 ] || [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then
        echo "[*] seems like you have bootx boot files dualboot, so we are gonna use bootx boot process"
        _bootx
    else
        echo "[*] so we are going to use localboot boot process"
        _boot    
    fi
    
fi

    # =========
    # extract ipsw 
    # =========
cd ipsw/
ipsw_files=(*.ipsw)
if [[ ${#ipsw_files[@]} -gt 1 ]]; then
    echo "in ipsw/ directory there is more than one ipsw so delete one and try again please"
    cd ..
    exit;
fi
cd ..

if [ "$dualboot" = "1" ] || [ "$jailbreak" = "1" ]; then
    # extracting ipsw
    echo "extracting ipsw, hang on please ..." # this will extract the ipsw into ipsw/extracted
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
        sudo "$dir"/iproxy 2222 22 >/dev/null &
    else
        "$dir"/iproxy 2222 22 >/dev/null &
    fi

    if ! ("$dir"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "echo connected" &> /dev/null); then
        echo "[*] Waiting for the ramdisk to finish booting"
    fi

    i=1
    while ! ("$dir"/sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -p2222 root@localhost "echo connected" &> /dev/null); do
        sleep 1
        i=$((i+1))
        if [ "$i" == 15 ]; then
            if [ "$os" = 'Linux' ]; then
                echo -e "as a sudo user or your user, you should execute in another terminal:  \e[1;37mssh-keygen -f /root/.ssh/known_hosts -R \"[localhost]:2222\"\e[0m"
                read -p "Press [ENTER] to continue"
            else
                echo "mmm that looks like that ssh it's not working try to reboot your computer or send the log file trough discord"
                read -p "Press [ENTER] to continue"
            fi
        fi
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

    # that is in order to know the partitions needed
    if [ "$jail_palera1n" = "1" ]; then
        disk=$(($disk + 1)) # if you have the palera1n jailbreak that will create + 1 partition for example your jailbreak is installed on disk0s1s8 that will create a new partition on disk0s1s9 so only you have to use it if you have palera1n
    fi
    dataB=$(($disk + 1))
    prebootB=$(($dataB + 1))
    echo "the root partition will be: $disk"
    echo "the data partition will be: $dataB"
    echo "the preboot partition will be: $prebootB"

    remote_cmd "/usr/bin/mount_filesystems >/dev/null 2>&1"

    has_active=$(remote_cmd "ls /mnt6/active" 2> /dev/null)
    if [ ! "$has_active" = "/mnt6/active" ]; then
        echo "[!] Active file does not exist! Please use SSH to create it"
        echo "    /mnt6/active should contain the name of the UUID in /mnt6"
        echo "    When done, type reboot in the SSH session, then rerun the script"
        echo "    ssh root@localhost -p 2222"
        exit
    fi
    active=$(remote_cmd "cat /mnt6/active" 2> /dev/null)
    
    mkdir -p "boot/${deviceid}"

    if [ "$restorerootfs" = "1" ]; then
        echo "[*] Removing some boot images file cache in the preboot"
        if [ ! $(remote_cmd "rm /mnt6/"$active"/System/Library/Caches/com.apple.kernelcaches/kernelcachd /mnt6/"$active"/usr/standalone/firmware/root_hasd.img4 /mnt6/"$active"/usr/standalone/firmware/devicetred.img4 /mnt6/"$active"/usr/standalone/firmware/FUD/StaticTrustCachd.img4") ];  then
            echo "[-] There is not boot images, Omitting ..."
        fi

        echo "[*] Removing dualboot partitions"
        
        partition_type="$(remote_cmd "/System/Library/Filesystems/apfs.fs/apfs.util -p /dev/disk0s1s${disk}")"
        if [ ! "$partition_type" == 'SystemB' ]; then
            # Print an error message and prompt the user to continue or exit
            echo "Error: Partition may be important and could be deleted by apfs_deletefs."
            read -p "Press [ENTER] to continue, or [CTRL]+[C] to exit."
        fi

        # this eliminate dualboot paritions 
        remote_cmd "/sbin/apfs_deletefs disk0s1s${disk} > /dev/null || true"
        remote_cmd "/sbin/apfs_deletefs disk0s1s${dataB} > /dev/null || true"
        remote_cmd "/sbin/apfs_deletefs disk0s1s${prebootB} > /dev/null || true"
        echo "[*] the dualboot was removed"
        echo "[*] Checking if there is more partition and removing them"
        i=$(($prebootB + 1))

        while [ "$(remote_cmd "ls /dev/disk0s1s$i 2>/dev/null")" ]; do
            echo "Found /dev/disk0s1s$i deleting ..."
            cmd="/sbin/apfs_deletefs disk0s1s$i &>/dev/null || true"
            remote_cmd "$cmd"
            i=$((i + 1))
        done
        
        remote_cmd "/usr/sbin/nvram auto-boot=true"
        echo "[*] the dualboot was sucessfully removed, now Rebooting your device"
        remote_cmd "/sbin/reboot"
        exit;
    fi

    remote_cp root@localhost:/mnt6/"$active"/System/Library/Caches/apticket.der blobs/"$deviceid"-"$version".der
    cp -av blobs/"$deviceid"-"$version".der work/IM4M

    if [ "$jailbreak" = "1" ]; then
    
        if [ ! -f boot/"${deviceid}"/iBEC.img4 ]; then
            echo "you don't have the boot files created, if you are doing this before dualboot please first dualboot and when you get the first boot try to jailbreak "
            exit;
        fi

        echo "patching kernel" # this will send and patch the kernel
        cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/kernelcache"
                
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
        remote_cp binaries/Kernel15Patcher.ios root@localhost:/mnt8/private/var/root/kpf15.ios
        remote_cmd "/usr/sbin/chown 0 /mnt8/private/var/root/kpf15.ios"
        remote_cmd "/bin/chmod 755 /mnt8/private/var/root/kpf15.ios"
        sleep 1
        if [ ! $(remote_cmd "/mnt8/private/var/root/kpf15.ios /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched 2>/dev/null") ]; then
            echo "you have the kernelpath already installed "
        fi
        sleep 2
        remote_cp root@localhost:/mnt4/"$active"/System/Library/Caches/com.apple.kernelcaches/kcache.patched work/ # that will return the kernelpatcher in order to be patched again and boot with it 
        "$dir"/Kernel64Patcher work/kcache.patched work/kcache.patchedB -e -o $(if [[ "$version" = "15."* ]]; then echo "-b15 -r"; else echo "-b"; fi) $(if [ ! "$taurine" = "1" ]; then echo "-l"; fi) 2>/dev/null

        if [[ "$deviceid" == *'iPhone8'* ]] || [[ "$deviceid" == *'iPad6'* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/kcache.im4p -f $(if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then echo "rkrn"; else echo "krnl"; fi)  --extra work/kpp.bin --lzss 2>/dev/null
        else
            python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/kcache.im4p -f $(if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then echo "rkrn"; else echo "krnl"; fi)  --lzss 2>/dev/null
        fi
        
        python3 -m pyimg4 img4 create -p work/kcache.im4p -o $(if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then echo "work/kernelcache.img4"; else echo "work/kernelcachd"; fi) -m work/IM4M 2>/dev/null
        
        if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then
            cp -rv "work/kernelcache.img4" "boot/${deviceid}"
        fi

        remote_cp work/kernelcachd root@localhost:/mnt6/"$active"/System/Library/Caches/com.apple.kernelcaches/kernelcachd
        remote_cmd "rm -f /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched"
        
        #"$dir"/kerneldiff work/kcache.raw work/kcache.patchedB work/kc.bpatch
        #"$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o work/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [ "$os" = 'Linux' ]; then echo "-J"; fi`
        #remote_cp root@localhost:/mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kernelcachd work/kernelcache.img4
        echo "[*] Copied suscessfully the new kernelcache"
        
        echo "[*] Installing trollstore on TV"
        remote_cmd "/bin/mkdir -p /mnt8/Applications/dualra1n-loader.app && /bin/mkdir -p /mnt8/Applications/trollstore.app" # thank opa you are a tiger xd 
        echo "[*] copying dualra1n-loader.app so hang on please ..."

	
        if [ ! $(remote_cmd "trollstoreinstaller TV") ]; then
            echo "[/] you have to install trollstore in order to intall taurine"
        fi

        if [ "$taurine" = 1 ]; then
            echo "installing taurine"
            remote_cp other/taurine/* root@localhost:/mnt8/
            echo "[*] Taurine installed"
            remote_cp other/dualra1n-loader.app root@localhost:/mnt8/Applications/
            echo "[*] it is copying so hang on please "
            remote_cmd "chmod +x /mnt8/Applications/dualra1n-loader.app/dual* && /usr/sbin/chown 33 /mnt8/Applications/dualra1n-loader.app/dualra1n-loader && /bin/chmod 755 /mnt8/Applications/dualra1n-loader.app/dualra1n-helper && /usr/sbin/chown 0 /mnt8/Applications/dualra1n-loader.app/dualra1n-helper" 
            echo "[*] REBOOTING ..."
            remote_cmd "/sbin/reboot"
            exit;
        fi

        remote_cp other/dualra1n-loader.app root@localhost:/mnt8/Applications/
        echo "[*] it is copying so hang on please "
        remote_cmd "chmod +x /mnt8/Applications/dualra1n-loader.app/dual* && /usr/sbin/chown 33 /mnt8/Applications/dualra1n-loader.app/dualra1n-loader && /bin/chmod 755 /mnt8/Applications/dualra1n-loader.app/dualra1n-helper && /usr/sbin/chown 0 /mnt8/Applications/dualra1n-loader.app/dualra1n-helper" 



        echo "[*] Installing JBINIT, thanks palera1n team"
        echo "[*] Copying files to rootfs"
        sleep 1
        remote_cmd "mkdir -p /mnt8/jbin/binpack /mnt8/jbin/loader.app"
        sleep 1

        # this is the jailbreak of palera1n being installing 
        
        cp -v other/post.sh other/rootfs/jbin/
        remote_cp -r other/rootfs/* root@localhost:/mnt8/
        remote_cmd "ldid -s /mnt8/jbin/launchd /mnt8/jbin/jbloader /mnt8/jbin/jb.dylib"
        remote_cmd "chmod +rwx /mnt8/jbin/launchd /mnt8/jbin/jbloader /mnt8/jbin/post.sh"
        echo "[*] Extracting the binpack"
        remote_cmd "tar -xf /mnt8/jbin/binpack/binpack.tar -C /mnt8/jbin/binpack/"
        sleep 1
        remote_cmd "rm /mnt8/jbin/binpack/binpack.tar"
        remote_cmd "/usr/sbin/nvram auto-boot=true"
        echo "[*] DONE ... now reboot and boot again"        
        remote_cmd "/sbin/reboot"
        exit;
    fi
    

    if [ "$dualboot" = "1" ]; then
        if [ -z "$dont_createPart" ]; then # if you have already your second ios you can omited with this
            echo "[*] Starting step 1"
            echo "[*] Verifying if we can continue with the dualboot"

            if [ "$(remote_cmd "ls /dev/disk0s1s${disk} 2>/dev/null")" ]; then
                if [ "$(remote_cmd "/System/Library/Filesystems/apfs.fs/apfs.util -p /dev/disk0s1s${disk}")" == 'Xystem' ]; then
                    echo "that look like you have the palera1n semitethered jailbreak, always add the command --jail-palera1n in order to fix it "
                    exit;
                else
                    echo "you have a system installed on the partition that will be used by this, so ctrl+c and try to restorerootfs or ignore this by pressing [enter]. (probably dualboot wont boot into the second ios if you dont --restorerootfs before this)."
                    read -p "click enter if you want to continue"
                fi
            else
                echo "[*] Sucessfull verified"
            fi

            echo "[*] Creating partitions"

        	if [ ! $(remote_cmd "/sbin/newfs_apfs -o role=n -A -v SystemB /dev/disk0s1") ] && [ ! $(remote_cmd "/sbin/newfs_apfs -o role=0 -A -v DataB /dev/disk0s1") ] && [ ! $(remote_cmd "/sbin/newfs_apfs -o role=D -A -v PrebootB /dev/disk0s1") ]; then # i put this in case that resturn a error the script can continuing
                echo "[*] partitions created, continuing..."
	        fi
		    
            echo "[*] partitions are already created"
            echo "[*] mounting filesystems "
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${disk} /mnt8/"
            sleep 1
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${dataB} /mnt9/" # this mount partitions which are needed by dualboot
            sleep 1
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${prebootB} /mnt4/"
            sleep 1
            
            if [ ! $(remote_cmd "cp -a /mnt2/keybags /mnt9/") ]; then # this are keybags without this the system wont work 
                echo "[*] copied keybags"
            fi
             

            if command -v rsync &>/dev/null; then
                echo "[*] rsync installed"
            else 
                echo "[-] you dont have rsync installed so the script will take much more time to copy the rootfs file, so install rsync in order to be faster."
            fi
            
            echo "[*] copying rootfs filesystem so hang on, that could take 20 minute because is trought ssh"
            if [ "$os" = "Darwin" ]; then
                if [ ! $("$dir"/sshpass -p 'alpine' rsync -rvz -e 'ssh -p 2222' ipsw/out.dmg root@localhost:/mnt8 2>/dev/null) ]; then
                    remote_cp ipsw/out.dmg root@localhost:/mnt8 >/dev/null 2>&1 # this will copy the root file in order to it is mounted and restore partition      
                fi
            else 
                if [ ! $("$dir"/sshpass -p 'alpine' rsync -rvz -e 'ssh -p 2222' "$extractedIpsw$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')" root@localhost:/mnt8 2>/dev/null) ]; then
                    remote_cp "$extractedIpsw$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')" root@localhost:/mnt8 >/dev/null 2>&1
                fi
                # on linux this will be different because asr. this just mount the rootfs and copying all files to partition 
                sleep 2
                dmg_disk=$(remote_cmd "/usr/sbin/hdik /mnt8/${dmgfile} | head -3 | tail -1 | sed 's/ .*//'")
                remote_cmd "/sbin/mount_apfs -o ro $dmg_disk /mnt5/"
                echo "[*] it is extracting the files so please hang on ......."
                remote_cmd "cp -na /mnt5/* /mnt8/"
                sleep 2
                remote_cmd "/sbin/umount $dmg_disk"
                remote_cmd "rm -rv /mnt8/${dmgfile}"
  		sleep 3
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

        # checking if we have acess to our partitions 
  	    if [ $(remote_cmd "ls /dev/disk0s1s8") ]; then
            echo "[*] Found disk0s1s$disk"
        else
            echo "[-] Error: It couldn't detect disk0s1s$disk, so now you'll need to wait until the device reboots and boots into your main iOS. After that, put your device in recovery mode."
            remote_cmd "/usr/sbin/nvram auto-boot=true"
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

            echo "[*] Checking if we can acess to disk0s1s$disk"

            if [ $(remote_cmd "ls /dev/disk0s1s8") ]; then
                echo "[*] Detected continuing ..."
            else
                echo "[-] Error: we can't acess to the root partition, so please --restorerootfs and report this error to my discord server"
                remote_cmd "/usr/sbin/nvram auto-boot=true"
                remote_cmd "/sbin/reboot"
                exit;
            fi

        fi

	    echo "[*] Trying to mount the partitions"
     
            if [ "$os" = "Darwin" ]; then
                remote_cmd "/System/Library/Filesystems/apfs.fs/apfs_invert -d /dev/disk0s1 -s ${disk} -n out.dmg" # this will mount the root file system and would restore the partition 
            fi

            sleep 2
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${disk} /mnt8/"
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${dataB} /mnt9/"
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${prebootB} /mnt4/"
            
            echo "[*] Copying var ..."
            if [ ! $(remote_cmd "cp -a /mnt8/private/var/. /mnt9/.") ]; then # this will copy all file which is needed by dataB
                echo "var was copied"
            fi
            sleep 2
            
            remote_cmd "/usr/bin/mount_filesystems >/dev/null 2>&1"
            echo "[*] Copying preboot ..."
            remote_cmd "cp -na /mnt6/* /mnt4/" # copy preboot to prebootB
            sleep 1
            remote_cmd "rm /mnt4/$active/usr/standalone/firmware/FUD/*"

            if [ $(remote_cmd "cp -a /mnt2/mobile/Library/Preferences/com.apple.Accessibility* /mnt9/mobile/Library/Preferences/") ]; then # this will copy the assesivetouch config to our data partition
                echo "[*] activating assesivetouch"
            fi

            echo "[*] installing trollstore"
            remote_cmd "/bin/mkdir -p /mnt8/Applications/trollstore.app"
            remote_cp other/trollstore.app root@localhost:/mnt8/Applications/
            sleep 4
            
            echo "[*] Saving snapshot"
            if [ "$(remote_cmd "/usr/bin/snaputil -c orig-fs /mnt8")" ]; then
                echo "[-] error saving snapshot, SKIPPING ..."
            fi

            echo "[*] Adding the kernel to preboot"
            "$dir"/img4 -i "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o work/kernelcache -M work/IM4M -T krnl
            remote_cp work/kernelcache root@localhost:/mnt4/"$active"/System/Library/Caches/com.apple.kernelcaches/kernelcache
            echo "[*] Step 1 is complete. You can use the --dont-create-part option to avoid copying and creating partitions, along with redoing any necessary configurations if needed."
        fi
        
        echo "[*] Starting step 2"
        echo "[*] Fixing firmwares"
        fixHard=1

        if [ "$dont_createPart" = "1" ]; then
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${disk} /mnt8/" 
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${prebootB} /mnt4/"
            sleep 1
        fi
        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/AOP.img4 2>/dev/null")" ]; then
            echo "AOP FOUND"
            cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/aop/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/aop/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]AOP[/]//')" -o work/AOP.img4 -M work/IM4M
        fi
        
        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/StaticTrustCache.img4 2>/dev/null")" ]; then
            echo "StaticTrustCache FOUND"
            if [ "$os" = 'Darwin' ]; then
                "$dir"/img4 -i "$extractedIpsw"/Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache -o work/StaticTrustCache.img4 -M work/IM4M -T trst
            else
                "$dir"/img4 -i "$extractedIpsw"/Firmware/"$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')".trustcache -o work/StaticTrustCache.img4 -M work/IM4M -T trst
            fi
        fi
        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/Homer.img4 2>/dev/null")" ]; then
            echo "Homer FOUND"
            cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/homer/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/homer/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]//')" -o work/Homer.img4 -M work/IM4M
        fi
        
        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/Multitouch.img4 2>/dev/null")" ]; then
            echo "Multitouch FOUND"
            cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/_Multitouch[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/_Multitouch[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]//')" -o work/Multitouch.img4 -M work/IM4M
        fi
        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/AVE.img4 2>/dev/null")" ]; then
            echo "AVE FOUND"
            remote_cmd "cp /mnt6/$active/usr/standalone/firmware/FUD/AVE.img4" "/mnt4/$active/usr/standalone/firmware/FUD/"
        fi
        
        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/AudioCodecFirmware.img4 2>/dev/null")" ]; then
            echo "AudioCodecFirmware FOUND"
            cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/_CallanFirmware[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/_CallanFirmware[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]//')" -o work/AudioCodecFirmware.img4 -M work/IM4M
        fi
        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/ISP.img4 2>/dev/null")" ]; then
            echo "ISP FOUND"
            cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/adc/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/adc/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]isp_bni[/]//')" -o work/ISP.img4 -M work/IM4M
        fi

        if [ ! "$(remote_cp work/*.img4 root@localhost:/mnt4/"$active"/usr/standalone/firmware/FUD/ )" ]; then
            echo "uh"
        fi

        if [ "$(remote_cmd "ls /mnt4/$active/usr/standalone/firmware/FUD/*.img4 2>/dev/null")" ]; then
            echo "[*] Fixed firmware suscessfully"
            rm work/*.img4
        else
            echo "[-] error fixing firmware, skipping ..."
            fixHard=0
        fi

        if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then
            echo "IOS 13 dualboot or bootx option detected, we are gonna use bootx boot process" # bootx is the boot process which is normaly used when we want to boot a ramdisk to restore. we can't use localboot on ios 13.
        else
            echo "IOS 14 or 15 dualboot detected, we are gonna use localboot boot process" # localboot is the boot process that normaly is used when you power on your iphone, it means that can be more stable
        fi
        
        echo "[*] Adding new boot images: kernelcache, root_hash, StaticTrustCache, devicetree... "
        if [ "$fixBoot" = "1" ]; then # i put it because my friend tested on his ipad and that does not boot so when we download all file from the internet so not extracting ipsw that boot fine idk why 
            cd work
            #that will download the files needed
            sleep 1
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/iBSS[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/DeviceTree[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
            
            if [ "$os" = 'Darwin' ]; then
                "$dir"/pzb -g Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".root_hash "$ipswurl"
            else
                "$dir"/pzb -g Firmware/"$(../binaries/Linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')".root_hash "$ipswurl"
            fi
            
            if [ "$os" = 'Darwin' ]; then
                "$dir"/pzb -g Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache "$ipswurl"
            else
                "$dir"/pzb -g Firmware/"$(../binaries/Linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')".trustcache "$ipswurl"
            fi
            
            cd ..
        else
            #that will extract the files needed from ipsw
            cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/iBSS[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/DeviceTree[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            
            if [ "$os" = 'Darwin' ]; then
                cp "$extractedIpsw"/Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".root_hash work/
            else
                cp "$extractedIpsw"/Firmware/"$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')".root_hash work/
            fi

            if [ "$os" = 'Darwin' ]; then
                cp "$extractedIpsw"/Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache work/
            else
                cp "$extractedIpsw"/Firmware/"$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')".trustcache work/
            fi
        fi

        echo "[*] Copying the new boot images to work with"
        cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/kernelcache"
        "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/DeviceTree[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" -o work/dtree.raw

        echo "[*] Patching kernel ..." # this will patch the kernel        
        if [[ "$deviceid" == "iPhone8"* ]] || [[ "$deviceid" == "iPad6"* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw --extra work/kpp.bin >/dev/null
        else
            python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw >/dev/null
        fi

        echo "[*] Checking if a jailbreak is installed"
        
        if [ "$dont_createPart" = "1" ] && [ $(remote_cmd "ls /mnt8/jbin/jbloader 2>/dev/null") ] || [ $(remote_cmd "ls /mnt8/.installed_odyssey 2>/dev/null") ] || [ $(remote_cmd "ls /mnt8/.installed_taurine 2>/dev/null") ]; then
            echo "[*] Jailbreak detected"
            remote_cmd "mkdir -p /mnt8/private/var/root/work"
            remote_cp work/kcache.raw root@localhost:/mnt4/"$active"/System/Library/Caches/com.apple.kernelcaches/kcache.raw
            remote_cp binaries/Kernel15Patcher.ios root@localhost:/mnt8/private/var/root/work/kpf15.ios
            remote_cmd "/usr/sbin/chown 0 /mnt8/private/var/root/work/kpf15.ios"
            remote_cmd "/bin/chmod 755 /mnt8/private/var/root/work/kpf15.ios"
            sleep 1

            if [ ! "$(remote_cmd "/mnt8/private/var/root/work/kpf15.ios /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched 2>/dev/null")" ]; then
                echo "[-] you have the kernelpath already installed, Omitting ..."
            fi
            remote_cp root@localhost:/mnt4/"$active"/System/Library/Caches/com.apple.kernelcaches/kcache.patched work/ # that will return the kernelpatcher in order to be patched again and boot with it 
            remote_cmd "rm -r /mnt8/private/var/root/work"
            "$dir"/Kernel64Patcher work/kcache.patched work/kcache.patchedB $(if [[ "$version" = "15."* ]]; then echo "-e -o -r -b15"; fi) $(if [[ "$version" = "14."* ]]; then echo "-b"; fi) `if [ "$fixHard" = "0" ]; then echo "-f"; fi` `if [ $(remote_cmd "ls /mnt8/jbin/jbloader") ]; then echo "-l"; fi` >/dev/null
        else
            "$dir"/Kernel64Patcher work/kcache.raw work/kcache.patchedB $(if [[ "$version" = "15."* ]]; then echo "-e -o -r -b15"; fi) $(if [[ "$version" = "14."* ]]; then echo "-b"; fi) `if [ "$fixHard" = "0" ]; then echo "-f"; fi` >/dev/null
        fi

        # on ios 15 we can't use root_hash from another ios version idk why, so we need to use bootx.
        
        if [[ "$deviceid" == *'iPhone8'* ]] || [[ "$deviceid" == *'iPad6'* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/kcache.im4p -f $(if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then echo "rkrn"; else echo "krnl"; fi) --extra work/kpp.bin --lzss >/dev/null
        else
            python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/kcache.im4p -f $(if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then echo "rkrn"; else echo "krnl"; fi) --lzss >/dev/null
        fi
        
        python3 -m pyimg4 img4 create -p work/kcache.im4p -o $(if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then echo "work/kernelcache.img4"; else echo "work/kernelcachd"; fi) -m work/IM4M >/dev/null
        
        
        echo "[*] Finished adding the kernel"

        if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then
            echo "Adding StaticTrustCache"

            "$dir"/img4 -i work/*.trustcache -o work/trustcache.img4 -M work/IM4M -T rtsc

            echo "Adding devicetree"
            sleep 1
            "$dir"/dtree_patcher work/dtree.raw work/dtree.patched -d -p >/dev/null
            "$dir"/img4 -i work/dtree.patched -o work/devicetree.img4 -A -M work/IM4M -T rdtr
        else
            echo "Adding StaticTrustCache"
            remote_cmd "cp -a /mnt4/$active/usr/standalone/firmware/FUD/StaticTrustCache.img4 /mnt6/$active/usr/standalone/firmware/FUD/StaticTrustCachd.img4"

            echo "Adding devicetree"

            sleep 1
            "$dir"/dtree_patcher work/dtree.raw work/dtree.patched -d -p >/dev/null
            "$dir"/img4 -i work/dtree.patched -o work/devicetred.img4 -A -M work/IM4M -T dtre >/dev/null


            echo "Adding root_hash"
            "$dir"/img4 -i work/*.root_hash -o work/root_hasd.img4 -M work/IM4M >/dev/null

            echo "[*] Sending boot images to device"
            remote_cp work/kernelcachd root@localhost:/mnt6/"$active"/System/Library/Caches/com.apple.kernelcaches/kernelcachd
            remote_cp work/devicetred.img4 work/root_hasd.img4 root@localhost:/mnt6/"$active"/usr/standalone/firmware
            
        fi
        
        echo "[*] FINISHED"
        echo "[*] Rebooting ..."
        remote_cmd "/usr/sbin/nvram auto-boot=false"
        remote_cmd "/sbin/reboot"
        _wait recovery
        sleep 4
        _dfuhelper "$cpid"
        sleep 3

        echo "[*] Patching file iBoot and ibss ..."

        "$dir"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBSS[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]dfu[/]//')" work/iBSS.dec
        "$dir"/iBoot64Patcher work/iBSS.dec work/iBSS.patched >/dev/null
        "$dir"/img4 -i work/iBSS.patched -o work/iBSS.img4 -M work/IM4M -A -T ibss

        "$dir"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" work/iBEC.dec

        
        "$dir"/iBoot64Patcher work/iBEC.dec work/iBEC.patched -b "-v wdt=-1 keepsyms=1 debug=0x2014e `if [ "$cpid" = '0x8960' ] || [ "$cpid" = '0x7000' ] || [ "$cpid" = '0x7001' ]; then echo "-restore"; fi`" -n $(if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then echo ""; else echo "-l"; fi) >/dev/null # `if [ ! $hb ]; then echo "rd=disk0s1s${disk}"; fi`
        # patching the string in the ibec in order to load different image
        echo "[*] Patching the string of images to load in the iboot..."
        if [ "$os" = 'Linux' ]; then
            sed -i 's/\/\kernelcache/\/\kernelcachd/g' work/iBEC.patched
            sed -i 's#\/usr\/standalone\/firmware\/devicetree.img4#\/usr\/standalone\/firmware\/devicetred.img4#g' work/iBEC.patched
            sed -i 's#\/usr\/standalone\/firmware\/FUD\/StaticTrustCache.img4#\/usr\/standalone\/firmware\/FUD\/StaticTrustCachd.img4#g' work/iBEC.patched
            if [[ ! "$version" = "15."* ]]; then
                sed -i 's#\/usr\/standalone\/firmware\/root_hash.img4#\/usr\/standalone\/firmware\/root_hasd.img4#g' work/iBEC.patched
            fi
        else
            LC_ALL=C sed -i.bak -e 's/\/\kernelcache/\/\kernelcachd/g' work/iBEC.patched
            LC_ALL=C sed -i.bak -e 's#\/usr\/standalone\/firmware\/devicetree.img4#\/usr\/standalone\/firmware\/devicetred.img4#g' work/iBEC.patched
            LC_ALL=C sed -i.bak -e 's#\/usr\/standalone\/firmware\/FUD\/StaticTrustCache.img4#\/usr\/standalone\/firmware\/FUD\/StaticTrustCachd.img4#g' work/iBEC.patched
            if [[ ! "$version" = "15."* ]]; then
                LC_ALL=C sed -i.bak -e 's#\/usr\/standalone\/firmware\/root_hash.img4#\/usr\/standalone\/firmware\/root_hasd.img4#g' work/iBEC.patched
            fi
        fi
        
        echo "[*] Appling path to the iboot"
        # this will path the iboot in order to use the custom partition
        "$dir"/kairos work/iBEC.patched work/iBEC.patchedB -d "$disk" >/dev/null

        if [[ "$cpid" == *"0x801"* ]]; then
            "$dir"/img4 -i work/iBEC.patchedB -o work/iBEC.img4 -M work/IM4M -A -T ibss
        else
            "$dir"/img4 -i work/iBEC.patchedB -o work/iBEC.img4 -M work/IM4M -A -T ibec
        fi
            

        cp -v work/*.img4 "boot/${deviceid}" # Copying all file img4 to boot
        echo "Finished step 2"
        #echo "so we finish, now you can execute './dualboot.sh --boot' to boot to second ios after that we need that you record a video when your iphone is booting to see what is the uuid and note that name of the uuid"       
        echo "Booting ..."

        if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then
            echo "IOS 13 or bootx option DETECTED, booting using bootx method"
            _bootx
        else
            echo "IOS 14,15 DETECTED, booting using localboot method"
            _boot
        fi
    fi
fi

} 2>&1 | tee logs/${log}
