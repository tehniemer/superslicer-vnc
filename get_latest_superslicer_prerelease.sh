#!/bin/bash

TMPDIR="$(mktemp -d)"

curl -SsL https://api.github.com/repos/supermerill/SuperSlicer/releases > $TMPDIR/prerelease.json

# Filter the release that has "prerelease": true
release=$(jq -c '.[] | select(.prerelease == true)' $TMPDIR/prerelease.json)

# Extract the first matching AppImage asset from the filtered release
url=$(echo "$release" | jq -r '.assets[] | select(.browser_download_url|test("^(?!.*gtk[0-9]).*SuperSlicer-ubuntu_.*?\\.AppImage$")) | .browser_download_url' | head -n 1)
name=$(echo "$release" | jq -r '.assets[] | select(.browser_download_url|test("^(?!.*gtk[0-9]).*SuperSlicer-ubuntu_.*?\\.AppImage$")) | .name' | head -n 1)
version=$(echo "$release" | jq -r '.tag_name')

if [ $# -ne 1 ]; then
  echo "Wrong number of params"
  exit 1
else
  request=$1
fi

case $request in

  url)
    echo $url
    ;;

  name)
    echo $name
    ;;

  version)
    echo $version
    ;;

  *)
    echo "Unknown request"
    ;;
esac

exit 0
