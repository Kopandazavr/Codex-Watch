package dev.bennett.codexmeter;

import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** One active long-running process represented by a local calendar watchdog event. */
final class CalendarProcess {
    static final String WATCHDOG_PREFIX = "GPT_WATCHDOG|urgent|";
    static final String METADATA_VERSION = "v1";
    private static final Pattern METADATA_PAIR = Pattern.compile(
            "(?is)(?:^|\\s)([a-z0-9_.-]+)\\s*=\\s*(.*?)(?=(?:\\s+[a-z0-9_.-]+\\s*=)|$)");

    final long eventId;
    final long beginMillis;
    final long endMillis;
    final String project;
    final String role;
    final String topic;

    CalendarProcess(long eventId, long beginMillis, long endMillis,
            String project, String role, String topic) {
        this.eventId = eventId;
        this.beginMillis = beginMillis;
        this.endMillis = endMillis;
        this.project = clean(project);
        this.role = clean(role);
        this.topic = clean(topic);
    }

    static CalendarProcess fromEvent(long eventId, String title, String description,
            long beginMillis, long endMillis) {
        if (title == null || !title.startsWith(WATCHDOG_PREFIX)
                || beginMillis <= 0L || endMillis <= beginMillis) {
            return null;
        }
        String titleProject = clean(title.substring(WATCHDOG_PREFIX.length()));
        Map<String, String> metadata = parseMetadata(description);
        String project = valueOr(metadata.get("project"), titleProject);
        String role = metadata.get("role");
        String topic = metadata.get("topic");
        return new CalendarProcess(eventId, beginMillis, endMillis, project, role, topic);
    }

    static Map<String, String> parseMetadata(String description) {
        Map<String, String> values = new LinkedHashMap<>();
        if (description == null || description.trim().isEmpty()) return values;

        // Google Calendar normally preserves line breaks, but some local/sync/provider paths flatten
        // DESCRIPTION into one whitespace-separated line. Parse key=value boundaries instead of
        // assuming exactly one metadata pair per physical line so role/topic survive both forms.
        Matcher matcher = METADATA_PAIR.matcher(description.replace('\r', ' '));
        boolean supported = false;
        while (matcher.find()) {
            String key = clean(matcher.group(1)).toLowerCase(Locale.ROOT);
            String value = clean(matcher.group(2));
            if ("codex_meter_watchdog".equals(key)) {
                supported = METADATA_VERSION.equalsIgnoreCase(value);
            } else if (!value.isEmpty()) {
                values.put(key, value);
            }
        }
        return supported ? values : new LinkedHashMap<>();
    }

    int remainingPercent(long nowMillis) {
        if (nowMillis <= beginMillis) return 100;
        if (nowMillis >= endMillis) return 0;
        long duration = endMillis - beginMillis;
        long remaining = endMillis - nowMillis;
        return (int) Math.max(0L, Math.min(100L,
                Math.round((remaining * 100.0d) / duration)));
    }

    String displayLabel() {
        StringBuilder label = new StringBuilder();
        appendPart(label, project);
        appendPart(label, role);
        appendPart(label, topic);
        return label.length() == 0 ? "Active process" : label.toString();
    }

    String identity() {
        return eventId + ":" + beginMillis;
    }

    private static void appendPart(StringBuilder value, String part) {
        String clean = clean(part);
        if (clean.isEmpty() || "unknown".equalsIgnoreCase(clean)) return;
        if (value.length() > 0) value.append(" · ");
        value.append(clean);
    }

    private static String valueOr(String preferred, String fallback) {
        String cleanPreferred = clean(preferred);
        return cleanPreferred.isEmpty() ? clean(fallback) : cleanPreferred;
    }

    private static String clean(String value) {
        return value == null ? "" : value.trim();
    }
}
