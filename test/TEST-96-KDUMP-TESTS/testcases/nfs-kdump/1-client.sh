# Executed before VM starts
on_build() {
	img_inst_pkg "nfs-utils"
	img_add_qemu_cmd "-nic socket,connect=127.0.0.1:8010,mac=52:54:00:12:34:57"
}

on_test() {
	local boot_count=$(get_test_boot_count)
	local nfs_server=192.168.77.1

	if [ "$boot_count" -eq 1 ]; then
		cat << EOF > /etc/kdump.conf
nfs $nfs_server:/srv/nfs
core_collector makedumpfile -l --message-level 7 -d 31
EOF

		while ! ping -c 1 $nfs_server -W 1; do
			sleep 1
		done

		kdumpctl start || test_failed "Failed to start kdump"

		sync

		echo 1 > /proc/sys/kernel/sysrq
		echo c > /proc/sysrq-trigger
	else
		shutdown -h 0
	fi
}
