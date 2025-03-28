#!/bin/bash
# Get the latest release of SuperSlicer for Linux (non-AppImage) using the GitHub API
# This was forked from https://github.com/dmagyar/prusaslicer-vnc-docker/blob/main/getLatestPrusaSlicerRelease.sh

set -eu

if [[ $# -lt 1 ]]; then
  echo "~~~ $0 ~~~"
  echo "	usage: $0 [ url | name | url_ver VERSION | name_ver VERSION_NAME ]"
  echo
  echo "	url: Returns the download URL for the latest release (for download using cURL/wget)"
  echo "	name: Returns the filename of the latest release"
  echo 
  echo "	url_ver: Takes a parameter to specify the version to retrieve (note: some download urls have hex-encoded ascii characters)"
  echo "	url_ver example: $0 url_ver 2.0.0%2B"
  echo "	output: https://github.com/supermerill/SuperSlicer/releases/download/2.3.57.10/SuperSlicer_2.3.57.10_linux64_220203.tar.zip"
  echo
  echo "	name_ver: Takes a parameter to specify the filename to retrieve (note: this has a '+' added on at the end of the provided version number)"
  echo "	name_ver example: $0 name_ver 2.0.0"
  echo "	output: SuperSlicer_2.3.57.10_linux64_220203.tar.zip"
  echo
  exit 1
fi

TMPDIR="$(mktemp -d)"

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

  echo "${releaseInfo}" | jq -r '.assets[] | .browser_download_url | select(test("SuperSlicer-ubuntu_20.04-gtk2.*AppImage$"))'

elif [[ "$1" == "name" ]]; then

  echo "${releaseInfo}" | jq -r '.assets[] | .name | select(test("SuperSlicer-ubuntu_20.04-gtk2.*AppImage$"))'

elif [[ "$1" == "url_ver" ]]; then

  # Note: Releases sometimes have hex-encoded ascii characters tacked on
  # So version '2.0.0+' might need to be requested as '2.0.0%2B' since GitHub returns that as the download URL
  echo "${allReleases}" | jq --arg VERSION "$VER" -r '.[] | .assets[] | .browser_download_url | select(test("^SuperSlicer-ubuntu_[0-9]{2}\.[0-9]{2}(-(?!gtk3)\w+)?-${VERSION}\.AppImage$"))'

elif [[ "$1" == "name_ver" ]]; then
   
  echo "${allReleases}" | jq --arg VERSION "$VER" -r '.[] | .assets[] | .name | select(test("^SuperSlicer-ubuntu_[0-9]{2}\.[0-9]{2}(-(?!gtk3)\w+)?-${VERSION}\.AppImage$"))'

fi
