# Executed before VM starts
on_build() {
	img_inst_pkg "sshpass"
	img_add_qemu_cmd "-nic socket,connect=127.0.0.1:8010,mac=52:54:00:12:34:57"
}

on_test() {
	local boot_count=$(get_test_boot_count)
	local ssh_server=192.168.77.1

	if [ "$boot_count" -eq 1 ]; then
cat << EOF > /etc/kdump.conf
ssh root@192.168.77.1
core_collector makedumpfile -l --message-level 7 -d 31 -F
EOF

		ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa <<< y

		while ! ping -c 1 $ssh_server -W 1; do
			sleep 1
		done

		while [ -z "$(cat /root/.ssh/known_hosts)" ]; do
			ssh-keyscan -H 192.168.77.1 > /root/.ssh/known_hosts
		done

		sshpass -p fedora ssh $ssh_server "mkdir /root/.ssh"
		cat /root/.ssh/id_rsa.pub | sshpass -p fedora ssh $ssh_server "cat >> /root/.ssh/authorized_keys"

		sshpass -p fedora kdumpctl propagate
		cat /root/.ssh/kdump_id_rsa.pub | sshpass -p fedora ssh $ssh_server "cat >> /root/.ssh/authorized_keys"

		kdumpctl start || test_failed "Failed to start kdump"

		sync

		echo 1 > /proc/sys/kernel/sysrq
		echo c > /proc/sysrq-trigger
	else
		shutdown -h 0
	fi
}
