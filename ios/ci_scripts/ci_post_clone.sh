#!/bin/sh
set -e

# Xcode Cloud post-clone script
# Runs after repository clone, before the build starts.
# Installs CocoaPods dependencies so Pods/ is available during build.

echo "--- Installing CocoaPods dependencies ---"

# Ensure 'pod' is available (Xcode Cloud images include it, but just in case)
if ! command -v pod >/dev/null 2>&1; then
    echo "CocoaPods not found, installing..."
    sudo gem install cocoapods --no-document
fi

# CI_WORKSPACE is the full path to the .xcworkspace file, e.g.:
#   /Volumes/workspace/repository/ios/FlowerLines.xcworkspace
# So we need dirname to get the ios/ directory where Podfile lives.
cd "$(dirname "$CI_WORKSPACE")"

pod install --repo-update

echo "--- pod install complete ---"
