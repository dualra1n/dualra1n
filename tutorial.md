# How do I dualboot?

1. <code>git clone --recursive https://github.com/dualra1n/dualra1n</code>

2. Download the .iPSW file for the iOS version which you want to dualboot with and put it in the [ipsw/](https://github.com/dualra1n/dualra1n/tree/main/ipsw) directory. You can download those from [ipsw.me](https://ipsw.me). (Remember, only iOS 13.6 to iOS 13.7. are supported.

3. Run `./dualboot.sh --dualboot (iOSver)`, replacing "(iOSver)" with the iOS version you wish to dualboot.

4. To boot the other iOS, run <code>./dualboot.sh --boot</code>.

# How do I jailbreak the dualbooted iOS? jailbreak its not working at all

-   you can jailbreak with the dualra1n-loader or the odyssey jailbreak.

- to jailbreak using odyssey just open the app and click jailbreak, when that finished and respring, just reboot it and boot into the second ios again. when you come back to the second ios open dualra1n-jailbreak and click re-jailbreak

- to jailbreak with dualra1n-loader just open the app and click jailbreak. each time that you reboot the device, open it and click re-jailbreak 

-   if you don't see any of the apps, open tips and click jailbreak.


# How do I delete the dualbooted iOS?

1. <code>./dualboot.sh --restorerootfs 13.7 </code> (if you have palera1n semi-tethered you must add <code>--jail-palera1n</code>)

# Issues 

1. Problem when installing something in Sileo whilst jailbroken with Taurine. You can solve this problem by removing Substrate.


2. "Deep sleep", the iDevice not "waking up" when it's supposed to. Installing [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) will fix this.


# fixHard

you can use --dualboot (vers) --fixHard to create the dualboot with the firmwares fixed 

and you can use --dualboot (vers) --fixHard --dont-create-part in order to get the boot files created again with the fix firmware path into it 