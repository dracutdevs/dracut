# Conducting A Successful Release
This documents should contain the necessary steps to conduct a successful release.
TODO Harald,Daniel fill in every step required for doing release in their correct order.
( Replace the sample steps with relevant actual steps ) 

1. Add all items to NEWS (Should outline the step required)
2. Update the contributors list in NEWS (Should outline the step required)
3. Update the time and place in NEWS (Should outline the step required)
4. Tag the release (version=05X && git tag -s "${version}" -m "dracut ${version}")
5. Make sure that the version string and package string match(Should outline the step required)
6. Close the github milestone and open a new one (https://github.com/dracutdevs/dracut/milestones)
7. "Draft" a new release on github (https://github.com/dracutdevs/dracut/releases/new)
8. Ensure that announcement was sent and reached the linux-initramfs mailinglist (https://www.spinics.net/lists/linux-initramfs/)
9. Update description on dracuts lobby on gitter.
9. Push commits to relevant branches (RHEL/SUSE)
