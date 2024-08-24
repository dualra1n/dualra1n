<div align="center">
<img src="https://github.com/hostedbyjustus/dualra1n/assets/139512773/8de3d184-5d1a-4432-807f-e8f47fd34b94" height="128" width=!"128" style="border-radius:25%">
   <h1> dualra1n
      <br/> Dualboot iOS 15 and 14 iDevices to 15 - 13.6
   </h1>
</div>

<h6 align="center"> Supports iOS 13.6-15.8.3 on A9-A11 devices </h6>

#### This will **NOT WORK** on devices with iOS 16.

#### However this script lets you dualboot iOS 15-13.6, (semi-tethered) on [checkm8](https://www.theiphonewiki.com/wiki/Checkm8_Exploit)-vulnerable devices.
#### This is not a downgrade, however you can use [downr1n](https://github.com/edwin170/downr1n) instead.

# New Features

1: using --aslrdisable when creating boot files will disable aslr in all process.
2: using --ptracedisable when creating boot files will disable ptrace debugger detection: PT_DENY_ATTACH in the kernel.

# Interested in dualbooting or downgrading to lower firmwares? 

1: [Semaphorin](https://github.com/hostedbyjustus/Semaphorin-Archive) (Free): supports SEP-less **tethered downgrades and dualboots** <br>‎ ‎ ‎ ‎ ↳ iOS 7.0.6-12.1 (13.x/14.x) on A7-A11 devices
<br>
<br>
2: Limefix SEP Utility (Paid): supports full SEP **untethered and tethered downgrades**  <br>‎ ‎ ‎ ‎ ↳ iOS 9.0-12.5.7 on A9 devices
<br>
<br>
3: [LEGACY-IOS-KIT](https://github.com/LukeZGD/Legacy-iOS-Kit) (Free): supports **untethered and tethered downgrades**  <br>‎ ‎ ‎ ‎ ↳ for 32-Bit devices and includes limited 64-Bit support

# How can you dualboot?

- [A full tutorial](https://github.com/dualra1n/dualra1n/blob/main/tutorial.md)

# Prerequisites
- An A9-A11 device (A10 & A11 will need a deactivated passcode)
- An .iPSW file for iOS 13 - 15.
- Approximately 15GB of free storage
- A computer with macOS or debian/ubuntu/other Linux distro installed (Windows Subsystem for Linux is not supported). Live CDs can work.

# Warnings
- I am **NOT** responsible for any data loss. The user of this program accepts responsibility if something were happen to their device.
 **If your device is stuck in recovery mode, please run one of the following commands:**
   - futurerestore --exit-recovery
   - irecovery -n

# Important info about dualboot Versions

- For devices with A11 SoCs, iOS 14.2 and older will fail to boot. Therefore, use iOS 14.3 or later instead.

- Dualbooting iOS 13 only supports 13.6 and 13.7 and will most likely **NOT** support any lower!
- iPhones with a capacitive home button (ex. iPhone 7/7+) on iOS 13 **WILL NOT HAVE A WORKING HOME BUTTON**. To get around this you can enable assistive touch in the main iOS and it will pass onto the dualbooted OS

- Devices that only have 16GB of storage, can use the --downgrade option instead of --dualboot, this is going to remove the main iOS and replace it with whatever you chose to downgrade to. To go back to the original iOS that you started with, just restore your device (you can use iTunes). 

# Common Issues

- iPads a8/a8x may have issues with "Deep Sleep" (iOS not "waking up" after the display goes to sleep). Installing the tweak [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) or using the dualra1n-loader and selecting the "fixdeepsleep" option may fix this. 


# If there are any other issues, please ask for help on the [dualra1n Discord server](https://discord.gg/Gjs2P7FBuk)

# Credits

<details><summary>Thanks to:</summary>
<p>

- [Uckermark](https://github.com/Uckermark/dualra1n-loader) thank you so much for the amazing dualra1n loader app to jailbreak it.
- thanks to My brother, for giving me a Hackintosh to test this on
- [sasa](https://github.com/sasa8810) thank you for improve the dfu timing on macos, and code to detect root on linux.
- [kjutzn](https://github.com/kjutzn) thank you for improve gramma and give colors to the script.
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
