on_build() {
	:
}

on_test() {
	local boot_count=$(get_test_boot_count)

	if [ $boot_count -eq 1 ]; then
		cat << EOF > /etc/kdump.conf
path /var/crash
core_collector makedumpfile -l --message-level 7 -d 31
EOF
		kdumpctl start || test_failed "Failed to start kdump"

		sync

		echo 1 > /proc/sys/kernel/sysrq
		echo c > /proc/sysrq-trigger

	elif [ $boot_count -eq 2 ]; then

		if has_valid_vmcore_dir /var/crash; then
			test_passed
		else
			test_failed "Vmcore missing"
		fi

		shutdown -h 0
	else
		test_failed "Unexpected reboot"
	fi
}
