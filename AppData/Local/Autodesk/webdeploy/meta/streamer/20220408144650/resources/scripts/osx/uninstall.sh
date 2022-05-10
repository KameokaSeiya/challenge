#!/bin/sh

STREAMERSDIR="$HOME/Library/Application Support/Autodesk/webdeploy/meta/streamer"

for ver in $(ls "${STREAMERSDIR}" | sort -r); do
    STREAMERPATH="${STREAMERSDIR}/${ver}/streamer"
    if [ -x "$STREAMERPATH" ]; then
        break
    fi
    STREAMERPATH=""
done


if [ -n "$STREAMERPATH" ]; then
    "$STREAMERPATH" -p uninstall -a %APPID  -s %STREAMTAG $*
fi
