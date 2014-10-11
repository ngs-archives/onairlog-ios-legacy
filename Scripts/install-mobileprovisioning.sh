#!/bin/sh
set -eu
BASE=~/Library/MobileDevice/Provisioning\ Profiles
mkdir -p "$BASE"
for file in MobileProvisionings/*$PROVISIONING_SUFFIX.*provision*; do
  uuid=`grep UUID -A1 -a "$file" | grep -io "[-A-Z0-9]\{36\}"`
  extension="${file##*.}"
  echo "$file -> $uuid"
  cp -f "$file" "$BASE/$uuid.$extension"
done
ls -lsa "$BASE"
