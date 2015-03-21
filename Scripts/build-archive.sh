#!/bin/sh
set -eu

PROVISIONING_PROFILE="$HOME/Library/MobileDevice/Provisioning Profiles/$PROFILE_UUID.mobileprovision"
RELEASE_DATE=`date '+%Y-%m-%d %H:%M:%S'`
ARCHIVE_PATH="Build/${APPNAME}.xcarchive"
APP_DIR="$ARCHIVE_PATH/Products/Applications"
DSYM_DIR="$ARCHIVE_PATH/dSYMs"
mkdir -p $ARCHIVE_PATH

echo "********************"
echo "*     Archive      *"
echo "********************"
xcodebuild -scheme "$XCODE_SCHEME" -workspace "$XCODE_WORKSPACE" -archivePath "$ARCHIVE_PATH" clean archive CODE_SIGN_IDENTITY="$DEVELOPER_NAME"

echo "********************"
echo "*     Signing      *"
echo "********************"
xcrun -log -sdk iphoneos PackageApplication "$APP_DIR/$APPNAME.app" -o "$CIRCLE_ARTIFACTS/$APPNAME.ipa" -sign "$DEVELOPER_NAME" -embed "$PROVISIONING_PROFILE"

zip -r -9 "$CIRCLE_ARTIFACTS/$APPNAME.app.dSYM.zip" "$DSYM_DIR/$APPNAME.app.dSYM"
