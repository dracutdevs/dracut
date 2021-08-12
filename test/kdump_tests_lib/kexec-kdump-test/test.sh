#!/usr/bin/env sh
# A test example that do nothing

# Executed before VM starts
on_build() {
	:
}

# Executed when VM boots
on_test() {
	:
	# call get_test_boot_count to get boot cound
	# call test_passed if test passed
	# call test_failed if test passed
}
