# How do I dualboot?

1. <code>git clone --recursive https://github.com/dualra1n/dualra1n</code>

2. Download the ipsw file which you want to dualboot with and paste it into ipsw/ directory. You can use this website to download: https://ipsw.me (Remember, only iOS 14.0 to iOS 14.8.1. are supported. iOS 13.7 is supported too, but requires the iOS 13 branch. All other versions are unsupported.)

3. Run <code>./dualboot.sh --dualboot 14.2 or (the version to dualboot) </code>

4. To boot the second iOS, run <code>./dualboot.sh --boot</code>


# How to Jailbreak the second iOS version  

1. Run <code>./dualboot.sh --jailbreak 14.2 (the version to dualboot) </code> ( this is very recomendable,its better use this jailbreak) , when this finish, open Pogo and tap install, then tap Do All. If you reboot your device, you will only need to tap Do all in Pogo.

2. Jailbreak with Taurine: <code>./dualboot.sh --jailbreak 14.3 --taurine </code> (not recomndable dont use it if you are not pro on this,)( when that finsh install TrollStore from AppleTV and refresh icon using TrollStore, open taurine and click jailbroken. If you reboot your device, you will only need to tap Do all in Pogo).


# Delete the second iOS install from your device

1. <code>./dualboot.sh --restorerootfs 14.2 </code> (if you have palera1n semitethered you have to put <code>--jail-palera1n</code>)


# issues 

1. problem installing something in sileo using taurine jailbreak, so you can solve that problem removing substrate from sileo.


2. deep sleep = the idevice poweroff automatically when I let use it. installing Fiona tweaks can fix that problem.


