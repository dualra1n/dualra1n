# How do I dualboot?

1. <code>git clone --recursive https://github.com/dualra1n/dualra1n</code>

2. Download the .iPSW file for the iOS version which you want to dualboot with and put it in the [ipsw/](https://github.com/dualra1n/dualra1n/tree/main/ipsw) directory. You can download those from [ipsw.me](https://ipsw.me). (Remember, only iOS 13.6 to iOS 13.7. are supported.

3. Run `./dualboot.sh --dualboot (iOSver)`, replacing "(iOSver)" with the iOS version you wish to dualboot.

4. To boot the other iOS, run <code>./dualboot.sh --boot</code>.

# How do I jailbreak the dualbooted iOS? jailbreak its not working at all

2. Jailbreak with odyssey: <code>./dualboot.sh --jailbreak 14.3 --odyssey </code> (not recommended, don't use this unless you are a professional jailbreaker). When this finishes, install TrollStore from the Apple TV app and refresh icon using TrollStore, open Taurine and click Jailbreak.


# How do I delete the dualbooted iOS?

1. <code>./dualboot.sh --restorerootfs 13.7 </code> (if you have palera1n semi-tethered you must add <code>--jail-palera1n</code>)

# Issues 

1. Problem when installing something in Sileo whilst jailbroken with Taurine. You can solve this problem by removing Substrate.


2. "Deep sleep", the iDevice not "waking up" when it's supposed to. Installing [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) will fix this.


