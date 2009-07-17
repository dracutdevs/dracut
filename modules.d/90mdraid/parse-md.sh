initrdargs="$initrdargs rd_MD_UUID rd_NO_MD rd_NO_MDIMSM" 

if getarg rd_NO_MD; then
    info "rd_NO_MD: removing MD RAID activation"
    rm /etc/udev/rules.d/65-md-incremental*.rules
else
    MD_UUID=$(getargs rd_MD_UUID=)

    # rewrite the md rules to only process the specified raid array
    if [ -n "$MD_UUID" ]; then
	for f in /etc/udev/rules.d/65-md-incremental*.rules; do
	    [ -e "$f" ] || continue
	    mv $f ${f}.bak 
	    while read line; do 
		if [ "${line/UUID CHECK//}" != "$line" ]; then
		    for uuid in $MD_UUID; do
			printf 'ENV{MD_UUID}=="%s", GOTO="do_md_inc"\n' $uuid
		    done;
 		    printf 'GOTO="md_inc_end"\n';		
		else
		    echo $line; 
		fi
	    done < ${f}.bak > $f
	    rm ${f}.bak 
	done
    fi
fi

if getarg rd_NO_MDIMSM; then
    info "rd_NO_MDIMSM: no MD RAID for imsm/isw raids"
    udevadm control --property=rd_NO_MDIMSM=1
fi