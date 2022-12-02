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

6. Create a new release on github (https://github.com/dracutdevs/dracut/releases/new)
   - Add the section from `NEWS.md` to the release.

7. Close the github milestone and open a new one (https://github.com/dracutdevs/dracut/milestones)
