# Release Checklist

This project uses semantic versions such as `v0.1.0`.

## Before Release

1. Update `CFBundleShortVersionString` and `CFBundleVersion` in `Packaging/Info.plist`.
2. Add an English entry to `CHANGELOG.md`.
3. Sync the website changelog copy in `docs/i18n.js` for every supported website language.
4. Build and verify locally:

   ```sh
   swift build -c release
   Scripts/package-app.sh
   open build/BlackPoint.app
   ```

5. Run the local install script against a local zip once, then verify the app launches from `/Applications`.
6. Verify the website with headless Chrome screenshots.

## Package

```sh
rm -rf dist
mkdir -p dist
Scripts/package-app.sh
ditto -c -k --keepParent build/BlackPoint.app dist/BlackPoint-macOS.zip
cp dist/BlackPoint-macOS.zip dist/BlackPoint-0.1.0-macOS.zip
shasum -a 256 dist/BlackPoint-0.1.0-macOS.zip > dist/BlackPoint-0.1.0-macOS.zip.sha256
```

## Publish

```sh
git status --short
git add -A
git commit -m "Release BlackPoint 0.1.0"
git push

gh release create v0.1.0 \
  dist/BlackPoint-macOS.zip \
  dist/BlackPoint-0.1.0-macOS.zip \
  dist/BlackPoint-0.1.0-macOS.zip.sha256 \
  --target main \
  --title "BlackPoint 0.1.0" \
  --notes "Initial public release of BlackPoint, a macOS menu bar utility for stowing distracting apps without quitting them."
```

## After Release

1. Confirm `gh release list` marks the release as latest.
2. Confirm `https://github.com/7757/BlackPoint/releases/latest` redirects to the new version.
3. Confirm `https://github.com/7757/BlackPoint/releases/latest/download/BlackPoint-macOS.zip` returns `200`.
4. Confirm GitHub Pages has rebuilt.
5. Confirm `https://7757.github.io/BlackPoint/install.sh` returns the current install script.
6. If a Homebrew tap is added later, update `version` and `sha256` in the cask.
