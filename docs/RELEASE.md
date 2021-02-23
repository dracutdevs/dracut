# Conducting A Successful Release

This documents contains the necessary steps to conduct a successful release.

1. Add all items to `NEWS.md`

    Get a first template with [`clog`](https://github.com/clog-tool/clog-cli)
    ```console
    $ clog -F -r https://github.com/dracutdevs/dracut
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

5. Tag the release and push

   ```console
   $ VERSION=052
   $ git tag -s "$VERSION"
   $ git push --tags
   ```

   Add the section from `NEWS.md` to the git tag message.

6. Push git to kernel.org

   With:
   ```console
   $ git remote add kernelorg ssh://gitolite@ra.kernel.org/pub/scm/boot/dracut/dracut.git
   ```

   Push to kernel.org git:
   ```console
   $ git push --atomic kernelorg master "$VERSION"
   ```


7. Sign and upload tarballs to kernel.org

   ```console
   $ make upload
   ```

   This requires `kup` and a kernel.org account.
   Wait until the tarballs are synced to http://www.kernel.org/pub/linux/utils/boot/dracut/ .

8. Create a new release on github (https://github.com/dracutdevs/dracut/releases/new)
   - Add the section from `NEWS.md` to the release.
   - Attach the tarballs and signature file from http://www.kernel.org/pub/linux/utils/boot/dracut/ to the github release.

9. Close the github milestone and open a new one (https://github.com/dracutdevs/dracut/milestones)
10. Ensure that announcement was sent and reached the linux-initramfs mailinglist (https://www.spinics.net/lists/linux-initramfs/)
