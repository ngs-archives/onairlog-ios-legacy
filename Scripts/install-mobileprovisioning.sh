#!/bin/sh
set -eu
for file in MobileProvisionings/*.*provision*; do
  uuid=`grep UUID -A1 -a "$file" | grep -io "[-A-Z0-9]\{36\}"`
  extension="${file##*.}"
  echo "$file -> $uuid"
  cp "$file" $HOME/Library/MobileDevice/Provisioning\ Profiles/"$uuid.$extension"
done

