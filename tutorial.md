# How do I dualboot?

1. <code>git clone --recursive https://github.com/dualra1n/dualra1n</code>

2. Download the .iPSW file for the iOS version which you want to dualboot with and put it in the [ipsw/](https://github.com/dualra1n/dualra1n/tree/main/ipsw) directory. You can download those from [ipsw.me](https://ipsw.me). (Remember, only iOS 14.0 to iOS 14.8.1. are supported. iOS 13.7 is supported too, but requires the [ios13](https://github.com/dualra1n/dualra1n/tree/ios13) branch)

3. Run <code>./dualboot.sh --dualboot <iOSver></code>, replacing "<iOSver>" with the iOS version you wish to dualboot.

4. To boot the other iOS, run <code>./dualboot.sh --boot</code>.

# How to jailbreak the second iOS version  

1. Run `./dualboot.sh --jailbreak 14.2` (add `--fixHard` if you fixed the firmwares before)(the version to dualboot) (highly recommended to use this over Taurine). When this finishes, open Pogo and tap Install, then Do All. If you reboot your device, you will only need to tap Do All in Pogo.

2. Jailbreak with Taurine: <code>./dualboot.sh --jailbreak 14.3 --taurine </code> (not recommended, don't use this unless you are a professional jailbreaker). When this finishes, install TrollStore from the Apple TV app and refresh icon using TrollStore, open Taurine and click Jailbreak.

# How do I fix hardware?

If you have already dualbooted previously (and have not removed said dualboot), run the script with the arguments `--dualboot 14.3 --dont-create-part --fixHard`.

If you have not dualbooted yet, run the script with the arguments `--dualboot 14.3 --fixHard`.

# How do I delete the dualbooted iOS?

1. <code>./dualboot.sh --restorerootfs 14.2 </code> (if you have palera1n semi-tethered you must add <code>--jail-palera1n</code>)


# Issues 

1. Problem when installing something in Sileo whilst jailbroken with Taurine. You can solve this problem by removing Substrate.


2. "Deep sleep", the iDevice not "waking up" when it's supposed to. Installing [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) will fix this.


