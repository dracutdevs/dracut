root=$(getarg root=)

if rflags="$(getarg rootflags=)"; then
    getarg rw && rflags="${rflags},rw" || rflags="${rflags},ro"
else
    getarg rw && rflags=rw || rflags=ro
fi

fstype="$(getarg rootfstype=)"
if [ -z "$fstype" ]; then
    fstype="auto"
fi

