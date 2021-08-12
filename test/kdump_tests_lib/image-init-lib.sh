#!/usr/bin/env bash
[ -z "$TESTDIR" ] && TESTDIR=$(realpath ./)

SUDO="sudo"

declare -A MNTS=()
declare -A DEVS=()

perror() {
       echo $@>&2
}

perror_exit() {
       echo $@>&2
       exit 1
}

is_mounted()
{
       findmnt -k -n $1 &>/dev/null
}

clean_up()
{
	for _mnt in ${MNTS[@]}; do
		is_mounted $_mnt && $SUDO umount -f $_mnt
	done

	for _dev in ${DEVS[@]}; do
		[ ! -e "$_dev" ] && continue
		[[ "$_dev" == "/dev/loop"* ]] && $SUDO losetup -d "$_dev"
		[[ "$_dev" == "/dev/nbd"* ]] && $SUDO qemu-nbd --disconnect "$_dev"
	done

	[ -d "$TMPDIR" ] && $SUDO rm --one-file-system -rf -- "$TMPDIR";

	sync
}

trap '
ret=$?;
clean_up
exit $ret;
' EXIT

# clean up after ourselves no matter how we die.
trap 'exit 1;' SIGINT

readonly TMPDIR="$(mktemp -d -t kexec-kdump-test.XXXXXX)"
[ -d "$TMPDIR" ] || perror_exit "mktemp failed."

get_image_fmt() {
	local image=$1 fmt

	[ ! -e "$image" ] && perror "image: $image doesn't exist" && return 1

	fmt=$(qemu-img info $image | sed -n "s/file format:\s*\(.*\)/\1/p")

	[ $? -eq 0 ] && echo $fmt && return 0

	return 1
}

fmt_is_qcow2() {
	[ "$1" == "qcow2" ] || [ "$1" == "qcow2 backing qcow2" ]
}

# If it's partitioned, return the mountable partition, else return the dev
get_mountable_dev() {
	local dev=$1 parts

	$SUDO partprobe $dev && sync
	parts="$(ls -1 ${dev}p*)"
	if [ -n "$parts" ]; then
		if [ $(echo "$parts" | wc -l) -gt 1 ]; then
			perror "It's a image with multiple partitions, using last partition as main partition"
		fi
		echo "$parts" | tail -1
	else
		echo "$dev"
	fi
}

prepare_loop() {
	[ -n "$(lsmod | grep "^loop")" ] && return

	$SUDO modprobe loop

	[ ! -e "/dev/loop-control" ] && perror_exit "failed to load loop driver"
}

prepare_nbd() {
	[ -n "$(lsmod | grep "^nbd")" ] && return

	$SUDO modprobe nbd max_part=4

	[ ! -e "/dev/nbd0" ] && perror_exit "failed to load nbd driver"
}

mount_nbd() {
	local image=$1 size dev
	for _dev in /sys/class/block/nbd* ; do
		size=$(cat $_dev/size)
		if [ "$size" -eq 0 ] ; then
			dev=/dev/${_dev##*/}
			$SUDO qemu-nbd --connect=$dev $image 1>&2
			[ $? -eq 0 ] && echo $dev && break
		fi
	done

	return 1
}

image_lock()
{
	local image=$1 timeout=5 fd

	eval "exec {fd}>$image.lock"
	if [ $? -ne 0 ]; then
		perror_exit "failed acquiring image lock"
		exit 1
	fi

	flock -n $fd
	rc=$?
	while [ $rc -ne 0 ]; do
		echo "Another instance is holding the image lock ..."
		flock -w $timeout $fd
		rc=$?
	done
}

# Mount a device, will umount it automatially when shell exits
mount_image() {
	local image=$1 fmt
	local dev mnt mnt_dev

	# Lock the image just in case user run this script in parrel
	image_lock $image

	fmt=$(get_image_fmt $image)
	[ $? -ne 0 ] || [ -z "$fmt" ] && perror_exit "failed to detect image format"

	if [ "$fmt" == "raw" ]; then
		prepare_loop

		dev="$($SUDO losetup --show -f $image)"
		[ $? -ne 0 ] || [ -z "$dev" ] && perror_exit "failed to setup loop device"

	elif fmt_is_qcow2 "$fmt"; then
		prepare_nbd

		dev=$(mount_nbd $image)
		[ $? -ne 0 ] || [ -z "$dev" ] perror_exit "failed to connect qemu to nbd device '$dev'"
	else
		perror_exit "Unrecognized image format '$fmt'"
	fi
	DEVS[$image]="$dev"

	mnt="$(mktemp -d -p $TMPDIR -t mount.XXXXXX)"
	[ $? -ne 0 ] || [ -z "$mnt" ] && perror_exit "failed to create tmp mount dir"
	MNTS[$image]="$mnt"

	mnt_dev=$(get_mountable_dev "$dev")
	[ $? -ne 0 ] || [ -z "$mnt_dev" ] && perror_exit "failed to setup loop device"

	$SUDO mount $mnt_dev $mnt
	[ $? -ne 0 ] && perror_exit "failed to mount device '$mnt_dev'"
}

get_image_mount_root() {
	local image=$1
	local root=${MNTS[$image]}

	echo $root

	if [ -z "$root" ]; then
		return 1
	fi
}

shell_in_image() {
	local root=$(get_image_mount_root $1) && shift

	pushd $root

	$SHELL

	popd
}

inst_pkg_in_image() {
	local root=$(get_image_mount_root $1) && shift

	# LSB not available
	# release_info=$($SUDO chroot $root /bin/bash -c "lsb_release -a")
	# release=$(echo "$release_info" | sed -n "s/Release:\s*\(.*\)/\1/p")
	# distro=$(echo "$release_info" | sed -n "s/Distributor ID:\s*\(.*\)/\1/p")
	# if [ "$distro" != "Fedora" ]; then
	# 	perror_exit "only Fedora image is supported"
	# fi
	release=$(cat $root/etc/fedora-release | sed -n "s/.*[Rr]elease\s*\([0-9]*\).*/\1/p")
	[ $? -ne 0 ] || [ -z "$release" ] && perror_exit "only Fedora image is supported"

	$SUDO dnf --releasever=$release --installroot=$root install -y $@
}

run_in_image() {
	local root=$(get_image_mount_root $1) && shift

	$SUDO chroot $root /bin/bash -c "$@"
}

inst_in_image() {
	local image=$1 src=$2 dst=$3
	local root=${MNTS[$image]}

	$SUDO cp $src $root/$dst
}

# If source image is qcow2, create a snapshot
# If source image is raw, convert to raw
# If source image is xz, decompress then repeat the above logic
#
# Won't touch source image
create_image_from_base_image() {
	local image=$1
	local output=$2
	local decompressed_image

	local ext="${image##*.}"
	if [[ "$ext" == 'xz' ]]; then
		echo "Decompressing base image..."
		xz -d -k $image
		decompressed_image=${image%.xz}
		image=$decompressed_image
	fi

	local image_fmt=$(get_image_fmt $image)
	if [ "$image_fmt" != "raw" ]; then
		if fmt_is_qcow2 "$image_fmt"; then
			echo "Source image is qcow2, using snapshot..."
			qemu-img create -f qcow2 -b $image $output
		else
			perror_exit "Unrecognized base image format '$image_mnt'"
		fi
	else
		echo "Source image is raw, converting to qcow2..."
		qemu-img convert -f raw -O qcow2 $image $output
	fi

	# Clean up decompress temp image
	if [ -n "$decompressed_image" ]; then
		rm $decompressed_image
	fi
}
