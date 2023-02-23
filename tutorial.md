# How to dualboot?

// first clone the repository to the pc
1: git clone https://github.com/dualra1n/dualra1n.git

Step 2: download your ipsw file which is wanted to dualboot and paste it into ipsw/ directory. you can use this web to download https://ipsw.me (remember ios 15 to ios 14.0 (13.7 is supported using the ios13 branch) other versions are not supported )

// example 
Step 3: ./dualboot.sh --dualboot 14.2  (the version of the ipsw downloaded) (more options like --debug)

// when the dualboot proccess finished
Step 4: to boot the second ios using ./dualboot.sh --boot


# How to jailbreak the dualboot ios (the second ios)

// after you dualbooted your device you can jailbreak (after the first boot to the second ios, you can jailbreak it) 

1) Jailbreak with Pogo : to jailbreak your device: ./dualboot.sh --jailbreak 14.3 (or your version) remember that if you have palera1n jailbreak you have to put --jail_palera1n. Then after boot, open Pogo tap install, after that tap Do All. Then have fun.

2) Jailbreak with Taurine :  ./dualboot.sh --jailbreak 14.3 --taurine (if you have palera1n jailbreak use --jail_palera1n). After boot, open TV App and install Trollstore, then install ldid and rebuild icon cache. Taurine should appear on your homescreen, open it and tap jailbreak (If it shows Jailbroken, forget it and tap). when that reboot you can not press jsilbroken again or install taurine because that can give erros, each time that you reboot you will have to open pogo app and press do all (never press install because that can create conflict).

# delete the dualboot from your device
1) ./dualboot.sh --restorerootfs 14.2


# What issues you will have known so far

- A9 : Everything works perfect expect camera. (Fixable with ldrestart) # when i jailbreak it the camera always work without using ldrestart (on my iphone6s i dualbooted with ios 14.2 and camera work fine and flash too, i dont know why on others version is different however that work fine on ios 14.2)


- iPhone 7, 7+ : Home button is not working at the moment. You can use tweaks that brings X gestures to move. Also camera is not working too. (before you dualboot activate assesivetouch on your device and the second ios will have assesivetouch activated )

- iPhone 8 , 8+ : Home button is not working at the moment. You can use tweaks that brings X gestures to move. Also camera is not working too. https://www.youtube.com/watch?v=k8-2NhCcVMg&t=0s that is a video how to activate assesive touch in order to settting the setup so after you can install tweaks to dont have to use button one of that is gesture13 or minixs

- iPhone X : Touchscreen is not working.

- most ipads have deep sleep so installing [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) may fix it 


# Problems and issues contact me here in discord there https://discord.gg/UtxhxHFE
