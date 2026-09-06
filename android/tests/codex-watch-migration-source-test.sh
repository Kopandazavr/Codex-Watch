#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_GRADLE="$ROOT/app/build.gradle.kts"
WEAR_GRADLE="$ROOT/wear/build.gradle.kts"
STRINGS="$ROOT/app/src/main/res/values/strings.xml"
BUILD="$ROOT/build.sh"
WORKFLOW="$ROOT/../.github/workflows/build-apk.yml"
PARSER="$ROOT/app/src/main/java/dev/bennett/codexmeter/GitHubReleaseParser.java"
BRANDING="$ROOT/app/src/main/java/dev/bennett/codexmeter/Branding.java"
HOME_VERSION="$ROOT/app/src/main/java/dev/bennett/codexmeter/HomeVersionLabel.java"
APP_CLASS="$ROOT/app/src/main/java/dev/bennett/codexmeter/CodexMeterApplication.java"

# Product identity and installed-app identity.
grep -Fq 'applicationId = "dev.kopandazavr.codexwatch"' "$APP_GRADLE"
grep -Fq 'applicationId = "dev.kopandazavr.codexwatch"' "$WEAR_GRADLE"
! grep -Fq 'applicationId = "dev.bennett.codexmeter"' "$APP_GRADLE"
! grep -Fq 'applicationId = "dev.bennett.codexmeter"' "$WEAR_GRADLE"
grep -Fq '<string name="app_name">Codex Watch</string>' "$STRINGS"
grep -Fq 'Codex Watch contains no analytics SDK' "$STRINGS"
grep -Fq 'private static final String PRODUCT_NAME = "Codex Watch"' "$BRANDING"
grep -Fq 'Branding.apply(activity);' "$APP_CLASS"
grep -Fq 'private static final String HOME_TITLE = "Codex Watch"' "$HOME_VERSION"

# Fork versioning remains on the established 2.9.x line.
grep -Fq 'versionName = "2.9.0"' "$APP_GRADLE"
grep -Fq 'versionCode = 31' "$APP_GRADLE"
grep -Fq 'versionName = "2.9.0"' "$WEAR_GRADLE"
grep -Fq 'versionCode = 31' "$WEAR_GRADLE"

# Updater/release/artifact identity follows the new repository and product name.
grep -Fq 'https://api.github.com/repos/Kopandazavr/Codex-Watch/releases?per_page=30' "$APP_GRADLE"
grep -Fq 'String expectedApk = "CodexWatch-"' "$PARSER"
grep -Fq 'releaseName = "Codex Watch " + version.normalized();' "$PARSER"
grep -Fq 'OUT="$DIST/CodexWatch-$VERSION_NAME.apk"' "$BUILD"
grep -Fq 'WEAR_OUT="$DIST/CodexWatch-Wear-$VERSION_NAME.apk"' "$BUILD"
grep -Fq 'name: Build Codex Watch APK' "$WORKFLOW"
grep -Fq 'name: codex-watch-${{ steps.version.outputs.name }}-ci' "$WORKFLOW"
grep -Fq 'release-dist/CodexWatch-Wear-$VERSION_NAME.apk#Codex Watch Wear OS $VERSION_NAME APK' "$WORKFLOW"
grep -Fq -- '--title "Codex Watch $VERSION_NAME"' "$WORKFLOW"

echo 'Codex Watch migration source contract PASS'
