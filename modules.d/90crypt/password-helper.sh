#!/bin/sh

# first parameter gives us the key name
name="$1"
shift

# rest of the parameters are evaluated as a command line.
# (this will handle parameters with spaces, but plytmouth doesn't)

# pipe the first line of stdin into keyctl and the user
# specified program
( (head -n1 | tee /dev/fd/5 \
    | keyctl padd user "$name" @u > /dev/null 2>&1) 5>&1 | "$@") 4>&1
