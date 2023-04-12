# dualra1n

A script that lets you dualboot iOS 14-15 (semi-tethered) on [checkm8](https://www.theiphonewiki.com/wiki/Checkm8_Exploit)-vulnerable devices. This is not a downgrade, however you can use [sunst0rm](https://github.com/mineek/sunst0rm) or [my tool "downr1n"](https://github.com/edwin170/downr1n) which works fine on Linux.


# Usage

Example: `./dualboot.sh --dualboot 14.3`

Options:

`--dualboot`          Dualboot your iDevice.

`--jail-palera1n`     Use this when you are already jailbroken with semi-tethered palera1n to avoid disk errors. 

`--jailbreak`         Jailbreak dualbooted iOS with [dualra1n-loader](https://github.com/Uckermark/dualra1n-loader). Usage :  `./dualboot.sh --jailbreak 14.3`

`--taurine`           Jailbreak dualbooted iOS with [Taurine](https://taurine.app). Usage: `./dualboot.sh --jailbreak 14.3 --taurine` (currently ***NOT RECOMMENDED***)
   
`--fixHard`           Fixes microphone, girocopes, camera, audio, touchscreen, etc.

`--help`              Print this help.
       
`--get-ipsw`          Automatically downloads .iPSW of the iOS version that you want to dualboot. Don't forget to specify iOS version. (currently ***DOES NOT WORK***)

`--dfuhelper`         A helper to help you enter DFU if you are struggling to do it manually.

`--boot`              Lets you boot into dualbooted iOS. Use this when you already have the dualbooted iOS installed. Usage : ./dualboot.sh --boot

`--dont-create-part`   Skips creating a new disk partition if you have them already, so using this this downloads the boot files. Usage : ./dualboot.sh --dualboot 14.3 --dont-create-part.

`--restorerootfs`     Deletes the dualbooted iOS. (also add --jail-palera1n if you are jailbroken semi-tethered with palera1n)
    
`--recoveryModeAlways`    Fixes the main iOS when it is recovery looping.

`--debug`             Makes the script significantly more verbose. (meaning it will output exactly what command it is running)

Subcommands:

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

iOS 13 is working but only 13.6, 13.7. If you want to dualboot iOS 13, use the [ios13](https://github.com/dualra1n/dualra1n/tree/ios13) branch.

# Common Issues

- iPhone and iPads may have issues with "Deep Sleep" (iOS not "waking up" after the display going to sleep). Installing the tweak [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) may fix this.

- You can fix the above problems by adding `--fixHard`. For instructions on how to do that, check [a full tutorial](https://github.com/dualra1n/dualra1n/blob/main/tutorial.md).

# How would I dualboot?


- [A full tutorial](https://github.com/dualra1n/dualra1n/blob/main/tutorial.md)


- [Video tutorial from burhanrana](https://www.youtube.com/watch?v=4iCZv7Ox5AA)

# If there are any other issues, please contact me on the [dualra1n Discord server](https://discord.gg/E6jj48hzd5)

# Credits

<details><summary>Thanks to:</summary>
<p>

- [Edwin](https://github.com/edwin170) owner :)
- [Uckermark](https://github.com/Uckermark/dualra1n-loader) thank you so much for the amazing dualra1n loader app to jailbreak it.
- Edward, my brother, for giving me a Hackintosh to test this on
- [Fatih](https://github.com/swayea) for helping with the readme, testing linux support and being a very good person.
- [plooshi](https://github.com/plooshi)
   thank you so much for fix the home button issue

   - [azaz0322](https://github.com/m00nl1ghts), [Huy Nguyen](https://github.com/34306), [Uckermark](https://github.com/Uckermark), [DarwinUang](https://github.com/DarwinUang) and [aditya11110](https://github.com/aditya11110) for helping with the readme\
</details>
<details><summary>Credits for tools used in dualra1n</summary>

- [Dualboot guide](https://dualbootfun.github.io/) for the guide
- [palera1n](https://github.com/palera1n) for some of the code
- [opa334](https://github.com/opa334/TrollStore) amazing app
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
- [0x7ff](https://github.com/0x7ff/gaster) thank you so much for the gaster tool.
</details>
</p>
