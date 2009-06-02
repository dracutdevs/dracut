# XXX actually we could, if we move to root=XXX and netroot=XXX, then
# you could do root=LABEL=/ iscsiroot=XXX, or netroot=iscsi:XXX
#
#
# Preferred format:
#       root=iscsi:[<servername>]:[<protocol>]:[<port>]:[<LUN>]:<targetname>
#
# Legacy formats:
#       iscsiroot=[<servername>]:[<protocol>]:[<port>]:[<LUN>]:<targetname>
#	root=dhcp iscsiroot=[<servername>]:[<protocol>]:[<port>]:[<LUN>]:<targetname>
#	root=iscsi iscsiroot=[<servername>]:[<protocol>]:[<port>]:[<LUN>]:<targetname>
#       root=??? iscsi_initiator= iscsi_target_name= iscsi_target_ip= iscsi_target_port= iscsi_target_group= iscsi_username= iscsi_password= iscsi_in_username= iscsi_in_password=
#       root=??? iscsi_firmware

case "$root" in
    iscsi|dhcp|'')
	if getarg iscsiroot= > /dev/null; then
	    root=iscsi:$(getarg iscsiroot=)
	fi
	;;
esac

if [ "${root%%:*}" = "iscsi" ]; then
    # XXX validate options here?
    # XXX generate udev rules?
    rootok=1
    netroot=iscsi
fi

if getarg iscsiroot; then
	netroot=iscsi
fi
