# dualra1n

A script that lets you dualboot iOS 14-15 (semi-tethered) on [checkm8](https://www.theiphonewiki.com/wiki/Checkm8_Exploit)-vulnerable devices. This is not a downgrade, however you can use [downr1n](https://github.com/edwin170/downr1n) which works fine on MACOS and Linux. not ios 16. 


# How would I dualboot?

- [A full tutorial](https://github.com/dualra1n/dualra1n/blob/main/tutorial.md)

- [Video tutorial from burhanrana](https://www.youtube.com/watch?v=4iCZv7Ox5AA)

# Dependencies
- A deactivated passcode on A10-A11
- An .iPSW file for iOS 14-15 
- Around 15 gigabytes of free storage
- A computer with macOS or Linux (if you have neither, you can temporarily "install" a Linux distro to RAM)

# Warnings
- I am **NOT** responsible for any data loss. The user of this program accepts responsibility should something happen to their device.
 **If your device is stuck in recovery, please run one of the following:**
   - futurerestore --exit-recovery
   - irecovery -n

# Ideal Dualboot Versions
on devices with A11 SoCs, dualbooting 14.2- or earlier will not boot so on those devices, use 14.3 upper instead.

iOS 13 is working but only 13.6, 13.7. If you want to dualboot iOS 13, use the [ios13](https://github.com/dualra1n/dualra1n/tree/ios13) branch, use this command to change the branch: git checkout ios13. to come back to the normal branch use git checkout main.

# Common Issues

- iPhone and iPads may have issues with "Deep Sleep" (iOS not "waking up" after the display going to sleep). Installing the tweak [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) or go to dualra1n-loader and click to fixdeepsleep option, may fix this. 


# If there are any other issues, please contact me on the [dualra1n Discord server](https://discord.gg/E6jj48hzd5)

# Credits

<details><summary>Thanks to:</summary>
<p>

- [Edwin](https://github.com/edwin170) owner :)
- [Uckermark](https://github.com/Uckermark/dualra1n-loader) thank you so much for the amazing dualra1n loader app to jailbreak it.
- Edward, my brother, for giving me a Hackintosh to test this on
- [sasa](https://github.com/sasa8810) thank for improve the dfu timing on macos
- [Fatih](https://github.com/swayea) for helping with the readme, testing linux support and being a very good person.
- [plooshi](https://github.com/plooshi) thank you so much for help to fix the home button issue.

   - [azaz0322](https://github.com/m00nl1ghts), [Huy Nguyen](https://github.com/34306), [DarwinUang](https://github.com/DarwinUang) and [aditya11110](https://github.com/aditya11110) for helping with the readme\
</details>
<details><summary>Credits for tools used in dualra1n</summary>

- [Dualboot guide](https://dualbootfun.github.io/) for the guide
- [palera1n](https://github.com/palera1n) for some of the code
- [opa334](https://github.com/opa334/TrollStore) amazing app
- [blacktop](https://github.com/blacktop) for the iPSW downloader
- [Nathan](https://github.com/verygenericname) for the ramdisk
- [Amy](https://github.com/elihwyma) for the [Pogo](https://github.com/elihwyma/Pogo) app
- [Mineek](https://github.com/mineek) thank you for the Kernel15patcher which is a kpf midfied to use with bootx.
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
