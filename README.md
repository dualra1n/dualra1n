# dualboot-ios-15-with-14-script
this is a script to dualboot your iphone on ios 15 with 14

# tutorial



Options:
    --dualboot          dualboot your device ios 15 with 14 
    --jail_palera1n     uses only if you have the palera1n jailbreak installed, it will create partition on disk + 1 because palera1n create a new partition. disk0s1s8 however if you jailbreakd with palera1n the disk would be disk0s1s9"
    
    for example ./dualboot.sh --dualboot 14.3 --jail_palera1n 
    
    
    --jailbreak         jailbreak your second ios. you can use it when your device boot correctly the second ios. example ./dualboot.sh --jailbreak 14.3
    
    --help              Print this help
    
    --bypass            that will bypass to second ios in case that you dont know the password of icloud however you could not login on icloud, but you can login on appstore and download apps. thank you for share mobileactivationd @MatthewPierson". example./dualboot.sh --jailbreak 14.3
    
    --dfuhelper         A helper to help get A11 devices into DFU mode from recovery mode
    
    --boot              put boot alone, to boot your second ios. /dualboot.sh --boot
    
    --dont_createPart   Don't create the partitions if you have already created. ./dualboot.sh --dualboot 14.3 --dont_createPart
    
    --restorerootfs     Remove partitions of dualboot. ./dualboot.sh --restorerootfs
    
    --fix_preboot       that restore preboot with the prebootBackup. --fix_preboot
    
    --debug             Debug the script

Subcommands:
    clean               Deletes the created boot files

The iOS version argument should be the iOS version of your device.
It is required when starting from DFU mode.



1: download your ipsw and put it on ipsw/ directory (you can download of ipsw.me. please only ios 14.* also please download exactly your ipsw for your device) (your ios version that you want to dualboot with also is recommended ios 14.3 because you can jailbreak with taurine)

2: execute ./dualboot --dualboot 14.3 (the version of your ipsw downloaded which is the version that you want to dualboot ) 

3: ./dualboot --boot 

---
# just in case kenelpanic
in case that your iphone not boot on the second ios try to do this:
you will have to record a video of iphone's screen because you have to note the name of the preboot directory when that is booting. 



https://user-images.githubusercontent.com/85508740/205308846-edc2673f-4e8c-4265-a63b-14664e4301db.MOV


so you will see that is booting however that will reboot because the preboot directory is not created so we have to create it. 
you have to record a video which look like above. after you have take a photo or to note the name of the directory 

![IMG_0774](https://user-images.githubusercontent.com/85508740/205313633-567ff020-1279-4fdc-88b1-bc0914bdda82.jpg)

like this so note the name /private/preboot/*thisName*/usr/standalone/firmware
now boot ./sshrd.sh or any ssh ramdisk after execute mount_filesystem, execute mount_apfs /dev/disk0s1s10 /mnt4/ after that execute mkdir "*thisName*" | mkdir "*thisName*"/usr | cp -av /mnt6/"theonlydirectorythatexist"/usr mnt4/"*thisName*"/
reboot and your iphone should boot without error 
---
# how to jailbreak 
---
to jailbreak your device: ./dualboot.sh --jailbreak 15.7 (or your version)
after install trollstore with https://github.com/verygenericname/SSHRD_Script, after install 2 ipa in the dualboot repository 3 taurine and pogo also filza if you want, after open taurine and jailbreak it when that reboot, boot again to the second ios, open pongo which was installed by trollstore and click do all (never click install that can break the jailbreak so only you will use pongo to press do all) after that you can use sileo to install package and install libhooker to inyect tweaks (if you reboot your device, the tweaks will be disable so you have to reinstall libhooker opening sileo and press reinstall )

---

for any error you could create issues 


this is a video booting my second ios:

https://user-images.githubusercontent.com/85508740/205317738-84b00b64-778a-41ae-bb97-a28b2953b816.mp4


test it on iphone 6s on ios 15.7 using macos big sur

in the case that you dont trust about binary, you can download of palera1n binary both are the same binary and compile https://github.com/Ralph0045/dtree_patcher.git and copy to binary Darwin directory this is the only binary that palera1n does not have it  

you can not do it on linux because dtree_patcher does not work and asr command not exist, if you have any solution, share please.


# thanks

THANKS PALERA1N, https://dualbootfun.github.io/, MatthewPierson, Ralph0045, people who help me test on discord like @something, @samm and others and all people who created the boot patcher tool. thanks

