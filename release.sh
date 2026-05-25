#!/bin/bash
set -euo pipefail

VERSION=$(grep -o '[0-9]*' BrowserRouter/Version.swift)
TAG="v${VERSION}.0.0"

echo "Releasing $TAG"
git tag "$TAG"
git push origin main --tags
echo "Done. GitHub Actions will create the release."
