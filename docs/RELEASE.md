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
   $ git commit -m "docs: update NEWS.md and AUTHORS" NEWS.md AUTHORS
   $ git push origin master
   ```

5. Tag the release, validate the tag and push

   ```console
   $ git tag -s 060
   $ git tag -v 060
   $ git push --tags
   ```

   Add the section from `NEWS.md` to the git tag message excluding the Rendered
   view entry.

6. Create a new release on github (https://github.com/dracutdevs/dracut/releases/new)
   - Add the section from `NEWS.md` to the release.

7. Open a new milestone, move all unfinished issue from the previous milestone to the new one and close the released milestone (https://github.com/dracutdevs/dracut/milestones)
