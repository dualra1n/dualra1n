# How do I dualboot?

1. Clone the repository with the following command: <code>git clone --recursive https://github.com/dualra1n/dualra1n</code>.

2. Download the .iPSW file for the iOS version you intend to be dualbooting, and place it in the ipsw/ directory. The file can be obtained from [ipsw.me](https://ipsw.me). Please keep in mind that only iOS 13.6 to iOS 15.* are supported.

3. Execute the command ./dualboot.sh --dualboot (iOSver), replacing "(iOSver)" with the desired iOS version for dualbooting.

4. To switch to the dualbooted iOS version after your device rebooted, run <code>./dualboot.sh --boot</code>.

# How do I Jailbreak the Dualbooted iOS?

- Run ./dualboot.sh --jailbreak (iOSver). Upon completion, open the dualra1n-loader and click on "jailbreak". If your device reboots, simply select "re-jailbreak". (This method is highly recommended over Taurine.)

- To jailbreak with Taurine, use the command <code>./dualboot.sh --jailbreak (iOSver) --taurine </code>. Note that this is not the preferred method and should only be used by experienced jailbreakers. After the process is completed, open the Apple TV app, select "install trollstore",
and after a respring, open Taurine and select "jailbreak". If your device shows a blue screen, try a forced reboot. After rebooting, boot again into the second iOS version. If the Sileo app is not visible, retry the Taurine jailbreak. If Sileo is visible, the jailbreak was successful, and you can open dualra1n-loader and click "re-jailbreak" to activate the tweaks.

# How do I delete the dualbooted iOS?

1. To delete the dualbooted iOS, use the command: <code>./dualboot.sh --restorerootfs (iOSver) </code>. If you are using palera1n semi-tethered, you must add <code>--jail-palera1n</code> to the command.

2. If you wish to remove the jailbreak alone, use the "restorerootfs" option in the dualra1n-loader. After rebooting and running --boot, if the device doesn't boot and you previously ran --jailbreak, you need to jailbreak again to boot the secondary iOS version.

# Known issues 

"Deep Sleep": The device doesn't "wake up" after you turn it off. Using the "fixdeepsleep" option in the dualra1n-loader app, or by installing the [Fiona](https://www.ios-repo-updates.com/repository/julioverne-s-repo/package/com.julioverne.fiona/) tweak will fix this issue

# Command Explanation for people who might not understand :_

- --dualboot (vers) --dont-create-part = this will create the boot files (and can fix some stuff if the device doesn't boot) instead of completely installing the second ios again.

- --dualboot (vers) --jail-palera1n, use --jail-palera1n always when you have the palera1n semi-tethered jailbreak.

- --downgrade (vers) use this if you don't have enough storage and you are positive that you dont have any important data on the main OS
