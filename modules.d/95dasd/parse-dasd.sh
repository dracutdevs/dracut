for dasd_arg in $(getargs 'rd_DASD='); do
    (
        IFS=","
        set $dasd_arg
        echo "$@" >> /etc/dasd.conf
    )
done
