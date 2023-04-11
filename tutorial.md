# How do I dualboot?

1. <code>git clone --recursive https://github.com/dualra1n/dualra1n</code>

2. Download the .iPSW file for the iOS version which you want to dualboot with and put it in the [ipsw/](https://github.com/dualra1n/dualra1n/tree/main/ipsw) directory. You can download those from [ipsw.me](https://ipsw.me). (Remember, only iOS 14.0 to iOS 14.8.1 are supported. iOS 13.7 is supported too, but requires using the [ios13](https://github.com/dualra1n/dualra1n/tree/ios13) branch)

3. Run `./dualboot.sh --dualboot (iOSver)`, replacing "(iOSver)" with the iOS version you wish to dualboot.

4. To boot the other iOS, run <code>./dualboot.sh --boot</code>.

# How do I jailbreak the dualbooted iOS?

1. Run `./dualboot.sh --jailbreak 14.2` When this finishes, open dualra1n-loader and click jailbreak. If you reboot your device, you will only need to tap re-jailbreak. (it is ***highly recommended*** to use this over Taurine)

2. Jailbreak with Taurine: <code>./dualboot.sh --jailbreak 14.3 --taurine </code> (not recommended, don't use this unless you are a professional jailbreaker). When this finishes, open Taurine and click Jailbreak, when the device get in a screen blue try force reboot, after that boot again into the second ios and if you don't see the sileo app try to rejailbreak with taurine and if you see sileo that means that the jailbreak was complete so open dualra1n-loader and click re-jailbreak to activate the tweaks. 

# How do I delete the dualbooted iOS?

1. <code>./dualboot.sh --restorerootfs 14.2 </code> (if you have palera1n semi-tethered you must add <code>--jail-palera1n</code>)

# Issues 

1. Problem when installing something in Sileo whilst jailbroken with Taurine. You can solve this problem by removing Substrate.


2. "Deep sleep", the iDevice not "waking up" when it's supposed to. Installing [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) will fix this.
