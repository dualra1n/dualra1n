# How do I dualboot?


1. <code>git clone --recursive https://github.com/dualra1n/dualra1n</code>

2. Download the ipsw file which you want to dualboot with and paste it into ipsw/ directory. You can use this website to download: https://ipsw.me (Remember, iOS 14.0 to iOS 14.8.1. iOS 13.7 is supported using the iOS 13 branch. Other versions are not supported.)


3. Run <code>./dualboot.sh --dualboot <version you want to dualboot with></code>

4. To boot the second iOS, run <code>./dualboot.sh --boot</code>


# How to Jailbreak the second iOS version  

1. Run <code>./dualboot.sh --jailbreak <version></code> (If you want to use palera1n, you have to put --jail_palera1n) Then after boot, open Pogo and tap install. If you reboot your device, you will only need to tap Do all in Pogo.

2. Jailbreak with Taurine: <code>./dualboot.sh --jailbreak 14.3 --taurine</code>

# Delete the second iOS install from your device
<code>./dualboot.sh --restorerootfs 14.2</code>


# Common Issues

- A9 : Everything except the camera works perfectly. (Can be fixed with ldrestart or using iOS 14.2


- A10/11: Home button is not working currently. You can use tweaks like GesturesXV to simulate iPhone X gestures. and sounds.


- iPhone X: Touchscreen does not work.

- iPads may have issues with "Deep Sleep". Sometimes, installing this [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) may fix it.


# Problems and issues contact me here in discord there https://discord.gg/E6jj48hzd5

