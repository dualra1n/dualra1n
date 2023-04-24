# How do I dualboot?

1. <code>git clone --recursive https://github.com/dualra1n/dualra1n</code>

2. Download the .iPSW file for the iOS version which you want to dualboot with and put it in the [ipsw/](https://github.com/dualra1n/dualra1n/tree/main/ipsw) directory. You can download those from [ipsw.me](https://ipsw.me). (Remember, only iOS 14.0 to iOS 15.* are supported. iOS 13.6 upper is supported too, but requires using the [ios13](https://github.com/dualra1n/dualra1n/tree/ios13) branch)
 
3. Run `./dualboot.sh --dualboot (iOSver)`, replacing "(iOSver)" with the iOS version you wish to dualboot.

4. To boot the other iOS, run <code>./dualboot.sh --boot</code>.

# How do I jailbreak the dualbooted iOS?

1. Run `./dualboot.sh --jailbreak (iOSver)` When this finishes, open dualra1n-loader and click jailbreak. If you reboot your device, you will only need to tap re-jailbreak. (it is ***highly recommended*** to use this over Taurine)

2. Jailbreak with Taurine: <code>./dualboot.sh --jailbreak (iOSver) --taurine </code> (not recommended, don't use this unless you are a professional jailbreaker). When this finishes, open TVAPP and click install trollstore, open trollstore and click refresh icon, when that respring open Taurine and click jailbroken, when the device get in a screen blue try force reboot, after that boot again into the second ios and if you don't see the sileo app try to rejailbreak with taurine and if you see sileo that means that the jailbreak was complete so open dualra1n-loader and click re-jailbreak to activate the tweaks. 

# How do I delete the dualbooted iOS?

1. <code>./dualboot.sh --restorerootfs (iOSver) </code> (if you have palera1n semi-tethered you must add <code>--jail-palera1n</code>)

2. in case that you want to delete just the jailbreak, you can use the restorerootfs option in the dualra1n-loader so when you tap reboot it and --boot, if the device doesn't boot and you'd had the --jailbreak you must do jailbreak again in order to get the second ios boot.

# Issues 

1. "Deep sleep", the iDevice not "waking up" when it's supposed to. Installing [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) will fix this.

# commang cobination for person who don't understand very well :_

- --dualboot (vers) --dont-create-part = this will create the boot files instead install the second ios again.

-- dualboot (vers) --jail-palera1n, use --jail-palera1n always when you have the palera1n semitethered jailbreak.
