#!/bin/bash
# Push a tag for our repository if upstream SuperSlicer generates a new release
# This was forked from https://github.com/dmagyar/prusaslicer-vnc-docker/blob/main/tagLatestPrusaSlicer.sh

set -eu

# ** start of configurable variables **

# Where to find SuperSlicer releases
LATEST_RELEASE="https://api.github.com/repos/supermerill/SuperSlicer/releases/latest"
ALL_RELEASES="https://api.github.com/repos/supermerill/SuperSlicer/releases"

# ** end of configurable variables **

# Get the latest tagged version from the SuperSlicer repo
LATEST_VERSION="$(curl -SsL ${LATEST_RELEASE} | jq -r '.tag_name')"
PRERELEASE_VERSION="$(curl -SsL ${ALL_RELEASES} | jq -r '[.[] | select(.target_commitish == "rc" and .prerelease == true)] | sort_by(.created_at) | reverse | .[0].tag_name')"

if [[ -z "${LATEST_VERSION}" || -z "${PRERELEASE_VERSION}" ]]; then
  echo "Could not determine version number(s)."
  echo "Has release naming changed from previous conventions?"
  exit 1
fi

# Run from the git repository
cd "$(dirname "$0")";

# Fetch all package tags (not just release tags)
git fetch --tags

# Get the latest package tag (sorted by creation date)
LATEST_PKG_TAG=$(git tag --sort=-creatordate | grep -E "latest" | head -n 1 || echo "")

# Get the latest prerelease package tag (matching 'rc' or prerelease pattern)
PRERELEASE_PKG_TAG=$(git tag --sort=-creatordate | grep -E "prerelease" | head -n 1 || echo "")

# Function to compare version numbers
version_greater() {
  [[ "$(printf '%s\n' "$@" | sort -V | tail -n 1)" == "$1" ]]
}

# Check if the latest release version is greater than the local latest package tag
if [[ -n "$LATEST_VERSION" && -n "$LATEST_PKG_TAG" && version_greater "$LATEST_VERSION" "$LATEST_PKG_TAG" ]]; then
  echo "New stable release found! Updating latest package from ${LATEST_PKG_TAG} to ${LATEST_VERSION}"
  gh workflow run publish_release.yml
else
  echo "No new stable release detected."
fi

# Check if the latest prerelease version is greater than the local prerelease package tag
if [[ -n "$PRERELEASE_VERSION" && -n "$PRERELEASE_PKG_TAG" && version_greater "$PRERELEASE_VERSION" "$PRERELEASE_PKG_TAG" ]]; then
  echo "New prerelease found! Updating prerelease package from ${PRERELEASE_PKG_TAG} to ${PRERELEASE_VERSION}"
  gh workflow run publish_prerelease.yml
else
  echo "No new prerelease detected."
fi

exit 0