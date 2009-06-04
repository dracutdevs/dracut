#!/bin/sh

# first trigger graphics subsystem
udevadm trigger --attr-match=class=0x030000
# first trigger graphics and tty subsystem
udevadm trigger --subsystem-match=graphics --subsystem-match=tty >/dev/null 2>&1
# add nomatch for full trigger
echo " --subsystem-nomatch=graphics --subsystem-nomatch=tty " >> /tmp/udevtriggeropts

udevadm settle --timeout=30 >/dev/null 2>&1
[ -c /dev/null ] || mknod /dev/null c 1 3
[ -c /dev/zero ] || mknod /dev/zero c 1 5
[ -c /dev/systty ] || mknod /dev/systty c 4 0
[ -c /dev/fb ] || mknod /dev/fb c 29 0
[ -c /dev/hvc0 ] || mknod /dev/hvc0 c 229 0

[ -x /bin/plymouthd ] && /bin/plymouthd

/lib/udev/console_init tty0
/bin/plymouth --show-splash

