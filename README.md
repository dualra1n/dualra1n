# dualra1n

A script that lets you dualboot iOS 14-15 on checkm8 devices.

# What issues you will have known so far

- A9 : Everything works perfect expect camera. (Fixable with ldrestart) # when i jailbreak it the camera always work without using ldrestart (on my iphone6s i dualbooted with ios 14.2 and camera work fine and flash too, i dont know why on others version is different however that work fine on ios 14.2)


- iPhone 7, 7+ : Home button is not working at the moment. You can use tweaks that brings X gestures to move. Also camera is not working too. 

- iPhone 8 , 8+ : Home button is not working at the moment. You can use tweaks that brings X gestures to move. Also camera is not working too. https://www.youtube.com/watch?v=k8-2NhCcVMg&t=0s that is a video how to activate assesive touch in order to settting the setup so after you can install tweaks to dont have to use button one of that is gesture13 or minixs

- iPhone X : Touchscreen is not working.


# Usage

Example: ./dualboot.sh --dualboot 14.3 

    --dualboot          Dualboot your device with any SEP and Baseband compatible iOS 14 version.
    
    --jail_palera1n     Use this only when you already jailbroken with semitethered palera1n to avoid disk errors. 
    
    --jailbreak         Jailbreak the dualbooted iOS with Pogo. Usage :  ./dualboot.sh --jailbreak 14.3

    --taurine           Jailbreak dualbooted iOS with Taurine. Usage: ./dualboot.sh --jailbreak 14.3 --taurine 
   
    --help              Print this help.
       
    --getIpsw           Automaticly downloads IPSW that you want to dualboot. Dont forget specify iOS version.

    --dfuhelper         A helper to enter DFU if you struggling in it.
    
    --boot              Lets you boot into dualbooted iOS. Use it alone. Usage : ./dualboot.sh --boot
    
    --dont_createPart   Skips the creating a new disk partition if you have them already.
    
    --restorerootfs     Deletes dualbooted OS. and remember put --jail_palera1n if you have palera1n semitethered jailbreak 
    
    --fix_preboot       that restore preboot with the prebootBackup. --fix_preboot
    
    --debug             Debug the script

Subcommands:

    clean               Deletes the created boot files 

---

# how to dualboot

Step 1: download your ipsw file which is wanted to dualboot. you can use --getIpsw that will do automatically however if that give error you must download manual and put the ipsw file into the ipsw/ directory 

Step 2: ./dualboot.sh --dualboot 14.3 (other options)

Step 3: when that is already installed and you would want to dualboot your second ios, you will have to use ./dualboot.sh --boot




# How to jailbreak 

1) Jailbreak with Pogo : to jailbreak your device: ./dualboot.sh --jailbreak 14.3 (or your version) remember that if you have palera1n jailbreak you have to put --jail_palera1n. Then after boot, open Pogo tap install, after that tap Do All. Then have fun.

2) Jailbreak with Taurine :  ./dualboot.sh --jailbreak 14.3 --taurine (if you have palera1n jailbreak use --jail_palera1n). After boot, open TV App and install Trollstore, then install ldid and rebuild icon cache. Taurine should appear on your homescreen, open it and tap jailbreak (If it shows Jailbroken, forget it and tap). when that reboot you can not press jsilbroken again or install taurine because that can give erros, each time that you reboot you will have to open pogo app and press do all (never press install because that can create conflict).

- Tested on iPhone 6s on iOS 15.7-15.7.2 - macOS Big Sur, Kali Linux, Ubuntu 22.04


# Credits

- [palera1n](https://github.com/palera1n) for most of code

- [verygenericname](https://github.com/verygenericname) for SSH Ramdisk

- [Dualboot guide](https://dualbootfun.github.io/) for guide

- [Darling](https://github.com/darlinghq) for macOS emulator

- [blacktop](https://github.com/blacktop) for ipsw downloader

- [dora2-iOS]( https://github.com/dora2-iOS) for home button fix

