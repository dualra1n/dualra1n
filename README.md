# dualra1n

A script that lets you dualboot iOS 14-15 on checkm8 devices.

# What issues you will have known so far

- A9 : Everything works perfect expect camera. (Fixable with ldrestart)

- A10 : Home button is not working at the moment. You can use tweaks that brings X gestures to move. Also camera is not working too.

- iPhone 8 , 8+ : Home button is not working at the moment. You can use tweaks that brings X gestures to move. Also camera is not working too.

- iPhone X : Touchscreen is not working.


# Usage

Example: ./dualboot.sh --dualboot 14.3 

    --dualboot          Dualboot your device with any SEP and Baseband compatible iOS 14 version.
    
    --jail_palera1n     Use this only when you already jailbroken with palera1n to avoid disk errors. 
    
    --jailbreak         Jailbreak the dualbooted iOS with Pogo. Usage :  ./dualboot.sh --jailbreak 14.3

    --taurine           Jailbreak dualbooted iOS with Taurine. Usage: ./dualboot.sh --jailbreak 14.3 --taurine 
   
    --help              Print this help.
  
    --jump              Bypass setup.app on second iOS. If you want revert phone to original state use --back .
     
    --getIpsw           Automaticly downloads IPSW that you want to dualboot. Dont forget specify iOS version.

    --dfuhelper         A helper to enter DFU if you struggling in it.
    
    --boot              Lets you boot into dualbooted iOS. Use it alone. Usage : ./dualboot.sh --boot
    
    --dont_createPart   Skips the creating a new disk partition if you have a one already.
    
    --restorerootfs     Deletes dualbooted OS.
    
    --fix_preboot       that restore preboot with the prebootBackup. --fix_preboot
    
    --debug             Debug the script

Subcommands:

    clean               Deletes the created boot files 

---

# Fix for booting issue/kernel panic on dualbooted iOS

Step 1: Clone [this](https://github.com/verygenericname/SSHRD_Script) repository and boot a SSH Ramdisk with it.

Step 2: After booting SSH Ramdisk, connect with ssh on it.

Step 3: After connected, run these commands on terminal one by one.

```

mount_apfs /dev/disk0s1s9 /mnt9

mount_apfs /dev/disk0s1s8 /mnt8

mount_apfs /dev/disk0s1s10 /mnt4

cp -av /mnt8/private/var/* /mnt9/

mount_filesystems

cp -av /mnt6/* /mnt4/

```

-  After you succeed, get in DFU again and boot with ./dualboot.sh boot

- If you set a password, the iPhone will ask you your password, enter it.

# How to jailbreak 

1) Jailbreak with Pogo : to jailbreak your device: ./dualboot.sh --jailbreak 14.3 (or your version) remember that if you have palera1n jailbreak you have to put --jail_palera1n. Then after boot, open Pogo tap install, after that tap Do All. Then have fun.

2) Jailbreak with Taurine :  ./dualboot.sh --jailbreak 14.3 --taurine (if you have palera1n jailbreak use --jail_palera1n). After boot, open TV App and install Trollstore, then install ldid and rebuild icon cache. Taurine should appear on your homescreen, open it and tap jailbreak (If it shows Jailbroken, forget it and tap). If it reboots, boot with ./dualboot.sh boot . 

- Tested on iPhone 6s on iOS 15.7-15.7.2 - macOS Big Sur, Kali Linux, Ubuntu 22.04


# Credits

- [palera1n](https://github.com/palera1n) for most of code

- [verygenericname](https://github.com/verygenericname) for SSH Ramdisk

- [Dualboot guide](https://dualbootfun.github.io/) for guide

- [Darling](https://github.com/darlinghq) for macOS emulator

- [blacktop](https://github.com/blacktop) for ipsw downloader

- [dora2-iOS]( https://github.com/dora2-iOS) for home button fix

