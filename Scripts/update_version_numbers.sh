#!/bin/bash

APP_VERSION_NUMBER="3.1"

BASE_PLIST="../ScienceJournal/Info.plist"
COMBINED_PLIST="../ScienceJournal/Info-Combined.plist"

echo "Updating version numbers to $APP_VERSION_NUMBER..."
/usr/libexec/PlistBuddy -c "Merge $BASE_PLIST" $COMBINED_PLIST
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $APP_VERSION_NUMBER" $COMBINED_PLIST
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION_NUMBER" $COMBINED_PLIST
