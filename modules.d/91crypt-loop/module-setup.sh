check() {
	type -P losetup >/dev/null || return 1
	
	return 255
}

depends() {
	echo crypt
}

install() {
	dracut_install losetup
	inst "$moddir/crypt-loop-lib.sh" "/lib/dracut-crypt-loop-lib.sh"
}
