#!/bin/bash
# Push a tag for our repository if upstream SuperSlicer generates a new release
# This was forked from https://github.com/dmagyar/prusaslicer-vnc-docker/blob/main/tagLatestPrusaSlicer.sh

set -eu

# ** start of configurable variables **

# Where to find SuperSlicer releases
LATEST_RELEASE="https://api.github.com/repos/supermerill/SuperSlicer/releases/latest"
ALL_RELEASES="https://api.github.com/repos/supermerill/SuperSlicer/releases"

# name 
PKG_NAME="superslicer-vnc"

# ** end of configurable variables **

# Get the latest tagged version from the SuperSlicer repo
TMPDIR="$(mktemp -d)"

curl -SsL ${LATEST_RELEASE} > $TMPDIR/latest.json
curl -SsL  ${ALL_RELEASES} > $TMPDIR/allreleases.json

# Filter the release that has both "target_commitish": "rc" and "prerelease": true
release=$(jq -c '.[] | select(.target_commitish == "rc" and .prerelease == true)' $TMPDIR/allreleases.json)

LATEST_VERSION=$(jq -r .tag_name $TMPDIR/latest.json)
PRERELEASE_VERSION=$(echo "$release" | jq -r '.tag_name')

if [[ -z "${LATEST_VERSION}" || -z "${PRERELEASE_VERSION}" ]]; then
  echo "Could not determine SuperSlicer version number(s)."
  echo "Has release naming changed from previous conventions?"
  exit 1
fi

# Run from the local git repository
cd "$(dirname "$0")";

# Fetch all package tags
gh api -H "Accept: application/vnd.github.v3+json" /user/packages/container/${PKG_NAME}/versions > $TMPDIR/packages.json

# Parse the tags as a JSON array
tags=$(jq -c '.[] | .metadata.container.tags' $TMPDIR/packages.json | jq -s '.')

# Get the version numbers of the published packages
LATEST_PKG_TAG=$(echo "$tags" | jq -r 'map(select(.[0] == "latest")) | .[0][1]')
PRERELEASE_PKG_TAG=$(echo "$tags" | jq -r 'map(select(.[0] == "prerelease")) | .[0][1]')

if [[ -z "${LATEST_PKG_TAG}" || -z "${PRERELEASE_PKG_TAG}" ]]; then
  echo "Could not determine package version number(s)."
  echo "Has tag naming changed from previous conventions?"
  exit 1
fi

# Function to compare version numbers
version_greater() {
  [[ "$(printf '%s\n' "$@" | sort -V | tail -n 1)" == "$1" ]]
}

# Check if the latest release version is greater than the local latest package tag
if version_greater "$LATEST_VERSION" "$LATEST_PKG_TAG"; then
  echo "New stable release found! Updating latest package from ${LATEST_PKG_TAG} to ${LATEST_VERSION}"
  gh workflow run publish_release.yml
else
  echo "No new stable release detected."
fi

# Check if the latest prerelease version is greater than the local prerelease package tag
if version_greater "$PRERELEASE_VERSION" "$PRERELEASE_PKG_TAG"; then
  echo "New prerelease found! Updating prerelease package from ${PRERELEASE_PKG_TAG} to ${PRERELEASE_VERSION}"
  gh workflow run publish_prerelease.yml
else
  echo "No new prerelease detected."
fi

exit 0