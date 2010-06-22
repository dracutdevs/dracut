if [ "${root%%:*}" = "block" ]; then
    [ -d /dev/.udev/rules.d ] || mkdir -p /dev/.udev/rules.d
    {
    printf 'KERNEL=="%s", SYMLINK+="root"\n' \
	${root#block:/dev/} 
    printf 'SYMLINK=="%s", SYMLINK+="root"\n' \
	${root#block:/dev/} 
    } >> /dev/.udev/rules.d/99-root.rules
    
    printf '[ -e "%s" ] && { ln -s "%s" /dev/root 2>/dev/null; rm "$job"; }\n' \
	"${root#block:}" "${root#block:}" >> /initqueue-settled/blocksymlink.sh

    echo '[ -e /dev/root ]' > /initqueue-finished/block.sh
fi
