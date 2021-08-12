#!/usr/bin/env bash

if [ $# -lt 2 ]; then
	echo "Usage: $(basename $0) <base-image> <output-image> <build-script> [<build-script-args>]
	Build a new <output-image> on top of <base-image>, and install
	contents defined in <build-script>. <args> are directly passed
	to <build-script>.

	If <base-image> is raw, will copy it and create <output-image>
	in qcow2 format.

	If <base-image> is qcow2, will create <output-image> as a snapshot
	on top of <base-image>"
	exit 1
fi

BASEDIR=$(realpath $(dirname "$0"))
. $BASEDIR/image-init-lib.sh

# Base image to build from
BASE_IMAGE=$1 && shift
if [[ ! -e $BASE_IMAGE ]]; then
	perror_exit "Base image '$BASE_IMAGE' not found"
else
	BASE_IMAGE=$(realpath "$BASE_IMAGE")
fi

OUTPUT_IMAGE=$1 && shift
if [[ ! -d $(dirname $OUTPUT_IMAGE) ]]; then
	perror_exit "Path '$(dirname $OUTPUT_IMAGE)' doesn't exists"
fi

INST_SCRIPT=$1 && shift

create_image_from_base_image $BASE_IMAGE $OUTPUT_IMAGE.building

mount_image $OUTPUT_IMAGE.building

img_inst() {
	inst_in_image $OUTPUT_IMAGE.building $@
}

img_inst_pkg() {
	inst_pkg_in_image $OUTPUT_IMAGE.building $@
}

img_run_cmd() {
	run_in_image $OUTPUT_IMAGE.building "$@"
}

img_add_qemu_cmd() {
	QEMU_CMD+="$@"
}

[ -e "$INST_SCRIPT" ] && source $INST_SCRIPT

mv $OUTPUT_IMAGE.building $OUTPUT_IMAGE
