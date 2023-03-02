# How do I dualboot?


1. <code>git clone https://github.com/dualra1n/dualra1n.git</code>

2: Download the ipsw file which you want to dualboot with and paste it into ipsw/ directory. You can use this website to download: https://ipsw.me (Remember, iOS 15 to iOS 14.0.) (iOS 13.7 is supported using the iOS 13 branch.) (Other versions are not supported.)


3: Run <code>./dualboot.sh --dualboot 14.2(version you want to dualboot with)</code>

4: To boot the second iOS, run <code>./dualboot.sh --boot</code>


# How to Jailbreak the second iOS version  

1) Run <code>./dualboot.sh --jailbreak <version></code> ( this is very recomendable,its better use this jailbreak) , when this finish,open Pogo and tap install, then tap Do All.

2) Jailbreak with Taurine: <code>./dualboot.sh --jailbreak 14.3 --taurine</code> (not recomndable dont use it if you are not pro on this,)( when that finsh install TrollStore from AppleTV and refresh icon using TrollStore, open taurine and click jailbreak).

# Delete the second iOS install from your device
1) <code>./dualboot.sh --restorerootfs 14.2</code> if you have palera1n semitethered you have to put (--jail_palera1n)


# Common Issues

- A9 : Everything works perfect expect camera. (Fixable with ldrestart) or using ios 14.2


- A10/11: Home button is not working currently. You can use tweaks like GesturesXV to simulate iPhone X gestures. and sounds.


- iPhone X: Touchscreen does not work.

- iPads may have issues with "Deep Sleep". Sometimes, installing this [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) may fix it.


# Problems and issues contact me here in discord there https://discord.gg/UtxhxHFE
