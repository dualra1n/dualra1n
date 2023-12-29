#!/usr/bin/env bash


mkdir -p logs
mkdir -p boot
mkdir -p ipsw/extracted
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
os=$(uname)
dir="$(pwd)/binaries/$os"
max_args=2
arg_count=0
disk=8

if [ ! -d "ramdisk/" ]; then
    echo "[*] Please wait patiently; We are currently cloning the ramdisk..."
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
    --dualboot              Dualboot your iDevice with the version specified.
    --downgrade             Will do the same thing as dualbooting but before continuing it will remove the files for the main ios (Useful for 16gb devices).
    --jailbreak             Jailbreak dualbooted iOS with dualra1n-loader. Usage :  ./dualboot.sh --jailbreak 14.3

Subcommands:
    --jail-palera1n         Use this when you are already jailbroken with semi-tethered palera1n to avoid disk errors. 
    --taurine               Jailbreak dualbooted iOS with Taurine. (currently ***NOT RECOMMENDED***). Usage: ./dualboot.sh --jailbreak 14.3 --taurine 
    --help                  Print this help.
    --dfuhelper             A helper to help you enter DFU mode if you are struggling to do it manually.
    --boot                 Boots your iDevice into the dualbooted iOS. Use this when you already have the dualbooted iOS installed. Usage : ./dualboot.sh --boot
    --dont-create-part      Skips creating a new disk partition if you have them already, so using this will only download the boot files. Usage : ./dualboot.sh --dualboot 14.3 --dont-create-part.
    --bootx                 This option will force the script to create and boot as bootx proccess.
    --use-main-data         This option will tell the dualboot to use the main data partition so you will retain the data from the main iOS, uses when dualbooting and when you use --dont-create-part
    --restorerootfs         Deletes the dualbooted iOS. (also add --jail-palera1n if you are jailbroken semi-tethered with palera1n)
    --verbose               This option will tell the iphone to boot in verbose to show more info on the iPhones screen (Useful for extra debugging). Usage: ./dualboot.sh --dualboot 14.3 (also can be used with dontcreatepart arg)
    --recoveryModeAlways    Fixes the main iOS if it is recovery looping.
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
        --downgrade)
            downgrade=1
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
        --use-main-data)
            mainData=1
            ;;
        --restorerootfs)
            restorerootfs=1
            ;;
        --verbose)
            verbose=1
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
            if [[ "$arg" == *"ipsw"* ]]; then
                ipsw=$arg
            else
                parse_arg "$arg";
            fi
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
        echo "[-] Please attach only one device at a time" > /dev/tty
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
        echo "[*] Device already in dfu mode"
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
        echo "[*] Your device has entered DFU!"
    else
        echo "[-] Your device did not enter DFU mode, please try again!"
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
    echo "[*] Looking for devices"
    while [ "$(get_device_mode)" = "none" ]; do
        sleep 1;
    done
    echo $(echo "[*] Detected $(get_device_mode) mode device" | sed 's/dfu/DFU/')

    if grep -E 'pongo|checkra1n_stage2|diag' <<< "$(get_device_mode)"; then
        echo "[-] Detected device in a unsupported mode '$(get_device_mode)'"
        exit 1;
    fi

    if [ "$(get_device_mode)" != "normal" ] && [ -z "$version" ] && [ "$dfuhelper" != "1" ]; then
        echo "[-] You must put in what version you want your device to dualboot"
        exit
    fi

    if [ "$(get_device_mode)" = "ramdisk" ]; then
        # If a device is in ramdisk mode, perhaps iproxy is still running?
        _kill_if_running iproxy
        echo "[*] Rebooting device in SSH Ramdisk mode"
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
            echo "[-] dualboot will not, EVER work on non-checkm8 devices aka:A12+ devices"
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
    
    echo "[*] Booting device!"

    "$dir"/irecovery -f "blobs/"$deviceid"-"$version".der"
    sleep 1

    if [[ ! "$cpid" == *"0x801"* ]]; then
        "$dir"/irecovery -f "boot/${deviceid}/iBSS.img4"
        sleep 4
    fi

    "$dir"/irecovery -f "boot/${deviceid}/iBEC.img4"
    echo "[*] The device should now be showing alot of code on the screen, that means it is booting, if it gets stuck or reboots into recovery or doesn't show the apple logo please try --boot again, if it still does not boot after running --boot please report it to the dualra1n discord (link on the github). If this didnt exit on its own plase press 'ctrl-c' to exit"
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
    echo "[-] An error has occurred, Please try again!"

    if [ -d "logs" ]; then
        cd logs
        mv "$log" FAIL_${log}
        cd ..
    fi

    echo "[*] A failure log has been made. If you need to ask for help, please attach the latest log on the dualra1n discord or in issues"
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
        echo "[-] Command '${cmd}' is not installed, please install it!";
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
         echo "[-] $package is not installed. we can installl it for you, press any key to start installing $package, or press ctrl + c to cancel"
         read -n 1 -s
         python3 -m pip install -U "$package" pyliblzfse
     fi
 done
 # LZSS gets its own check
packages=("lzss")
 for package in "${packages[@]}"; do
     if ! python3 -c "import pkgutil; exit(not pkgutil.find_loader('$package'))"; then
         echo "[-] $package is not installed. we can installl it for you, press any key to start installing $package, or press ctrl + c to cancel"
         read -n 1 -s
         git clone https://github.com/yyogo/pylzss "$dir"/pylzss
         cd "$dir"/pylzss
         python3 "$dir"/pylzss/setup.py install
         rm -rf "$dir"/pylzss
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
echo "Created by edwin :) | Some code from palera1n.sh, Thanks Nathan for the ramdisks | thanks MatthewPierson, Ralph0045, and to all of the creaters of path file boot"
echo ""

parse_cmdline "$@"

if [ "$debug" = "1" ]; then
    set -o xtrace
fi

if [ "$clean" = "1" ]; then
    rm -rf  work/* blobs/* boot/"$deviceid"/  ipsw/extracted $extractedIpsw/out.dmg
    echo "[*] Removed the created boot files"
    exit
fi

if [[ -z "$version" ]]; then
    echo "[-] error you didnt specify which iOS version you wanted to dualboot. please add that to your command, example: ./dualboot.sh --dualboot 14.3"
fi

if [[ "$version" = "13."* ]] && [ "$jailbreak" = "1" ]; then
    echo "[/] you can't use the --jailbreak option on ios 13 because we automatically install a jailbreak on ios 13"
    exit;
fi

_detect

# Grab more info
echo "[*] Getting your device info..."
cpid=$(_info recovery CPID)
model=$(_info recovery MODEL)
deviceid=$(_info recovery PRODUCT)

echo "Detected cpid, your cpid is $cpid"
echo "Detected model, your model is $model"
echo "Detected deviceid, your deviceid is $deviceid"

if [ "$dfuhelper" = "1" ]; then
    echo "[*] Running the DFU helper tool"
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
        echo "[-] failed to enter DFU mode, please ctrl-c and run dualboot.sh again to try again"
        exit -1
    }
fi
sleep 2


if [ "$boot" = "1" ]; then # call boot in order to boot it
    if [ ! -e boot/"$deviceid"/iBEC.img4 ]; then
        echo "[-] you don't have any boot files created, Please try to dualboot or if you know you are already dualbooted try --dualboot (VERS) --dont-create-part this will create only the boot files."
        exit;
    fi
    if [ -e boot/"$deviceid"/kernelcache.img4 ] || [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then
        echo "[*] looks like you have bootx boot files for this dualboot, so we are going to use the bootx boot process"
        _bootx
    else
        echo "[*] we are going to use the localboot boot process"
        _boot    
    fi
    
fi

    # =========
    # extract ipsw 
    # =========
mkdir -p ipsw/extracted/$deviceid
mkdir -p ipsw/extracted/$deviceid/$version

extractedIpsw="ipsw/extracted/$deviceid/$version/"

if [[ "$ipsw" == *".ipsw" ]]; then
    echo "[*] Argument detected we are going to use the ipsw specified"
else
    ipsw=()
    for file in ipsw/*.ipsw; do
        ipsw+=("$file")
    done


    if [ ${#ipsw[@]} -eq 0 ]; then
        echo "[-] we could not find any .ipsw files in the ipsw folder, please place an ipsw in that folder for your device and the version you want to dualboot."
        exit;
    else
        for file in "${ipsw[@]}"; do
            if [[ "$file" = *"$version"* ]]; then
                while true
                do
                    echo "[-] we found $file, do you want to use this ipsw? please write, "yes" or "no""
                    read result
                    if [ "$result" = "yes" ]; then
                        echo "$file"
                        unset ipsw
                        ipsw=$file
                        break
                    elif [ "$result" = "no" ]; then
                        break
                    fi
                done
            fi
        done
    fi
fi

# Check if ipsw is an array
if [[ "$(declare -p ipsw)" =~ "declare -a" ]]; then
    while true
    do
        echo "Choose an IPSW by entering its number:"
        for i in "${!ipsw[@]}"; do
            echo "$((i+1)). ${ipsw[i]}"
        done
        read -p "Enter your choice: " choice

        if [[ ! "$choice" =~ ^[1-${#ipsw[@]}]$ ]]; then
            echo "Invalid IPSW number. Please enter a valid number."
        else
            echo "[*] We are gonna use ${ipsw[$choice-1]}"
            ipsw="${ipsw[$choice-1]}"
            break
        fi
    done
fi

unzip -o $ipsw BuildManifest.plist -d work/ >/dev/null

if [ "$dualboot" = "1" ] || [ "$downgrade" = "1" ] || [ "$jailbreak" = "1" ]; then
    echo "[*] Checking if the ipsw you placed is for your device"
    ipswDevicesid=()
    ipswVers=""
    ipswDevId=""
    counter=0

    while [ ! "$deviceid" = "$ipswDevId" ]
    do
        if [ "$os" = 'Darwin' ]; then
            ipswDevId=$(/usr/bin/plutil -extract "SupportedProductTypes.$counter" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
        else
            ipswDevId=$("$dir"/PlistBuddy work/BuildManifest.plist -c "Print SupportedProductTypes:$counter" | sed 's/"//g')
        fi

        ipswDevicesid[counter]=$ipswDevId

        if [ "$ipswDevId" = "" ]; then # this is to stop looking for more devices as it pass the limit and can't find deviceid
            break
        fi

        let "counter=counter+1"
    done
    
    
    if [ "$ipswDevId" = "" ]; then
        echo "[/] it looks like this ipsw file is not the type for your device, please check your ipsw and try again"
        
        for element in "${ipswDevicesid[@]}"; do
            echo "these are the ipsw's devices support: $element"
        done
        
        echo "and your device $deviceid is not in this list"
        read -p "are you sure you want to continue? click enter if you are sure ..."
    fi


    echo "[*] Checking the ipsw version"
    if [ "$os" = 'Darwin' ]; then
        ipswVers=$(/usr/bin/plutil -extract "ProductVersion" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)
    else
        ipswVers=$("$dir"/PlistBuddy work/BuildManifest.plist -c "Print ProductVersion" | sed 's/"//g')
    fi
    
    if [[ ! "$version" = "$ipswVers" ]]; then
        echo "ipsw version is $ipswVers, and you specify $version"
        read -p "incompatible ipsw version detected, click ENTER to continue or ctrl + c to exit"
    fi

    # extracting ipsw
    echo "extracting ipsw, please wait..." # this will extract the ipsw into ipsw/extracted
    unzip -n $ipsw -d $extractedIpsw

    if [ "$os" = 'Darwin' ]; then
        if [ ! -f "$extractedIpsw/out.dmg" ]; then # this would create a dmg file which can be mounted an restore a patition
            asr -source "$extractedIpsw$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" -target "$extractedIpsw/out.dmg" --embed -erase -noprompt --chunkchecksum --puppetstrings
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
    echo "[*] Creating the ramdisk"
    ./sshrd.sh 15.6

    echo "[*] Booting the ramdisk"
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
                echo -e "as a root user or your user, please execute this command in another terminal:  \e[1;37mssh-keygen -f /root/.ssh/known_hosts -R \"[localhost]:2222\"\e[0m"
                read -p "Press [ENTER] to continue"
            else
                echo "Huh it looks like ssh is not working, please try to reboot your computer or send the log through discord"
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
        echo "[*] Removing some boot image file caches in the preboot"
        if [ ! $(remote_cmd "rm /mnt6/"$active"/System/Library/Caches/com.apple.kernelcaches/kernelcachd /mnt6/"$active"/usr/standalone/firmware/root_hasd.img4 /mnt6/"$active"/usr/standalone/firmware/devicetred.img4 /mnt6/"$active"/usr/standalone/firmware/FUD/StaticTrustCachd.img4") ];  then
            echo "[-] There is not boot images, Omitting ..."
        fi

        echo "[*] Removing the dualboot partitions"
        
        partition_type="$(remote_cmd "/System/Library/Filesystems/apfs.fs/apfs.util -p /dev/disk0s1s${disk}")"
        if [ ! "$partition_type" == 'SystemB' ]; then
            # Print an error message and prompt the user to continue or exit
            echo "[-] error this partition may be important and could be deleted by apfs_deletefs."
            read -p "Press [ENTER] to continue, or [CTRL]+[C] to exit."
        fi

        # this eliminate dualboot paritions 
        remote_cmd "/sbin/apfs_deletefs disk0s1s${disk} > /dev/null || true"
        remote_cmd "/sbin/apfs_deletefs disk0s1s${dataB} > /dev/null || true"
        if [[ ! "$version" = "13."* ]]; then
            remote_cmd "/sbin/apfs_deletefs disk0s1s${prebootB} > /dev/null || true"
        fi
        
        echo "[*] the dualboot has been removed"
        echo "[*] Checking if there is more partitions and removing them"
        i=$((prebootB + 1))
        
        if [[ "$version" = "13."* ]]; then
            i=$((dataB + 1))
        fi
        

        while [ "$(remote_cmd "ls /dev/disk0s1s$i 2>/dev/null")" ]; do
            echo "Found /dev/disk0s1s$i deleting ..."
            cmd="/sbin/apfs_deletefs disk0s1s$i &>/dev/null || true"
            remote_cmd "$cmd"
            i=$((i + 1))
        done
        
        remote_cmd "/usr/sbin/nvram auto-boot=true"
        echo "[*] the dualboot was sucessfully removed, now we are rebooting your device"
        remote_cmd "/sbin/reboot"
        exit;
    fi

    remote_cp root@localhost:/mnt6/"$active"/System/Library/Caches/apticket.der blobs/"$deviceid"-"$version".der
    cp -av blobs/"$deviceid"-"$version".der work/IM4M

    if [ "$jailbreak" = "1" ]; then
    
        if [ ! -f boot/"${deviceid}"/iBEC.img4 ]; then
            echo "[-] you don't have any boot files created, if you are doing this before dualbooting please dualboot first then when the device finishes booting then try to jailbreak"
            exit;
        fi
        
        echo "[*] we are now patching the kernel" # this will send and patch the kernel
	echo "[*] If this fails, please run python3 -m pip uninstall lzss, and re-run the script"
        cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/kernelcache"
                
        if [[ "$deviceid" == "iPhone8"* ]] || [[ "$deviceid" == "iPad6"* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw --extra work/kpp.bin >/dev/null
        else
            python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw >/dev/null
        fi
        
        remote_cmd "/sbin/mount_apfs /dev/disk0s1s${disk} /mnt8/"
        remote_cmd "/sbin/umount /dev/disk0s1s2"
        remote_cmd "/sbin/mount_apfs /dev/disk0s1s${dataB} /mnt2/"
        remote_cmd "/sbin/mount_apfs /dev/disk0s1s${prebootB} /mnt4/"

        if [ ! "$taurine" = "1" ]; then
            remote_cp work/kcache.raw root@localhost:/mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw
            remote_cp binaries/Kernel15Patcher.ios root@localhost:/mnt8/private/var/root/kpf15.ios
            remote_cmd "/usr/sbin/chown 0 /mnt8/private/var/root/kpf15.ios"
            remote_cmd "/bin/chmod 755 /mnt8/private/var/root/kpf15.ios"
            sleep 1

            if [ ! $(remote_cmd "/mnt8/private/var/root/kpf15.ios /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched 2>/dev/null") ]; then
                echo "you already have the kernelpath installed "
            fi
            sleep 2
            remote_cp root@localhost:/mnt4/"$active"/System/Library/Caches/com.apple.kernelcaches/kcache.patched work/ # that will return the kernelpatcher in order to be patched again and boot with it 
            "$dir"/Kernel64Patcher work/kcache.patched work/kcache.patchedB -l  $(if [[ "$version" = "15."* ]]; then echo "-e -o -r -b15"; fi) $(if [[ "$version" = "14."* ]]; then echo "-b"; fi) >/dev/null
            
            if [[ "$deviceid" == *'iPhone8'* ]] || [[ "$deviceid" == *'iPad6'* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
                python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/kcache.im4p -f $(if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then echo "rkrn"; else echo "krnl"; fi)  --extra work/kpp.bin --lzss >/dev/null
            else
                python3 -m pyimg4 im4p create -i work/kcache.patchedB -o work/kcache.im4p -f $(if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then echo "rkrn"; else echo "krnl"; fi)  --lzss >/dev/null
            fi
        
            python3 -m pyimg4 img4 create -p work/kcache.im4p -o $(if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then echo "work/kernelcache.img4"; else echo "work/kernelcachd"; fi) -m work/IM4M >/dev/null
            remote_cp work/kernelcachd root@localhost:/mnt6/"$active"/System/Library/Caches/com.apple.kernelcaches/kernelcachd
        fi



        if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then
            cp -rv "work/kernelcache.img4" "boot/${deviceid}"
        fi

        remote_cmd "rm -f /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched"
        
        #"$dir"/kerneldiff work/kcache.raw work/kcache.patchedB work/kc.bpatch
        #"$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o work/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch `if [ "$os" = 'Linux' ]; then echo "-J"; fi`
        #remote_cp root@localhost:/mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kernelcachd work/kernelcache.img4
        echo "[*] Copied the new kernelcache Successfully!"
        
        echo "[*] Installing trollstore on the Apple TV app"
	
        if [ ! $(remote_cmd "trollstoreinstaller TV") ]; then
            echo "[/] you have to install trollstore in order to intall taurine"
        fi

        if [ "$taurine" = 1 ]; then
            echo "[*] Creating a file to specify the partition to taurine, it will be /disk$disk"
            remote_cmd "/usr/bin/touch /mnt8/disk0s1s$disk"
            echo "[*] installing taurine"
            remote_cp other/taurine/* root@localhost:/mnt8/
            echo "[*] Done, please install trollstore through the Apple TV app, after that if you dont see Taurine on the home screen, open trollstore and click on 'Rebuild icon cache' if it is still not there, plase ask us on the dualra1n discord server"
            remote_cmd "/sbin/reboot"
            exit;
        fi

        remote_cmd "/bin/mkdir -p /mnt8/Applications/dualra1n-loader.app && /bin/mkdir -p /mnt8/Applications/trollstore.app" # thank opa you are a tiger xd 
        
        echo "[*] copying the dualra1n-loader.app so please wait ..."
        remote_cp other/dualra1n-loader.app root@localhost:/mnt8/Applications/
        remote_cmd "chmod +x /mnt8/Applications/dualra1n-loader.app/dual* && /usr/sbin/chown 33 /mnt8/Applications/dualra1n-loader.app/dualra1n-loader && /bin/chmod 755 /mnt8/Applications/dualra1n-loader.app/dualra1n-helper && /usr/sbin/chown 0 /mnt8/Applications/dualra1n-loader.app/dualra1n-helper" 



        echo "[*] Installing JBINIT, thanks palera1n team"
        echo "[*] Copying files to the rootfs"
        sleep 1
        remote_cmd "mkdir -p /mnt8/jbin/binpack /mnt8/jbin/loader.app"
        sleep 1

        # this is the jailbreak of palera1n being installing 
        
        cp -v other/post.sh other/rootfs/jbin/
        remote_cp other/rootfs/* root@localhost:/mnt8/
        remote_cmd "ldid -s /mnt8/jbin/launchd /mnt8/jbin/jbloader /mnt8/jbin/jb.dylib"
        remote_cmd "chmod +rwx /mnt8/jbin/launchd /mnt8/jbin/jbloader /mnt8/jbin/post.sh"
        remote_cmd "ln -fs /jbin/binpack/ /mnt2/pkg"
        echo "[*] Extracting the binpack"
        remote_cmd "tar -xf /mnt8/jbin/binpack/binpack.tar -C /mnt8/jbin/binpack/"
        sleep 1
        remote_cmd "rm /mnt8/jbin/binpack/binpack.tar"
        remote_cmd "/usr/sbin/nvram auto-boot=true"
        echo "[*] Done! We are going to reboot your device, please run --boot again to boot into the dualboot"        
        remote_cmd "/sbin/reboot"
        exit;
    fi
    

    if [ "$dualboot" = "1" ] || [ "$downgrade" = "1" ]; then
        if [ -z "$dont_createPart" ]; then # if you have already your second ios you can omited with this
            echo "[*] Starting step 1"
            echo "[*] Checking if we can continue with the dualboot"

            if [ "$downgrade" = "1" ]; then
                echo "--downgrade option detected, this will destroy the main ios."
                read -p "Please if you do not agree to remove the main ios please ctrl + c to exit from the program and run --dualboot instead or dont do this at all, if you do agree to remove the main iOS click ENTER to continue. info: This option is meant for 16gb users, this will also mean if you ever want to boot your device you are going to need to run --boot as this will make your device tethered, in the case that you want to return to the main iOS, just use itunes to restore"
                sleep 4
                echo "[*] Checking if the main ios has the rootfs"
                if [ $(remote_cmd "ls /mnt1/usr/libexec/keybagd 2>/dev/null") ]; then
                    echo "[*] User has chosen to remove the main iOS, Before removing it we are going to save the keybags"
              	    
                    if [ ! $(remote_cmd "ls /mnt6/$active/keybags 2>/dev/null") ]; then
                        remote_cmd "cp -a /mnt2/keybags /mnt6/$active/"
                    fi
                    
                    remote_cmd "/sbin/umount /dev/disk0s1s2 && /sbin/umount /dev/disk0s1s1 2>/dev/null"
                    echo "[*] keybags saved!"
                    echo "[*] Removing the root and data partitions"
                    remote_cmd "/sbin/apfs_deletefs /dev/disk0s1s1 && /sbin/apfs_deletefs /dev/disk0s1s2 2>/dev/null"
                    echo "[*] Removed them successfully (no going back now)"
                    echo "[*] Creating the partitions iOS needs"
                    remote_cmd "/sbin/newfs_apfs -o role=s -A -v System /dev/disk0s1"
        	        if [ $(remote_cmd "/sbin/newfs_apfs -o role=d -A -v Data -P /dev/disk0s1") ]; then # data volumen is created as protected as it panic each time that we need to mount the dualboot
                        echo "[*] An error occurred creating the data partitions but we can continue, continuing..."
                        remote_cmd "/sbin/newfs_apfs -o role=d -A -v Data /dev/disk0s1"
	                fi
                fi
            fi

            echo "[*] Verifying if we can continue with the dualboot"
            if [ "$(remote_cmd "ls /dev/disk0s1s${disk} 2>/dev/null")" ]; then
                if [ "$(remote_cmd "/System/Library/Filesystems/apfs.fs/apfs.util -p /dev/disk0s1s${disk}")" == 'Xystem' ]; then
                    echo "[-] It looks like you have the palera1n semitethered rootful jailbreak installed, please add the command --jail-palera1n in order to remove it"
                    exit;
                else
                    echo "[-] it looks like you have a system installed on the partitions that we ae going to use, please ctrl+c and restorerootfs or ignore this by pressing [enter]. (the dualboot most likely wont boot into the second ios if you dont --restorerootfs before this)."
                    read -p "click enter if you want to continue"
                fi
            else
                echo "[*] Sucessfully verified"
            fi

            echo "[*] Creating partitions"

        	if [ ! $(remote_cmd "/sbin/newfs_apfs -o role=n -A -v SystemB /dev/disk0s1") ] && [ ! $(remote_cmd "/sbin/newfs_apfs -o role=0 -A -v DataB /dev/disk0s1") ]; then # i put this in case that resturn a error the script can continuing
                echo "[*] partitions created, continuing..."
	        fi
		    
            if [[ ! "$version" = "13."* ]]; then
                if [ ! $(remote_cmd "/sbin/newfs_apfs -o role=D -A -v PrebootB /dev/disk0s1") ]; then
                    echo "[*] Preboot partitions already created, continuing ..."
                fi
            fi

            echo "[*] partitions are already created!"
            echo "[*] mounting the filesystems"
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${disk} /mnt8/"
            sleep 1
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${dataB} /mnt9/" # this mount partitions which are needed by dualboot
            sleep 1
            if [[ ! "$version" = "13."* ]]; then
                remote_cmd "/sbin/mount_apfs /dev/disk0s1s${prebootB} /mnt4/"
                sleep 1
            fi

            if [ "$downgrade" = "1" ]; then
                if [ $(remote_cmd "cp -a /mnt6/$active/keybags /mnt9/") ]; then # this are keybags without this the system wont work 
                    echo "[-] ERROR copying the keybags over"
                    exit;
                fi
            else
                if [ $(remote_cmd "cp -a /mnt2/keybags /mnt9/") ]; then
                    echo "[-] ERROR copying the keybags over"
                    exit;
                fi
            fi
             

            if command -v rsync &>/dev/null; then
                echo "[*] rsync is installed on this PC"
            else 
                echo "[-] you dont have rsync installed so the script will take much longer to copy the rootfs file, so please install rsync if you want this process to be faster."
            fi
            
            echo "[*] copying the rootfs filesystem file so please wait, this could take as long as 20 minutes or longer because is through ssh"
            if [ "$os" = "Darwin" ]; then
                if [ ! $("$dir"/sshpass -p 'alpine' rsync -rvz -e 'ssh -p 2222' $extractedIpsw/out.dmg root@localhost:/mnt8 2>/dev/null) ]; then
                    remote_cp $extractedIpsw/out.dmg root@localhost:/mnt8 >/dev/null 2>&1 # this will copy the root file in order to it is mounted and restore partition      
                fi
            else 
                if [ ! $("$dir"/sshpass -p 'alpine' rsync -rvz -e 'ssh -p 2222' "$extractedIpsw$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')" root@localhost:/mnt8 2>/dev/null) ]; then
                    remote_cp "$extractedIpsw$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')" root@localhost:/mnt8 >/dev/null 2>&1
                fi
                # on linux this will be different because asr. this just mount the rootfs and copying all files to partition 
                sleep 2
                dmg_disk=$(remote_cmd "/usr/sbin/hdik /mnt8/${dmgfile} | head -3 | tail -1 | sed 's/ .*//'")
                
                if [[ ! "$version" = "13."* ]]; then
                    remote_cmd "/sbin/mount_apfs -o ro $dmg_disk /mnt5/"
                else 
                    remote_cmd "/sbin/mount_apfs -o ro ""$dmg_disk""s1 /mnt5/"
                fi
                echo "[*] it is extracting the files so please hang on ......."
                
                remote_cmd "cp -na /mnt5/* /mnt8/"
                sleep 2
                
                if [[ ! "$version" = "13."* ]]; then
                    remote_cmd "/sbin/umount $dmg_disk"
                else
                    remote_cmd "/sbin/umount ""$dmg_disk""s1"
                fi
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
  	        if [ $(remote_cmd "ls /dev/disk0s1s$disk") ]; then
                echo "[*] Found disk0s1s$disk"
            else
                echo "[-] Error: We couldn't detect disk0s1s$disk, so you'll need to wait until the device reboots and boots into your main iOS. After that, put your device back in recovery mode and we will continue when we detect your device."
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

                echo "[*] Checking if we have access to disk0s1s$disk"

                if [ $(remote_cmd "ls /dev/disk0s1s$disk") ]; then
                    echo "[*] Detected that we have access! continuing ..."
                else
                    echo "[-] Error: we can't access the root partition, so please --restorerootfs and report this error to the dualra1n discord server"
                    remote_cmd "/usr/sbin/nvram auto-boot=true"
                    remote_cmd "/sbin/reboot"
                    exit;
                fi

            fi

	        echo "[*] Attempting to mount the partitions"
     
            if [ "$os" = "Darwin" ]; then
                remote_cmd "/System/Library/Filesystems/apfs.fs/apfs_invert -d /dev/disk0s1 -s ${disk} -n out.dmg" # this will mount the root file system and would restore the partition 
            fi

            sleep 2
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${disk} /mnt8/"
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${dataB} /mnt9/"
            
            if [[ ! "$version" = "13."* ]]; then
                remote_cmd "/sbin/mount_apfs /dev/disk0s1s${prebootB} /mnt4/"
            fi

            echo "[*] Copying /var ..."
            if [ ! $(remote_cmd "cp -a /mnt8/private/var/. /mnt9/.") ]; then # this will copy all file which is needed by dataB
                echo "[*] /var was copied"
            fi
            sleep 2
            
            remote_cmd "/usr/bin/mount_filesystems >/dev/null 2>&1"
            
            echo "[*] Copying /preboot ..."
            if [[ ! "$version" = "13."* ]]; then
                remote_cmd "cp -na /mnt6/* /mnt4/" # copy preboot to prebootB
                remote_cmd "rm /mnt4/$active/usr/standalone/firmware/FUD/*"
            else
	            if [ $(remote_cmd "cp -a /mnt2/mobile/Library/Preferences/com.apple.Accessibility* /mnt9/mobile/Library/Preferences/") ]; then # this will copy the assesivetouch config to our data partition
                    echo "[*] activating assistive touch"
                fi
                remote_cmd "cp -a /mnt6/${active}/* /mnt8/" # copy preboot to ios 13 partition
                echo "[*] Copying needed files to boot ios 13"
                remote_cmd "mkdir -p /mnt8/private/xarts && mkdir -p /mnt8/private/preboot/"
	            
                if [ $(remote_cmd "ls /mnt8/usr/standalone/firmware/FUD/AOP.img4") ]; then
                        remote_cmd "rm -v /mnt8/usr/standalone/firmware/FUD/AOP.img4"
	            fi

                remote_cmd "cp -a /mnt6/* /mnt8/private/preboot/"

                echo "[*] we are backing up the apfs binaries from the original iOS and changing them to ios 14 apfs.fs" # maybe must of ipad will not work becuase that apfs.fs is from my iphone ipsw ios14 so you can mount a dmg rootfs of ios 14 and extract the apfs.fs and sbin/fsck and remplace it or paste it to the second ios which is ios 13 
                remote_cmd "mv /mnt8/sbin/fsck /mnt8/sbin/fsckBackup && mv /mnt8/System/Library/Filesystems/apfs.fs /mnt8/System/Library/Filesystems/apfs.fsBackup "
                remote_cp other/apfsios14/* root@localhost:/mnt8/

                for (( i = 1; i <= 7; i++ )); do
                    if [ "$(remote_cmd "/System/Library/Filesystems/apfs.fs/apfs.util -p /dev/disk0s1s${i}")" == 'Hardware' ]; then
                        factoryDataPart=$i
                    fi
                done

                if [ ! $(remote_cmd "rm -rv /mnt8/System/Library/Caches/com.apple.factorydata") ]; then 
                    echo "[.] com.apple.factorydata does not exist so continuing ..."
                fi

                remote_cmd "/sbin/mount_apfs /dev/disk0s1s${factoryDataPart} /mnt5/"
                remote_cmd "cp -a /mnt5/FactoryData/* /mnt8/"

                echo "[*] copying odyssey to /applications/"
                unzip other/odysseymod.ipa -d other/
                mkdir -p other/Payload/Applications/
                echo "[*] installing odyssey"

                echo "[*] downloading dualra1n-loader from the internet"
                curl -L https://nightly.link/Uckermark/dualra1n-loader/workflows/build/main/dualra1n-loader.zip -o other/dualra1n-loader.zip
                unzip -o other/dualra1n-loader.zip -d other/
                rm other/dualra1n-loader.zip
                unzip -o other/dualra1n-loader.ipa -d other/

                mv -nv other/Payload/Odyssey.app/  other/Payload/dualra1n-loader.app/  other/Payload/Applications/
                remote_cp other/Payload/Applications/ root@localhost:/mnt8/

                echo "[*] Fixing odyssey"
                remote_cmd "chmod +x /mnt8/Applications/Odyssey.app/Odyssey && /usr/bin/ldid -S /mnt8/Applications/Odyssey.app/Odyssey" 

            fi
            
            sleep 1
            

            if [ $(remote_cmd "cp -a /mnt2/mobile/Library/Preferences/com.apple.Accessibility* /mnt9/mobile/Library/Preferences/") ]; then # this will copy the assesivetouch config to our data partition
                echo "[*] activating assistive touch"
            fi

            echo "[*] installing trollstore"
            remote_cmd "/bin/mkdir -p /mnt8/Applications/trollstore.app"
            remote_cp other/trollstore.app root@localhost:/mnt8/Applications/
            sleep 4
            
            echo "[*] Saving snapshot"
            if [ "$(remote_cmd "/usr/bin/snaputil -c orig-fs /mnt8")" ]; then
                echo "[-] error saving the snapshot, SKIPPING ..."
            fi

            echo "[*] Adding the kernel to /preboot"
            "$dir"/img4 -i "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/kernelcache.release/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" -o work/kernelcache -M work/IM4M -T krnl
            
            if [[ ! "$version" = "13."* ]]; then
                remote_cp work/kernelcache root@localhost:/mnt4/"$active"/System/Library/Caches/com.apple.kernelcaches/kernelcache
            else
                remote_cp work/kernelcache root@localhost:/mnt8/System/Library/Caches/com.apple.kernelcaches/kernelcache
            fi
            echo "[*] Step 1 is complete. You can use the --dont-create-part option to avoid copying and creating partitions, along with redoing any necessary configuration if needed."
        fi
        
        echo "[*] Starting step 2"
        echo "[*] Fixing firmwares"
        fixHard=1

        if [ "$dont_createPart" = "1" ]; then
            remote_cmd "/sbin/mount_apfs /dev/disk0s1s${disk} /mnt8/"

            if [[ ! "$version" = "13."* ]]; then
                remote_cmd "/sbin/mount_apfs /dev/disk0s1s${prebootB} /mnt4/"
            fi

            sleep 1
        fi

        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/AOP.img4 2>/dev/null")" ]; then
            echo "AOP FOUND"
            cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/aop/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/aop/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]AOP[/]//')" -o work/AOP.img4 -M work/IM4M
        fi
        
        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/StaticTrustCache.img4 2>/dev/null")" ]; then
            echo "[*] StaticTrustCache FOUND"
            if [ "$os" = 'Darwin' ]; then
                "$dir"/img4 -i "$extractedIpsw"/Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache -o work/StaticTrustCache.img4 -M work/IM4M -T trst
            else
                "$dir"/img4 -i "$extractedIpsw"/Firmware/"$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')".trustcache -o work/StaticTrustCache.img4 -M work/IM4M -T trst
            fi
        fi
        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/Homer.img4 2>/dev/null")" ]; then
            echo "[*] Homer FOUND"
            cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/homer/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/homer/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]//')" -o work/Homer.img4 -M work/IM4M
        fi
        
        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/Multitouch.img4 2>/dev/null")" ]; then
            echo "[*] Multitouch FOUND"
            cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/_Multitouch[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/_Multitouch[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]//')" -o work/Multitouch.img4 -M work/IM4M
        fi
        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/AVE.img4 2>/dev/null")" ]; then
            echo "[*] AVE FOUND"

            if [[ ! "$version" = "13."* ]]; then
                remote_cmd "cp /mnt6/$active/usr/standalone/firmware/FUD/AVE.img4" "/mnt4/$active/usr/standalone/firmware/FUD/"
            else
                remote_cmd "cp /mnt6/$active/usr/standalone/firmware/FUD/AVE.img4" "/mnt8/usr/standalone/firmware/FUD/"
            fi
            
        fi
        
        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/AudioCodecFirmware.img4 2>/dev/null")" ]; then
            echo "[*] AudioCodecFirmware FOUND"
            cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/_CallanFirmware[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/_CallanFirmware[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]//')" -o work/AudioCodecFirmware.img4 -M work/IM4M
        fi
        if [ "$(remote_cmd "ls /mnt6/$active/usr/standalone/firmware/FUD/ISP.img4 2>/dev/null")" ]; then
            echo "[*] ISP FOUND"
            cp "$extractedIpsw$(awk "/""${model}""/{x=1}x&&/adc/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "work/"
            "$dir"/img4 -i work/"$(awk "/""${model}""/{x=1}x&&/adc/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]isp_bni[/]//')" -o work/ISP.img4 -M work/IM4M
        fi
        if [[ ! "$version" = "13."* ]]; then

            if [ ! "$(remote_cp work/*.img4 root@localhost:/mnt4/"$active"/usr/standalone/firmware/FUD/ )" ]; then
                echo "uh"
            fi
        else
            if [ ! "$(remote_cp work/*.img4 root@localhost:/mnt8/usr/standalone/firmware/FUD/ )" ]; then
                echo "uh"
            fi
        fi

        if [[ ! "$version" = "13."* ]]; then

            if [ "$(remote_cmd "ls /mnt4/$active/usr/standalone/firmware/FUD/*.img4 2>/dev/null")" ]; then
                echo "[*] Fixed firmwares suscessfully"
                rm work/*.img4
            else
                echo "[-] error fixing the firmware (this means certain hardware features ex microphone will not work, please run this manually later), skipping ..."
                fixHard=0
            fi
        else
            
            if [ "$(remote_cmd "ls /mnt8/usr/standalone/firmware/FUD/*.img4 2>/dev/null")" ]; then
                echo "[*] Fixed firmwares suscessfully"
                rm work/*.img4
            else
                echo "[-] error fixing the firmware (this means certain hardware features ex microphone will not work, please run this manually later), skipping ..."
                fixHard=0
            fi
        fi
        
        if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then
            echo "IOS 13 dualboot or bootx option detected, we are going to use the bootx boot process" # bootx is the boot process which is normaly used when we want to boot a ramdisk to restore. we can't use localboot on ios 13.
        else
            echo "IOS 14 or 15 dualboot detected, we are going to use the localboot boot process" # localboot is the boot process that normaly is used when you power on your iphone, it means that can be more stable
        fi
        
        echo "[*] Adding the new modified boot images: kernelcache, root_hash, StaticTrustCache, devicetree... "
        if [ "$fixBoot" = "1" ]; then # i put it because my friend tested on his ipad and that does not boot so when we download all file from the internet so not extracting ipsw that boot fine idk why 
            cd work
            #that will download the files needed
            sleep 1
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/iBSS[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
            "$dir"/pzb -g "$(awk "/""${model}""/{x=1}x&&/DeviceTree[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1)" "$ipswurl"
            
            if [[ ! "$version" = "13."* ]]; then
                if [ "$os" = 'Darwin' ]; then
                    "$dir"/pzb -g Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".root_hash "$ipswurl"
                else
                    "$dir"/pzb -g Firmware/"$(../binaries/Linux/PlistBuddy BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')".root_hash "$ipswurl"
                fi
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
            
            if [[ ! "$version" = "13."* ]]; then
                if [ "$os" = 'Darwin' ]; then
                    cp "$extractedIpsw"/Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."OS"."Info"."Path" xml1 -o - work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".root_hash work/
                else
                    cp "$extractedIpsw"/Firmware/"$(binaries/Linux/PlistBuddy work/BuildManifest.plist -c "Print BuildIdentities:0:Manifest:OS:Info:Path" | sed 's/"//g')".root_hash work/
                fi
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
	echo "[*] If this fails, please run python3 -m pip uninstall lzss, and re-run the script"
        if [[ "$deviceid" == "iPhone8"* ]] || [[ "$deviceid" == "iPad6"* ]] || [[ "$deviceid" == *'iPad5'* ]]; then
            python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw --extra work/kpp.bin >/dev/null
        else
            python3 -m pyimg4 im4p extract -i work/kernelcache -o work/kcache.raw >/dev/null
        fi

        echo "[*] Checking if a jailbreak is installed"
        
        if [ "$dont_createPart" = "1" ] && [ $(remote_cmd "ls /mnt8/jbin/jbloader 2>/dev/null") ] || [[ "$version" = "13."* ]]; then
            if [[ "$version" = "13."* ]]; then
                echo "[*] ios 13 detected so we will be automatically installing a jailbreak"
            fi
            echo "[*] Jailbreak detected"
            remote_cmd "mkdir -p /mnt8/private/var/root/work"
            remote_cp work/kcache.raw root@localhost:"$(if [[ "$version" = "13."* ]]; then echo "/mnt8/"; else echo "/mnt4/"$active"/"; fi)"System/Library/Caches/com.apple.kernelcaches/kcache.raw
            remote_cp binaries/$(if [[ "$version" = "13."* ]]; then echo "Kernel13Patcher.ios"; else echo "Kernel15Patcher.ios"; fi) root@localhost:/mnt8/private/var/root/work/kpf15.ios
            remote_cmd "/usr/sbin/chown 0 /mnt8/private/var/root/work/kpf15.ios"
            remote_cmd "/bin/chmod 755 /mnt8/private/var/root/work/kpf15.ios"
            sleep 1

            if [[ "$version" = "13."* ]]; then
                if [ ! "$(remote_cmd "/mnt8/private/var/root/work/kpf15.ios /mnt8/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt8/System/Library/Caches/com.apple.kernelcaches/kcache.patched 2>/dev/null")" ]; then
                    echo "[-] you have the kernelpath already installed, Omitting ..."
                fi

                remote_cp root@localhost:/mnt8/System/Library/Caches/com.apple.kernelcaches/kcache.patched work/ # that will return the kernelpatcher in order to be patched again and boot with it 
                "$dir"/Kernel64Patcher work/kcache.patched work/kcache.patchedB -b13 -n `if [ "$fixHard" = "0" ]; then echo "-f"; fi` `if [ $(remote_cmd "ls /mnt8/jbin/jbloader") ]; then echo "-l"; fi` >/dev/null                

            else
                if [ ! "$(remote_cmd "/mnt8/private/var/root/work/kpf15.ios /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.raw /mnt4/$active/System/Library/Caches/com.apple.kernelcaches/kcache.patched 2>/dev/null")" ]; then
                    echo "[-] you have the kernelpath already installed, Omitting ..."
                fi
                remote_cp root@localhost:/mnt4/"$active"/System/Library/Caches/com.apple.kernelcaches/kcache.patched work/ # that will return the kernelpatcher in order to be patched again and boot with it 
                remote_cmd "rm -r /mnt8/private/var/root/work"
                "$dir"/Kernel64Patcher work/kcache.patched work/kcache.patchedB $(if [[ "$version" = "15."* ]]; then echo "-e -o -r -b15"; fi) $(if [[ "$version" = "14."* ]]; then echo "-b"; fi) `if [ "$fixHard" = "0" ]; then echo "-f"; fi` `if [ $(remote_cmd "ls /mnt8/jbin/jbloader") ]; then echo "-l"; fi` >/dev/null
            fi
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
            echo "[*] Adding StaticTrustCache"

            "$dir"/img4 -i work/*.trustcache -o work/trustcache.img4 -M work/IM4M -T rtsc

            echo "[*] Adding devicetree"
            sleep 1
            "$dir"/dtree_patcher work/dtree.raw work/dtree.patched $(if [ "$mainData" = "1" ]; then echo ""; else echo "-d"; fi) $(if [[ "$version" = "13."* ]]; then echo ""; else echo "-p"; fi) >/dev/null
            "$dir"/img4 -i work/dtree.patched -o work/devicetree.img4 -A -M work/IM4M -T rdtr
        else
            echo "[*] Adding StaticTrustCache"
            remote_cmd "cp -a /mnt4/$active/usr/standalone/firmware/FUD/StaticTrustCache.img4 /mnt6/$active/usr/standalone/firmware/FUD/StaticTrustCachd.img4"

            echo "[*] Adding devicetree"

            sleep 1 #mainData
            "$dir"/dtree_patcher work/dtree.raw work/dtree.patched $(if [ "$mainData" = "1" ]; then echo ""; else echo "-d"; fi) -p >/dev/null
            "$dir"/img4 -i work/dtree.patched -o work/devicetred.img4 -A -M work/IM4M -T dtre >/dev/null


            echo "[*] Adding root_hash"
            "$dir"/img4 -i work/*.root_hash -o work/root_hasd.img4 -M work/IM4M >/dev/null

            echo "[*] Sending the modified boot images to the device"
            remote_cp work/kernelcachd root@localhost:/mnt6/"$active"/System/Library/Caches/com.apple.kernelcaches/kernelcachd
            remote_cp work/devicetred.img4 work/root_hasd.img4 root@localhost:/mnt6/"$active"/usr/standalone/firmware
            
        fi
        
        echo "[*] finished successfully!"
        echo "[*] Rebooting to recovery ..."
        remote_cmd "/usr/sbin/nvram auto-boot=false"
        remote_cmd "/sbin/reboot"
        _wait recovery
        sleep 4
        _dfuhelper "$cpid"
        sleep 3

        echo "[*] Patching the files iBoot and ibss ..."

        "$dir"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBSS[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]dfu[/]//')" work/iBSS.dec
        "$dir"/iBoot64Patcher work/iBSS.dec work/iBSS.patched >/dev/null
        "$dir"/img4 -i work/iBSS.patched -o work/iBSS.img4 -M work/IM4M -A -T ibss

        "$dir"/gaster decrypt work/"$(awk "/""${model}""/{x=1}x&&/iBoot[.]/{print;exit}" work/BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/Firmware[/]all_flash[/]//')" work/iBEC.dec

        
        "$dir"/iBoot64Patcher work/iBEC.dec work/iBEC.patched $(if [ "$verbose" = "1" ] || [ "$bootx" = "1" ] || [[ "$version" = "13."* ]]; then echo "-b"; fi) "$(if [ "$verbose" = "1" ] || [ "$bootx" = "1" ] || [[ "$version" = "13."* ]]; then echo "-v"; fi) $(if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then echo "wdt=-1 keepsyms=1 debug=0x2014e"; fi) `if [ "$cpid" = '0x8960' ] || [ "$cpid" = '0x7000' ] || [ "$cpid" = '0x7001' ]; then echo "-restore"; fi`" -n $(if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then echo ""; else echo "-l"; fi) >/dev/null
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
        echo "Finished step 2!"
        #echo "so we finish, now you can execute './dualboot.sh --boot' to boot to second ios after that we need that you record a video when your iphone is booting to see what is the uuid and note that name of the uuid"       
        echo "Starting step 3! Booting your device for the first time ..."

        if [[ "$version" = "13."* ]] || [ "$bootx" = "1" ]; then
            echo "IOS 13 or bootx option DETECTED, booting using the bootx method"
            _bootx
        else
            echo "IOS 14,15 DETECTED, booting using the localboot method"
            _boot
        fi
    fi
fi

} 2>&1 | tee logs/${log}
