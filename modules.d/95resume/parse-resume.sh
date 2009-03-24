#!/bin/sh
if resume=$(getarg resume=) && ! getarg noresume; then 
    export resume
    echo "$resume" >/.resume
else
    unset resume
fi
