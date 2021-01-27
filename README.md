dracut
====

dracut is an event driven initramfs infrastructure.

[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](.github/CODE_OF_CONDUCT.md)
[![Fedora-32](https://github.com/dracutdevs/dracut/workflows/Fedora-32/badge.svg?branch=master)](https://github.com/dracutdevs/dracut/actions?query=workflow%3AFedora-32)
[![Fedora-33](https://github.com/dracutdevs/dracut/workflows/Fedora-33/badge.svg?branch=master)](https://github.com/dracutdevs/dracut/actions?query=workflow%3AFedora-33)
[![Fedora-latest](https://github.com/dracutdevs/dracut/workflows/Fedora-latest/badge.svg?branch=master)](https://github.com/dracutdevs/dracut/actions?query=workflow%3AFedora-latest)

dracut (the tool) is used to create an initramfs image by copying tools
and files from an installed system and combining it with the
dracut framework, usually found in /usr/lib/dracut/modules.d.

Unlike other implementations, dracut hard-codes as little
as possible into the initramfs. The initramfs has
(basically) one purpose in life -- getting the rootfs mounted so that
we can transition to the real rootfs.  This is all driven off of
device availability.  Therefore, instead of scripts hard-coded to do
various things, we depend on udev to create device nodes for us and
then when we have the rootfs's device node, we mount and carry on.
This helps to keep the time required in the initramfs as little as
possible so that things like a 5 second boot aren't made impossible as
a result of the very existence of an initramfs.

Most of the initramfs generation functionality in dracut is provided by a bunch
of generator modules that are sourced by the main dracut script to install
specific functionality into the initramfs.  They live in the modules.d
subdirectory, and use functionality provided by dracut-functions to do their
work.

Currently dracut lives on github.com and kernel.org.

The tarballs can be found here:
	http://www.kernel.org/pub/linux/utils/boot/dracut/
	ftp://ftp.kernel.org/pub/linux/utils/boot/dracut/

Git:
        https://github.com/dracutdevs/dracut.git
        http://git.kernel.org/?p=boot/dracut/dracut.git

Project Documentation:
	http://www.kernel.org/pub/linux/utils/boot/dracut/dracut.html

Project Wiki:
	http://dracut.wiki.kernel.org

See the github issue tracker for things which still need to be done and HACKING.md
for some instructions on how to get started.  There is also a mailing list
that is being used for the discussion -- initramfs@vger.kernel.org.
It is a typical vger list, send mail to majordomo@vger.kernel.org with body
of 'subscribe initramfs email@host.com'


Licensed under the GPLv2
