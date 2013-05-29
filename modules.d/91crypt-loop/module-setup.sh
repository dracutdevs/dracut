check() {
	type -P losetup >/dev/null || return 1
	
	return 255
}

depends() {
	echo crypt
}

installkernel() {
	    instmods loop
}

install() {
	dracut_install losetup
	inst "$moddir/crypt-loop-lib.sh" "/lib/dracut-crypt-loop-lib.sh"
        dracut_need_initqueue
}
