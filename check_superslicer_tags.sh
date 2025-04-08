#!/bin/bash
# Trigger publishing a new package if SuperSlicer generates a new pre-release or release

set -eu

# ** start of configurable variables **

# Where to find SuperSlicer releases
LATEST_RELEASE="https://api.github.com/repos/supermerill/SuperSlicer/releases/latest"
ALL_RELEASES="https://api.github.com/repos/supermerill/SuperSlicer/releases"

# Local repo name 
PKG_NAME="superslicer-vnc"

# ** end of configurable variables **

# Get the latest tagged version from the SuperSlicer repo
TMPDIR="$(mktemp -d)"

curl -SsL ${LATEST_RELEASE} > $TMPDIR/latest.json
curl -SsL  ${ALL_RELEASES} > $TMPDIR/allreleases.json

# Filter the release that has "prerelease": true
release=$(jq -c '.[] | select(.prerelease == true)' $TMPDIR/allreleases.json)

LATEST_VERSION=$(jq -r .tag_name $TMPDIR/latest.json)
PRERELEASE_VERSION=$(echo "$release" | jq -r '.tag_name' | head -n 1)

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

# Function to compare version numbers: returns true only if $1 > $2
version_greater() {
  if [[ "$1" == "$2" ]]; then
    return 1
  fi
  [[ "$(printf '%s\n' "$1" "$2" | sort -V | head -n 1)" != "$1" ]]
}

# Check if the latest release version is greater than the local latest package tag
if version_greater "$LATEST_VERSION" "$LATEST_PKG_TAG"; then
  echo "New stable release found! Updating latest package from ${LATEST_PKG_TAG} to ${LATEST_VERSION}"
  gh workflow run publish_release.yml
else
  echo "No new stable release detected."
fi

# Check if the latest pre-release version is greater than the local pre-release package tag
if version_greater "$PRERELEASE_VERSION" "$PRERELEASE_PKG_TAG"; then
  echo "New pre-release found! Updating pre-release package from ${PRERELEASE_PKG_TAG} to ${PRERELEASE_VERSION}"
  gh workflow run publish_prerelease.yml
else
  echo "No new pre-release detected."
fi

exit 0