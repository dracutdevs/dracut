# Conducting A Successful Release

This documents contains the necessary steps to conduct a successful release.

1. Add all items to `NEWS.md`

    Get a first template with [`clog`](https://github.com/clog-tool/clog-cli)
    ```console
    $ clog -r https://github.com/dracutdevs/dracut
    ```

2. Update the contributors list in NEWS.md

   Produce the list with:
   ```console
   $ make CONTRIBUTORS
   ```

   Append the list to the section in `NEWS.md`

3. Update AUTHORS

   ```console
   $ make AUTHORS
   ```

4. Check in AUTHORS and NEWS.md

   ```console
   $ git ci -m "docs: update NEWS.md and AUTHORS" NEWS.md AUTHORS
   ```

5. Tag the release

   ```console
   $ VERSION=052
   $ git tag -s "$VERSION"
   ```

   Add the section from `NEWS.md` to the git tag message.

6. Push git to kernel.org

   With:
   ```console
   $ git remote add kernelorg ssh://gitolite@ra.kernel.org/pub/scm/boot/dracut/dracut.git
   ```

   Push to kernel.org git:
   ```console
   $ git push kernelorg master
   ```


7. Sign and upload tarballs to kernel.org

   ```console
   $ make upload
   ```

   This requires `kup` and a kernel.org account.


8. Close the github milestone and open a new one (https://github.com/dracutdevs/dracut/milestones)
9. Ensure that announcement was sent and reached the linux-initramfs mailinglist (https://www.spinics.net/lists/linux-initramfs/)
