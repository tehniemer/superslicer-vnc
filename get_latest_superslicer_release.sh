#!/bin/bash

TMPDIR="$(mktemp -d)"

curl -SsL https://api.github.com/repos/supermerill/SuperSlicer/releases/latest > $TMPDIR/latest.json

if [[ ! -e "$TMPDIR/latestReleaseInfo.json" ]]; then

  curl -SsL https://api.github.com/repos/supermerill/SuperSlicer/releases/latest > $TMPDIR/latestReleaseInfo.json

fi

releaseInfo=$(cat $TMPDIR/latestReleaseInfo.json)

if [[ $# -gt 1 ]]; then

  VER=$2

  if [[ ! -e "$TMPDIR/releases.json" ]]; then
    curl -SsL https://api.github.com/repos/supermerill/SuperSlicer/releases > $TMPDIR/releases.json
  fi

  allReleases=$(cat $TMPDIR/releases.json)

fi

if [[ "$1" == "url" ]]; then

  echo "${releaseInfo}" | jq -r '.assets[] | .browser_download_url | select(test("SuperSlicer_.+(-\\w)?.linux64_(?!GTK3).+.tar.zip"))'

elif [[ "$1" == "name" ]]; then

  echo "${releaseInfo}" | jq -r '.assets[] | .name | select(test("SuperSlicer_.+(-\\w)?.linux64_(?!GTK3).+.tar.zip"))'

elif [[ "$1" == "url_ver" ]]; then

  # Note: Releases sometimes have hex-encoded ascii characters tacked on
  # So version '2.0.0+' might need to be requested as '2.0.0%2B' since GitHub returns that as the download URL
  echo "${allReleases}" | jq --arg VERSION "$VER" -r '.[] | .assets[] | .browser_download_url | select(test("SuperSlicer_" + $VERSION + "linux64_.+.tar.zip"))'

elif [[ "$1" == "name_ver" ]]; then
   
  echo "${allReleases}" | jq --arg VERSION "$VER" -r '.[] | .assets[] | .name | select(test("SuperSlicer_" + $VERSION + "\\+linux64_.+.tar.zip"))'

fi
