#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
TEST_DESCRIPTION="rpm integrity after dracut and kernel install"
$TESTDIR

test_run() {
    set -x
    export rootdir=$TESTDIR/root

    mkdir -p $rootdir

    mkdir -p "$rootdir/proc"
    mkdir -p "$rootdir/sys"
    mkdir -p "$rootdir/dev"

trap 'ret=$?; [[ -d $rootdir ]] && { umount "$rootdir/proc"; umount "$rootdir/sys"; umount "$rootdir/dev"; rm -rf "$rootdir"; }; exit $ret;' EXIT
trap '[[ -d $rootdir ]] && { umount "$rootdir/proc"; umount "$rootdir/sys"; umount "$rootdir/dev"; rm -rf "$rootdir"; }; exit 1;' SIGINT

    mount --bind /proc "$rootdir/proc"
    mount --bind /sys "$rootdir/sys"
    mount -t devtmpfs devtmpfs "$rootdir/dev"

    yum --nogpgcheck --releasever=/ --installroot "$rootdir"/ install -y \
	yum \
	passwd \
	rootfiles \
	systemd \
	kernel \
	fedora-release \
	device-mapper-multipath \
	lvm2 \
	mdadm \
        bash \
        iscsi-initiator-utils \
        $basedir/dracut-[0-9]*.$(arch).rpm \
        $basedir/dracut-network-[0-9]*.$(arch).rpm

    cat >"$rootdir"/test.sh <<EOF
#!/bin/bash
set -x
export LC_MESSAGES=C
rpm -Va &> /test.output
find / -xdev -type f -not -path '/var/*' \
  -not -path '/usr/lib/modules/*/modules.*' \
  -not -path '/etc/*-' \
  -not -path '/etc/.pwd.lock' \
  -not -path '/run/mount/utab' \
  -not -path '/test.sh' \
  -not -path '/test.output' \
  -not -path '/etc/nsswitch.conf.bak' \
  -not -path '/etc/iscsi/initiatorname.iscsi' \
  -not -path '/boot/*0-rescue*' \
  -not -path '/dev/null' \
  -exec rpm -qf '{}' ';' | \
  fgrep 'not owned' &> /test.output
exit
EOF

    chmod 0755 "$rootdir/test.sh"

    chroot "$rootdir" /test.sh

    if [[ -s "$rootdir"/test.output ]]; then
	failed=1
	echo TEST Failed >&2
	cat "$rootdir"/test.output >&2
    fi

    umount "$rootdir/proc"
    umount "$rootdir/sys"
    umount "$rootdir/dev"

    [[ $failed ]] && return 1
    return 0

}

test_setup() {
    return 0
}

test_cleanup() {
    return 0
}

. $testdir/test-functions
