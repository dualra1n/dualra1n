# dualboot-ios-15-with-14-script
this is a script to dualboot your iphone on ios 15 with 14

1: download your ipsw and put it on ipsw/ directory (you can download of ipsw.me. please only ios 14.* also please download exactly your ipsw for your iphone)

2: execute ./dualboot --dualboot 14.3 (or your ios version that you want to dualboot with also is recommended ios 14.3 because you can jailbreak with taurine) 

3: when the script finished, you will have to record a video of iphone's screen because you have to note the name of the preboot directory when that is booting. 



https://user-images.githubusercontent.com/85508740/205308846-edc2673f-4e8c-4265-a63b-14664e4301db.MOV


so you will see that is booting however that will reboot because the preboot directory is not created so we have to create it. 
you have to record a video which look like above. after you have take a photo or to note the name of the directory 

![IMG_0774](https://user-images.githubusercontent.com/85508740/205313633-567ff020-1279-4fdc-88b1-bc0914bdda82.jpg)

like this so note the name /private/preboot/*thisName*/usr/standalone/firmware
now boot ./sshrd.sh or any ssh ramdisk after execute mount_filesystem, execute mount_apfs /dev/disk0s1s10 /mnt4/ after that execute mkdir "*thisName*" | mkdir "*thisName*"/usr | cp -av /mnt6/"theonlydirectorythatexist"/usr mnt4/"*thisName*"/
reboot and your iphone should boot without error 

for any error you could create issues 


this is a video booting my second ios 


https://user-images.githubusercontent.com/85508740/205317738-84b00b64-778a-41ae-bb97-a28b2953b816.mp4


test it on iphone 6s on ios 15.7 using macos big sur

in the case that you dont trust about binary, you can download of palera1n binary both are the same binary and compile https://github.com/Ralph0045/dtree_patcher.git and copy to binary Darwin directory this is the only binary that palera1n does not have it  

you can not do it on linux because dtree_patcher does not work and asr command not exist, if you have any solution, share please.


THANKS PALERA1N, https://dualbootfun.github.io/, MatthewPierson, Ralph0045 and all people who created the boot patcher tool. thanks

