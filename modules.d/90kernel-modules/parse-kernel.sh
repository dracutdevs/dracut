for p in $(getargs rdloaddriver=); do 
	modprobe $p
done
