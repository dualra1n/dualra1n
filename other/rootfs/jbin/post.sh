#!/jbin/binpack/bin/bash
binpack=/jbin/binpack

# uicache loader app
$binpack/bin/rm -rf /var/.palera1n/loader.app
$binpack/usr/bin/uicache -p /Applications/dualra1n-loader.app/
$binpack/usr/bin/uicache -p /Applications/trollstore.app/

# remount r/w
/sbin/mount -uw /
/sbin/mount -uw /private/preboot/

# lauching daemon automatically
/usr/bin/launchctl load /Library/LaunchDaemons/

# activating tweaks
if [ -f /etc/rc.d/substitute-launcher ]; then
  /etc/rc.d/substitute-launcher
elif [ -f /etc/rc.d/libhooker ]; then
  /etc/rc.d/libhooker
fi

sleep 2

# respring
$binpack/usr/bin/uicache -a
$binpack/usr/bin/killall -9 SpringBoard

echo "[post.sh] done"
exit
