#!/bin/bash

# CONTRIBUTORS
printf "#### Contributors\n\n" > CONTRIBUTORS.md
make CONTRIBUTORS >> CONTRIBUTORS.md

# Update AUTHORS
make AUTHORS

# Update NEWS.md
cargo install clog-cli
head -2 NEWS.md > NEWS_header.md
tail +2 NEWS.md > NEWS_body.md
printf "dracut-%s\n==========\n" "$1" > NEWS_header_new.md
cat CONTRIBUTORS.md NEWS_body.md > NEWS_body_with_conttributors.md

# clog will always output both the new release and old release information together
clog -F --infile NEWS_body_with_conttributors.md -r https://github.com/dracutdevs/dracut | sed '1,2d' > NEWS_body_full.md

# Use diff to separate new release information and remove repeated empty lines
diff NEWS_body_with_conttributors.md NEWS_body_full.md | grep -e ^\>\  | sed s/^\>\ // | cat -s > NEWS_body_new.md
cat NEWS_header.md NEWS_header_new.md NEWS_body_new.md NEWS_body_with_conttributors.md > NEWS.md

# message for https://github.com/dracutdevs/dracut/releases/tag
cat -s NEWS_body_new.md CONTRIBUTORS.md > release.md

# Check in AUTHORS and NEWS.md
git config user.name "Dracut Release Bot"
git config user.email "<>"
git commit -m "docs: update NEWS.md and AUTHORS" NEWS.md AUTHORS
git push origin master
git tag "$1" -m "$1"
git push --tags
