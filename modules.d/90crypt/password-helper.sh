#!/bin/sh

# first parameter gives us the key name
name="$1"
shift

# rest of the parameters are evaluated as a command line.
# you should not pass parameters with spaces in them, as
# $@ will not handle them correctly. we don't care about
# that, as plymouth doesn't either. (plymouth splits the
# --command parameter with a space delimiter directly, so
# the functionality here is essentially equivalent)

# pipe the first line of stdin into keyctl and the user
# specified program
((head -n1 | tee /dev/fd/5 | \
	keyctl padd user "$name" @u &>/dev/null) 5>&1 | $@) 4>&1
