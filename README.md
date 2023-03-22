# dualra1n

A script that lets you dualboot iOS 14-15 on checkm8 devices.


# Usage

Example: ./dualboot.sh --dualboot 14.3 

    --dualboot          dualboot your idevice with ios 14,15.
    
    --jail-palera1n     Use this only when you already jailbroken with semitethered palera1n to avoid disk errors. 
    
    --jailbreak         jailbreak your second ios with pogo. Usage :  ./dualboot.sh --jailbreak 14.3

    --taurine           Jailbreak dualbooted iOS with Taurine. Usage: ./dualboot.sh --jailbreak 14.3 --taurine NOT RECOMMENDED
   
    --fixHard           this will fix microphone, girocopes, camera, audio, etc. at the moment home button its not fixed yet. 

    --help              Print this help.
       
    --get-ipsw           Automaticly downloads IPSW that you want to dualboot. Dont forget specify iOS version. THIS DOES'NT WORK.

    --dfuhelper         A helper to enter DFU if you struggling in it.
    
    --boot              Lets you boot into dualbooted iOS. use this when you are already dualbooted . Usage : ./dualboot.sh --boot
    
    --dont-create-part   Skips the creating a new disk partition if you have them already.
    
    --restorerootfs     Deletes dualbooted OS. and remember put --jail-palera1n if you have palera1n semitethered jailbreak 
    
    --recoveryModeAlways    this fixed the first ios when the first ios or the main ios always are entering in recovery mode 
    
    --debug             Debug the script

Subcommands:

    clean               Deletes the created boot files 

---
# Dependencies
- A desactivated passcode on A10-A11 
- unzip, python3
- Update or Install libimobiledevice-utils, libusbmuxd-tools
- A IPSW iOS 14-15 
- 15GB+ free storage
- a MACOS or LINUX, it's better that you use a mac it's more estable and faster

# Warnings
- I am **NOT** responsible for any data loss. The user of this program accepts responsibility should something happen to their device.
 **If your device is stuck in recovery, please run one of the following:**
   - futurerestore --exit-recovery
   - irecovery -n

# Ideal Dualboot Versions
iOS 14.2 is the ideal version as on that version the Camera and flash works, while on other version usually they don't. on a11 like iphone 8 and x the ios 14.2 does not boot so use 14.3 above

Dualbooting any version of iOS 15 will give you kernel panics, so you will have to use --jailbreak 15.* after the first boot. That should be a one time fix.

iOS 13 is working but only 13.6, 13.7. If you want to dualboot with iOS 13.x, use the iOS 13 branch. This probably will not work on iPads without baseband (WiFi Only).

# Common Issues. now there arent problems. just use --fixHard to fix the next errors however homebutton not working yet

 ramdisk-submodule
- A9 : Everything works except Camera, Microphone and Gyroscope. (Can be fixed with ldrestart or by using iOS 14.2)


- A10/11: Home button is not working currently and Camera, Audio, Microphone, Vibration does NOT work at the moment. You can use tweaks like GesturesXV to simulate iPhone X gestures.  also activating assesive touch on the first ios before you dualboot, and when you boot into the second ios you will have activated the assesive touch on the second ios.

- iPhone X: Touchscreen does not work.

- iPads may have issues with "Deep Sleep". Sometimes, installing this tweak [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) may fix it.

# How would I dualboot?

- [A full tutorial](https://github.com/dualra1n/dualra1n/blob/main/tutorial.md)

- [video tutorial from burhanrana](https://www.youtube.com/watch?v=4iCZv7Ox5AA)

# Problems and issues contact me on the official [Discord](https://discord.gg/E6jj48hzd5)


# if you want, you can support me 

in [Paypal](https://www.paypal.me/EdwinNunez2004)
<details><summary>why I decided to put a donate me ?</summary>
    dualran its not a team, this is just a name for this tool, this means that i created this script, therefore you can support me with whatever you have, that its important for me because rn I am not working cause this tool and i would be glad to receive something for it. if you cant no problem, just enjoy this.
</details>


# Credits

# with love Edwin :)

<details><summary>thanks to</summary>
<p>

- [Edwin](https://github.com/edwin170) owner :)

- [Fatih](https://github.com/swayea) help with readme and tester of linux support and is a very good person.
    <details><summary>readme constributors</summary>
    <p>
        
    - [azaz0322](https://github.com/m00nl1ghts), [Huy Nguyen](https://github.com/34306), [Uckermark](https://github.com/Uckermark) aditya11110 helped          with readme.
    </details>
</details>
<details><summary>Other credits for tools and codes used in dualra1n</summary>

- Edward thanks for my brother for gave me a hackintosh to test this:).

- [palera1n](https://github.com/palera1n) some code from it

- [Dualboot guide](https://dualbootfun.github.io/) for the guide

- [blacktop](https://github.com/blacktop) for the ipsw downloader

- [Nathan](https://github.com/verygenericname) for the ramdisk
    
- [Amy](https://github.com/elihwyma) for the [Pogo](https://github.com/elihwyma/Pogo) app
- [checkra1n](https://github.com/checkra1n) for the base of the kpf
- [m1sta](https://github.com/m1stadev) for [pyimg4](https://github.com/m1stadev/PyIMG4)
- [tihmstar](https://github.com/tihmstar) for [pzb](https://github.com/tihmstar/partialZipBrowser)/original [iBoot64Patcher](https://github.com/tihmstar/iBoot64Patcher)/original [liboffsetfinder64](https://github.com/tihmstar/liboffsetfinder64)/[img4tool](https://github.com/tihmstar/img4tool)
- [xerub](https://github.com/xerub) for [img4lib](https://github.com/xerub/img4lib) and [restored_external](https://github.com/xerub/sshrd) in the ramdisk
- [libimobiledevice](https://github.com/libimobiledevice) for several tools used in this project (irecovery, ideviceenterrecovery etc), and [nikias](https://github.com/nikias) for keeping it up to date
- [Dora](https://github.com/dora2-iOS) for kpf
- [Sam Bingner](https://github.com/sbingner) for [Substitute](https://github.com/sbingner/substitute)
- [CoolStar](https://github.com/coolstar) for [Libhooker]
- [Ralp0045](https://github.com/Ralph0045/Kernel64Patcher) amazing dtree_patcher and kernel64patcher ;)

</p>
</details>
