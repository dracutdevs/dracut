for i in dracut-*; do
    if [ -f $i ]; then
        vinfo < $i
    fi
done
unset i
