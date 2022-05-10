#!/bin/sh
realApp="%APPLICATION"
destfolder="%DESTINATION"

STREAMERPATH="$destfolder/$realApp.app"

exec "$STREAMERPATH/Contents/MacOS/$realApp" "-serviceUtil" "$@"
