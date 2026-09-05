#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_GRADLE="$ROOT/app/build.gradle.kts"
WEAR_GRADLE="$ROOT/wear/build.gradle.kts"
STRINGS="$ROOT/app/src/main/res/values/strings.xml"
BUILD="$ROOT/build.sh"
WORKFLOW="$ROOT/../.github/workflows/build-apk.yml"

# Product identity and installed-app identity.
grep -Fq 'applicationId = "dev.kopandazavr.codexwatch"' "$APP_GRADLE"
grep -Fq 'applicationId = "dev.kopandazavr.codexwatch"' "$WEAR_GRADLE"
! grep -Fq 'applicationId = "dev.bennett.codexmeter"' "$APP_GRADLE"
! grep -Fq 'applicationId = "dev.bennett.codexmeter"' "$WEAR_GRADLE"
grep -Fq '<string name="app_name">Codex Watch</string>' "$STRINGS"
grep -Fq 'Codex Watch contains no analytics SDK' "$STRINGS"

# Fork versioning remains on the established 2.9.x line.
grep -Fq 'versionName = "2.9.0"' "$APP_GRADLE"
grep -Fq 'versionCode = 31' "$APP_GRADLE"
grep -Fq 'versionName = "2.9.0"' "$WEAR_GRADLE"
grep -Fq 'versionCode = 31' "$WEAR_GRADLE"

# Updater/release/artifact identity follows the new repository and product name.
grep -Fq 'https://api.github.com/repos/Kopandazavr/Codex-Watch/releases?per_page=30' "$APP_GRADLE"
grep -Fq 'OUT="$DIST/CodexWatch-$VERSION_NAME.apk"' "$BUILD"
grep -Fq 'WEAR_OUT="$DIST/CodexWatch-Wear-$VERSION_NAME.apk"' "$BUILD"
grep -Fq 'name: Build Codex Watch APK' "$WORKFLOW"
grep -Fq 'name: codex-watch-${{ steps.version.outputs.name }}-ci' "$WORKFLOW"
grep -Fq 'release-dist/CodexWatch-Wear-$VERSION_NAME.apk#Codex Watch Wear OS $VERSION_NAME APK' "$WORKFLOW"
grep -Fq -- '--title "Codex Watch $VERSION_NAME"' "$WORKFLOW"

echo 'Codex Watch migration source contract PASS'
