package dev.bennett.codexmeter;

/** Focused regression coverage for watchdog metadata and canonical work timing. */
public final class CalendarProcessSelfTest {
    private CalendarProcessSelfTest() {
    }

    public static void main(String[] args) {
        testMultilineMetadata();
        testFlattenedMetadata();
        testUnsupportedMetadataFallsBackSoft();
        testCanonicalWorkWindow();
        System.out.println("CalendarProcess metadata/timing self-test passed.");
    }

    private static void testMultilineMetadata() {
        CalendarProcess process = CalendarProcess.fromEvent(
                42L,
                "GPT_WATCHDOG|urgent|Codex Watch",
                "codex_meter_watchdog=v1\n"
                        + "project=Codex Watch\n"
                        + "role=Codex Meter Project Agent\n"
                        + "topic=phone acceptance cleanup",
                1_000L,
                2_000L);
        require(process != null, "multiline process parsed");
        require("Codex Watch".equals(process.project), "multiline project");
        require("Codex Meter Project Agent".equals(process.role), "multiline role");
        require("phone acceptance cleanup".equals(process.topic), "multiline topic");
    }

    private static void testFlattenedMetadata() {
        CalendarProcess process = CalendarProcess.fromEvent(
                43L,
                "GPT_WATCHDOG|urgent|Codex Watch",
                "codex_meter_watchdog=v1 project=Codex Watch "
                        + "role=Planning / Review / Acceptance "
                        + "topic=bounded scope planning",
                3_000L,
                4_000L);
        require(process != null, "flattened process parsed");
        require("Codex Watch".equals(process.project), "flattened project");
        require("Planning / Review / Acceptance".equals(process.role), "flattened role");
        require("bounded scope planning".equals(process.topic), "flattened topic");
    }

    private static void testUnsupportedMetadataFallsBackSoft() {
        CalendarProcess process = CalendarProcess.fromEvent(
                44L,
                "GPT_WATCHDOG|urgent|Title fallback",
                "codex_meter_watchdog=v2 project=Wrong role=Wrong topic=Wrong",
                5_000L,
                6_000L);
        require(process != null, "unsupported metadata still yields title-only watchdog");
        require("Title fallback".equals(process.project), "title fallback project");
        require(process.role.isEmpty(), "unsupported metadata role ignored");
        require(process.topic.isEmpty(), "unsupported metadata topic ignored");
    }

    private static void testCanonicalWorkWindow() {
        long begin = CalendarProcess.ACTIVE_WORK_WINDOW_MS;
        long end = begin + 5L * 60_000L;
        CalendarProcess process = CalendarProcess.fromEvent(
                45L,
                "GPT_WATCHDOG|urgent|Codex Watch",
                "codex_meter_watchdog=v1 project=Codex Watch role=Developer topic=implementation",
                begin,
                end);
        require(process != null, "timed process parsed");
        require(process.workStartMillis() == 0L, "work starts 27 minutes before BEGIN");
        require(process.isVisibleActive(1L), "future watchdog is visible during work interval");
        require(process.isWorkRunning(1L), "pre-BEGIN phase is work-running");
        require(process.remainingPercent(0L) == 100, "work starts at 100 percent remaining");
        require(process.remainingPercent(begin / 2L) == 50, "work midpoint is 50 percent remaining");
        require(process.remainingMillis(begin / 2L) == begin / 2L,
                "work remaining targets BEGIN");
        require(process.isWatchdogActive(begin), "BEGIN enters watchdog window");
        require(process.remainingPercent(begin) == 100,
                "watchdog fallback window retains its own progress semantics");
        require(process.remainingMillis(begin) == end - begin,
                "post-BEGIN remaining targets END");
        require(!process.isVisibleActive(end), "process is no longer active at END");
    }

    private static void require(boolean condition, String label) {
        if (!condition) throw new AssertionError(label);
    }
}