# dualra1n

A script that lets you dualboot iOS 15-14. and 13.6/13.7, (semi-tethered) on [checkm8](https://www.theiphonewiki.com/wiki/Checkm8_Exploit)-vulnerable devices. This is not a downgrade, however you can use [downr1n](https://github.com/edwin170/downr1n) instead.

This will not work on devices with iOS 16.

# How would I dualboot?

- [A full tutorial](https://github.com/dualra1n/dualra1n/blob/main/tutorial.md)

- [Video tutorial from burhanrana](https://www.youtube.com/watch?v=4iCZv7Ox5AA)

# Prerequisites
- An A9-A11 device (A10 & A11 will need a deactivated passcode)
- An .iPSW file for iOS 15-14-13.
- Approximately 15GB of free storage
- A computer with macOS or any Linux distro installed (Windows Subsystem for Linux is not supported). Live CDs will work.

# Warnings
- I am **NOT** responsible for any data loss. The user of this program accepts responsibility if something were happen to their device.
 **If your device is stuck in recovery mode, please run one of the following commands:**
   - futurerestore --exit-recovery
   - irecovery -n

# imporant info about dualboot Versions

- For devices with A11 SoCs, iOS 14.2 and earlier will fail to boot. Therefore, use iOS 14.3 or later instead.

- Dualbooting iOS 13 only supports 13.6 and 13.7 and will most likely **NOT** go lower!
- iPhones with a capacitive home button (ex. iPhone 7/7+) on iOS 13 **WILL NOT HAVE A WORKING HOME BUTTON**. To get around this you can enable assistive touch in the main iOS and it will pass onto the dualbooted OS

- for devices that only have 16GB of storage, can use the --downgrade option instead of --dualboot, this is going to remove the main iOS and replace it with whatever you chose to downgrade to. To go back to the original iOS that you started with, just restore your device with itunes or whatever tool you use for restoring your device. 

# Common Issues

- iPhone and iPads may have issues with "Deep Sleep" (iOS not "waking up" after the display goes to sleep). Installing the tweak [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) or using the dualra1n-loader and selecting the "fixdeepsleep" option may fix this. 


# If there are any other issues, please ask for help on the [dualra1n Discord server](https://discord.gg/Gjs2P7FBuk)

# Credits

<details><summary>Thanks to:</summary>
<p>

- [Edwin](https://github.com/edwin170) owner :)
- [Uckermark](https://github.com/Uckermark/dualra1n-loader) thank you so much for the amazing dualra1n loader app to jailbreak it.
- Edward, my brother, for giving me a Hackintosh to test this on
- [sasa](https://github.com/sasa8810) thank for improve the dfu timing on macos
- [ElliesSurviving](https://github.com/ElliesSurviving) thank you for a little fix about pylzss
- [Fatih](https://github.com/swayea) for helping with the readme, testing linux support and being a very good person.
- [plooshi](https://github.com/plooshi) thank you so much for help to fix the home button issue.
- [azaz0322](https://github.com/m00nl1ghts) thank you so much for the repo in the dualra1n.loader.
- [Huy Nguyen](https://github.com/34306), [DarwinUang](https://github.com/DarwinUang), [KlutzyT](https://github.com/klutzyT), and [aditya11110](https://github.com/aditya11110) for helping with the readme
</details>
<details><summary>Credits for tools used in dualra1n</summary>

- [Dualboot guide](https://dualbootfun.github.io/) for the guide
- [palera1n](https://github.com/palera1n) for some of the code
- [opa334](https://github.com/opa334/TrollStore) for the amazing app TrollStore
- [Nathan](https://github.com/verygenericname) for the ramdisk
- [Amy](https://github.com/elihwyma) for [Pogo](https://github.com/elihwyma/Pogo) app
- [Mineek](https://github.com/mineek) thank you for the Kernel15patcher which is a kpf modified to use with bootx.
- [checkra1n](https://github.com/checkra1n) for the base of the kpf
- [m1sta](https://github.com/m1stadev) for [pyimg4](https://github.com/m1stadev/PyIMG4)
- [tihmstar](https://github.com/tihmstar) for [pzb](https://github.com/tihmstar/partialZipBrowser)/original [iBoot64Patcher](https://github.com/tihmstar/iBoot64Patcher)/original [liboffsetfinder64](https://github.com/tihmstar/liboffsetfinder64)/[img4tool](https://github.com/tihmstar/img4tool)
- [xerub](https://github.com/xerub) for [img4lib](https://github.com/xerub/img4lib) and [restored_external](https://github.com/xerub/sshrd) in the ramdisk
- [libimobiledevice](https://github.com/libimobiledevice) for several tools used in this project (irecovery, ideviceenterrecovery etc), and [nikias](https://github.com/nikias) for keeping it up to date
- [Sam Bingner](https://github.com/sbingner) for [Substitute](https://github.com/sbingner/substitute)
- [CoolStar](https://github.com/coolstar) for [Libhooker](https://github.com/coolstar/libhooker) 
- [Taurine](https://github.com/Odyssey-Team/Taurine) for taurine jailbreak
- [Ralp0045](https://github.com/Ralph0045) for [dtree_patcher](https://github.com/Ralph0045/dtree_patcher) and [Kernel64Patcher](https://github.com/Ralph0045/Kernel64Patcher)
- [0x7ff](https://github.com/0x7ff/gaster) thank you so much for the gaster tool.
</details>
</p>
