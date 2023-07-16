# How do I dualboot?

1. Clone the repository with the following command: <code>git clone --recursive https://github.com/dualra1n/dualra1n</code>.

2. Download the .iPSW file for the iOS version you intend to dualboot with, and place it in the ipsw/ directory. The file can be obtained from ipsw.me. Keep in mind that only iOS 14.0 to iOS 15.* versions are supported. For versions iOS 13.6 and higher, the ios13 branch should be utilized.

3. Execute the command ./dualboot.sh --dualboot (iOSver), replacing "(iOSver)" with the desired iOS version for dualbooting.

4. To switch to the dualbooted iOS version, run <code>./dualboot.sh --boot</code>.

# How to Jailbreak the Dualbooted iOS?

- Run ./dualboot.sh --jailbreak (iOSver). Upon completion, open the dualra1n-loader and click on "jailbreak". If your device reboots, simply select "re-jailbreak". (This method is highly recommended over Taurine.)

- To jailbreak with Taurine, use the command <code>./dualboot.sh --jailbreak (iOSver) --taurine </code>. Note that this is not the preferred method and should only be used by experienced jailbreakers. After the process is completed, open the TVAPP, select "install trollstore", refresh, and after a respring, open Taurine and select "jailbroken". If your device shows a blue screen, try a forced reboot. After rebooting, boot again into the second iOS version. If the Sileo app is not visible, retry the Taurine jailbreak. If Sileo is visible, the jailbreak was successful, and you can open dualra1n-loader and click "re-jailbreak" to activate the tweaks.

# How do I delete the dualbooted iOS?

1. To delete the dualbooted iOS, use the command: <code>./dualboot.sh --restorerootfs (iOSver) </code>. If you are using palera1n semi-tethered, you must add <code>--jail-palera1n</code> to the command.

2. If you wish to remove the jailbreak alone, use the "restorerootfs" option in the dualra1n-loader. After rebooting and running --boot, if the device doesn't boot and you previously ran --jailbreak, you need to jailbreak again to boot the secondary iOS version.

# Known issues 

"Deep Sleep": The device doesn't "wake up" as expected. Installing Fiona will rectify this. or you can activate localboot to fix it.

# commang cobination for person who don't understand very well :_

- --dualboot (vers) --dont-create-part = this will create the boot files instead install the second ios again.

-- dualboot (vers) --jail-palera1n, use --jail-palera1n always when you have the palera1n semitethered jailbreak.
