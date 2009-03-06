#!/bin/sh
mdadm   --assemble 		\
	--homehost=localhost    \
	--auto-update-homehost  \
	--scan 

udevadm settle --timeout=30 

