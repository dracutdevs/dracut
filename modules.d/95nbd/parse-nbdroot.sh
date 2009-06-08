# It'd be nice if this could share rules with 99-block.sh, but since
# the kernel side adds nbd{1..16} when the module is loaded -- before
# they are associated with a server -- we cannot use the udev add rule
# to find it
#
# XXX actually we could, if we move to root=XXX and netroot=XXX, then
# you could do root=LABEL=/ nbdroot=XXX, or netroot=nbd:XXX
#
# However, we need to be 90-nbd.sh to catch root=/dev/nbd*
#
# Preferred format:
#	root=nbd:srv:port[:fstype[:rootflags[:nbdopts]]]
#
# nbdopts is a comma seperated list of options to give to nbd-client
#
#
# Legacy formats:
#	nbdroot=srv,port
#	nbdroot=srv:port[:fstype[:rootflags[:nbdopts]]]
#	root=dhcp nbdroot=srv:port[:fstype[:rootflags[:nbdopts]]]
#	root=nbd nbdroot=srv:port[:fstype[:rootflags[:nbdopts]]]
#

case "$root" in
    nbd|dhcp|'')
	if getarg nbdroot= > /dev/null; then
	    root=nbd:$(getarg nbdroot=)
	fi
	;;
esac

# Convert the Debian style to our syntax, but avoid matches on fs arguments
case "$root" in
    nbd:*,*)
	if check_occurances "$root" ',' 1 && check_occurances "$root" ':' 1;
	then
	    root=${root%,*}:${root#*,}
	fi
	;;
esac

if [ "${root%%:*}" = "nbd" ]; then
    # XXX validate options here?
    # XXX generate udev rules?
    rootok=1
    netroot=nbd
fi
