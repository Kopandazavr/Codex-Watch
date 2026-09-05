#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/app/src/main/java/dev/bennett/codexmeter"

# Finished watchdogs become durable per-role idle state instead of disappearing.
grep -q 'recentlyFinished' "$SRC/CalendarProcessReader.java"
grep -q 'IdleProcessState.synchronize' "$SRC/DualUsageNotificationManager.java"
grep -q 'dismissedThroughMillis' "$SRC/IdleProcessState.java"
grep -q 'row.reminderEnabled = !row.reminderEnabled' "$SRC/IdleProcessState.java"

# DESCRIPTION parsing accepts both canonical newline-separated metadata and provider-flattened
# whitespace-separated key=value pairs so explicit role/topic survive local Calendar sync.
grep -q 'METADATA_PAIR' "$SRC/CalendarProcess.java"
grep -q 'Matcher matcher = METADATA_PAIR.matcher' "$SRC/CalendarProcess.java"
test -f "$ROOT/tests/CalendarProcessSelfTest.java"

# Future watchdogs are observed before BEGIN and persisted into idle lifecycle state. Once a known
# event disappears, deletion is an early completion even if the event never reached the active list.
grep -q 'static List<CalendarProcess> observed' "$SRC/CalendarProcessReader.java"
grep -q 'CalendarProcessReader.observed(context, now)' "$SRC/DualUsageNotificationManager.java"
grep -q 'CalendarProcessReader.active(observed, now)' "$SRC/DualUsageNotificationManager.java"
grep -q 'CalendarProcessReader.recentlyFinished(observed, now)' "$SRC/DualUsageNotificationManager.java"
grep -q 'synchronize(context, processes, finished, observed, now)' "$SRC/DualUsageNotificationManager.java"
grep -q 'List<CalendarProcess> recentlyFinished, List<CalendarProcess> observed' "$SRC/IdleProcessState.java"
grep -q 'rememberObserved(row, process)' "$SRC/IdleProcessState.java"

# Once an event has been observed, deleting it is an early completion rather than waiting for the
# stale scheduled END. Provider failures remain fail-safe (not false completion).
grep -q 'static boolean eventExists' "$SRC/CalendarProcessReader.java"
grep -q 'CalendarContract.Events.CONTENT_URI' "$SRC/CalendarProcessReader.java"
grep -q '!CalendarProcessReader.eventExists(context, row.pendingEventId)' "$SRC/IdleProcessState.java"
grep -q 'watchdog_deleted_early' "$SRC/IdleProcessState.java"

# Every process-notification mode has a useful collapsed summary. Combined mode surfaces it inside
# the usage card; grouped / one-each use a compact summary view plus the full expanded row layout.
grep -q 'static String collapsedSummary' "$SRC/ProcessNotificationManager.java"
grep -q 'process.remainingPercent(nowMillis)' "$SRC/ProcessNotificationManager.java"
grep -q 'R.layout.notification_processes_expanded' "$SRC/ProcessNotificationManager.java"
grep -q 'setCustomContentView(compact)' "$SRC/ProcessNotificationManager.java"
grep -q 'setCustomBigContentView(expanded)' "$SRC/ProcessNotificationManager.java"
grep -q 'ProcessNotificationManager.collapsedSummary' "$SRC/DualUsageNotificationManager.java"
grep -q 'notification_process_summary' "$ROOT/app/src/main/res/layout/notification_processes.xml"
grep -q 'notification_process_summary' "$ROOT/app/src/main/res/layout/notification_processes_expanded.xml"
grep -q 'notification_process_summary' "$ROOT/app/src/main/res/layout/notification_usage_dual_bars.xml"

# Cadence stays intentionally bounded to the approved 5/10 minute choices.
grep -q 'idle_reminder_cadence_entries' "$ROOT/app/src/main/res/values/settings_arrays.xml"
grep -q '<item>5</item>' "$ROOT/app/src/main/res/values/settings_arrays.xml"
grep -q '<item>10</item>' "$ROOT/app/src/main/res/values/settings_arrays.xml"
grep -q 'DEFAULT_CADENCE_MINUTES = 5' "$SRC/IdleProcessState.java"

# Reminder alarms are keyed per role and stop when the same role becomes active.
grep -q 'ACTION_FIRE' "$SRC/IdleReminderManager.java"
grep -q 'IdleProcessState.isRoleActive' "$SRC/IdleReminderManager.java"
grep -q 'cancelAlarm(context, key)' "$SRC/IdleReminderManager.java"

# Idle rows expose dismiss + bell actions, while overlay taps have explicit strong haptics.
grep -q 'notification_process_dismiss' "$ROOT/app/src/main/res/layout/notification_process_row.xml"
grep -q 'notification_process_reminder' "$ROOT/app/src/main/res/layout/notification_process_row.xml"
grep -q 'FLAG_WATCH_OUTSIDE_TOUCH' "$SRC/IdleReminderOverlayService.java"
grep -q 'VibrationEffect.createOneShot(160L, 255)' "$SRC/IdleReminderOverlayService.java"
grep -q 'IdleReminderOverlayService' "$ROOT/app/src/main/AndroidManifest.xml"
grep -q 'SYSTEM_ALERT_WINDOW' "$ROOT/app/src/main/AndroidManifest.xml"

# Reboot/package replacement restores local reminder scheduling.
grep -q 'IdleReminderManager.restore(context)' "$SRC/BootReceiver.java"

# Current phone-acceptance follow-ups stay source-guarded in the same iteration.
grep -q 'View flexibleTop = new View(this)' "$SRC/OnboardingActivity.java"
grep -q 'new LinearLayout.LayoutParams(-1, 0, 1.0f)' "$SRC/OnboardingActivity.java"
grep -q 'STATUS_YELLOW = 0xFFFFC107' "$SRC/OnboardingActivity.java"
grep -q 'setMatchingTextColor' "$SRC/OnboardingActivity.java"
grep -q 'hasExplicitStyle' "$SRC/ResetAlertPreferences.java"
grep -q 'ensureNotificationFeatureDefault' "$SRC/OnboardingActivity.java"
test -f "$SRC/HomeVersionLabel.java"
grep -q 'Ui.versionName(activity)' "$SRC/HomeVersionLabel.java"
grep -q 'RelativeSizeSpan' "$SRC/HomeVersionLabel.java"
grep -q 'HomeVersionLabel.apply(activity)' "$SRC/CodexMeterApplication.java"
grep -q 'normalizeAutomaticDefaults' "$SRC/CodexMeterApplication.java"
grep -q 'dashboard_reorder_root' "$ROOT/app/src/main/res/xml/preferences_settings.xml"
grep -q 'app:isPreferenceVisible="false"' "$ROOT/app/src/main/res/xml/preferences_settings.xml"

# OneUI HorizontalRadioPreference needs an explicit title and view type at runtime; missing these
# caused the Settings -> Now Bar page to fail during preference inflation on the target Samsung.
NOW_BAR_XML="$ROOT/app/src/main/res/xml/preferences_settings_now_bar.xml"
grep -q 'android:title="Process notifications"' "$NOW_BAR_XML"
grep -q 'app:viewType="noImage"' "$NOW_BAR_XML"

# Run focused pure-Java metadata regression coverage without needing Android framework stubs.
META_OUT="$ROOT/build/calendar-process-metadata-tests"
rm -rf "$META_OUT" && mkdir -p "$META_OUT"
javac -encoding UTF-8 -d "$META_OUT" \
  "$SRC/CalendarProcess.java" \
  "$ROOT/tests/CalendarProcessSelfTest.java"
java -ea -cp "$META_OUT" dev.bennett.codexmeter.CalendarProcessSelfTest

echo 'Idle reminder + phone follow-up source regression contract passed.'
