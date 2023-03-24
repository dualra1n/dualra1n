# dualra1n

A script that lets you dualboot iOS 14-15 (semi-tethered) on [checkm8](https://www.theiphonewiki.com/wiki/Checkm8_Exploit)-vulnerable devices. This is not a downgrade, however you can use [sunst0rm](https://github.com/mineek/sunst0rm) or [my tool "downra1n"](https://github.com/edwin170/downr1n) which works fine on Linux.


# Usage

Example: `./dualboot.sh --dualboot 14.3`

`--dualboot`          Dualboot your iDevice.

`--jail-palera1n`     Use this when you are already jailbroken with semi-tethered palera1n to avoid disk errors. 

`--jailbreak`         Jailbreak dualbooted iOS with [Pogo](https://github.com/elihwyma/Pogo). Usage :  `./dualboot.sh --jailbreak 14.3`

`--taurine`           Jailbreak dualbooted iOS with [Taurine](https://taurine.app). Usage: `./dualboot.sh --jailbreak 14.3 --taurine` (currently ***NOT RECOMMENDED***)
   
`--fixHard`           Fixes microphone, girocopes, camera, audio, etc. (the Home button is not fixed yet)

`--help`              Print this help.
       
`--get-ipsw`          Automatically downloads .iPSW of the iOS version that you want to dualboot. Don't forget to specify iOS version. (currently ***DOES NOT WORK***)

`--dfuhelper`         A helper to help you enter DFU if you are struggling to do it manually.

`--boot`              Lets you boot into dualbooted iOS. use this when you are already dualbooted . Usage : ./dualboot.sh --boot

`--dont-create-part`   Skips creating a new disk partition if you have one already.

`--restorerootfs`     Deletes the dualbooted iOS. (also add --jail-palera1n if you are jailbroken semi-tethered with palera1n)
    
`--recoveryModeAlways`    Fixes the main iOS when it is recovery looping.

`--debug`             Makes the script significantly more verbose. (meaning it will output exactly what command it is running)

`clean`               Deletes the created boot files.

# Dependencies
- A deactivated passcode on A10-A11 
- unzip, python3, libimobiledevice-utils, libusbmuxd-tools
- An .iPSW file for iOS 14-15 
- Around 15 gigabytes of free storage
- A computer with macOS or Linux (if you have neither, you can temporarily "install" a Linux distro to RAM)
# Warnings
- I am **NOT** responsible for any data loss. The user of this program accepts responsibility should something happen to their device.
 **If your device is stuck in recovery, please run one of the following:**
   - futurerestore --exit-recovery
   - irecovery -n

# Ideal Dualboot Versions
iOS 14.2 is the ideal version as on that version the camera and flash works, while on other versions usually they don't. (on devices with A11 SoCs, dualbooting 14.2- will cause a bootloop, so on those devices, use 14.3 instead)

Dualbooting any version of iOS 15 will cause the device to kernel panic, so you will have to use --jailbreak 15.* after the first boot. This should be a one time fix.

iOS 13 is working but only 13.6, 13.7. If you want to dualboot iOS 13, use the [ios13](https://github.com/dualra1n/dualra1n/tree/ios13) branch. This may not work on Wi-Fi only iPads.

# Common Issues

- A9 : Everything works except Camera, Microphone and Gyroscope. (Can be fixed with a userspace reboot or by using iOS 14.2)

- A10/11/X: Home button is not working. You can, however, use tweaks like GesturesXV to simulate iPhone X gestures. You can also activate Assistive Touch on the main iOS and have it also enabled on the dualbooted iOS.

- iPads may have issues with "Deep Sleep" (iOS not "waking up" after the display going to sleep). Installing the tweak [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) may fix this.


# How would I dualboot?

- [A full tutorial](https://github.com/dualra1n/dualra1n/blob/main/tutorial.md)

- [Video tutorial from burhanrana](https://www.youtube.com/watch?v=4iCZv7Ox5AA)

# If there are any other issues, please contact me on the [dualra1n Discord server](https://discord.gg/E6jj48hzd5)

# Buy me a coffee?

[My Paypal](https://www.paypal.me/EdwinNunez2004)

<details><summary>Why did I decide to put a donate me?</summary>
"dualra1n" is not a team, it is just a name for this tool, this means that I created this script, therefore you can support me with whatever you have. This is important for me because right now, I don't have any source of income. I would be glad to receive something for creating this tool. If you can't donate, no problem, just enjoy dualbooting.
</details>

# Credits

<details><summary>Thanks to:</summary>
<p>

- [Edwin](https://github.com/edwin170) owner :)

- [Fatih](https://github.com/swayea) for helping with the readme, testing linux support and being a very good person
- Edward, my brother, for giving me a Hackintosh to test this on
- [azaz0322](https://github.com/m00nl1ghts), [Huy Nguyen](https://github.com/34306), [Uckermark](https://github.com/Uckermark) and [aditya11110](https://github.com/aditya11110) for helping with the readme\

- [palera1n](https://github.com/palera1n) for some of the code
- [Dualboot guide](https://dualbootfun.github.io/) for the guide
- [blacktop](https://github.com/blacktop) for the iPSW downloader
- [Nathan](https://github.com/verygenericname) for the ramdisk
- [Amy](https://github.com/elihwyma) for the [Pogo](https://github.com/elihwyma/Pogo) app
- [checkra1n](https://github.com/checkra1n) for the base of the kpf
- [m1sta](https://github.com/m1stadev) for [pyimg4](https://github.com/m1stadev/PyIMG4)
- [tihmstar](https://github.com/tihmstar) for [pzb](https://github.com/tihmstar/partialZipBrowser)/original [iBoot64Patcher](https://github.com/tihmstar/iBoot64Patcher)/original [liboffsetfinder64](https://github.com/tihmstar/liboffsetfinder64)/[img4tool](https://github.com/tihmstar/img4tool)
- [xerub](https://github.com/xerub) for [img4lib](https://github.com/xerub/img4lib) and [restored_external](https://github.com/xerub/sshrd) in the ramdisk
- [libimobiledevice](https://github.com/libimobiledevice) for several tools used in this project (irecovery, ideviceenterrecovery etc), and [nikias](https://github.com/nikias) for keeping it up to date
- [Dora](https://github.com/dora2-iOS) for kpf
- [Sam Bingner](https://github.com/sbingner) for [Substitute](https://github.com/sbingner/substitute)
- [CoolStar](https://github.com/coolstar) for [Libhooker](https://libhooker.com/docs/index.html)
- [Ralp0045](https://github.com/Ralph0045) for [dtree_patcher](https://github.com/Ralph0045/dtree_patcher) and [Kernel64Patcher](https://github.com/Ralph0045/Kernel64Patcher)
</details>
</p>
