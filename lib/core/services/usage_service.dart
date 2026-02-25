import 'platform_channel.dart';

/// Represents usage data for a single app.
class AppUsageInfo {
  /// The app's package identifier (e.g. `com.instagram.android`).
  final String packageName;

  /// Human-readable app name (e.g. "Instagram").
  final String appName;

  /// Total usage time in milliseconds for the queried period.
  final int usageTimeMs;

  /// Number of times the app was opened in the queried period.
  final int openCount;

  /// Timestamp (ms since epoch) of the last time the app was used.
  final int lastUsed;

  const AppUsageInfo({
    required this.packageName,
    required this.appName,
    required this.usageTimeMs,
    required this.openCount,
    required this.lastUsed,
  });

  /// Creates an [AppUsageInfo] from a platform channel map.
  factory AppUsageInfo.fromMap(Map<String, dynamic> map) {
    return AppUsageInfo(
      packageName: map['packageName'] as String? ?? '',
      appName: map['appName'] as String? ?? '',
      usageTimeMs: map['usageTime'] as int? ?? 0,
      openCount: map['openCount'] as int? ?? 0,
      lastUsed: map['lastUsed'] as int? ?? 0,
    );
  }

  /// Returns usage time as a [Duration].
  Duration get usageDuration => Duration(milliseconds: usageTimeMs);

  /// Returns [lastUsed] as a [DateTime].
  DateTime get lastUsedTime =>
      DateTime.fromMillisecondsSinceEpoch(lastUsed);

  @override
  String toString() =>
      'AppUsageInfo($appName, ${usageDuration.inMinutes}min, $openCount opens)';
}

/// High-level abstraction over app usage data collection.
///
/// Wraps [PlatformChannelService] to provide convenient query methods
/// for screen time and per-app usage statistics.
class UsageService {
  final PlatformChannelService _platform;

  UsageService(this._platform);

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns usage data for today (midnight to now).
  Future<List<AppUsageInfo>> getUsageForToday() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return getUsageForRange(midnight, now);
  }

  /// Returns usage data for a custom date range.
  Future<List<AppUsageInfo>> getUsageForRange(
    DateTime start,
    DateTime end,
  ) async {
    final rawData = await _platform.getUsageStats(
      startTime: start.millisecondsSinceEpoch,
      endTime: end.millisecondsSinceEpoch,
    );
    return rawData.map((map) => AppUsageInfo.fromMap(map)).toList();
  }

  /// Returns total screen time for today as a [Duration].
  Future<Duration> getTotalScreenTimeToday() async {
    final usage = await getUsageForToday();
    final totalMs =
        usage.fold<int>(0, (sum, info) => sum + info.usageTimeMs);
    return Duration(milliseconds: totalMs);
  }

  /// Returns the top [count] apps by usage time for today.
  ///
  /// Results are sorted in descending order by usage time.
  Future<List<AppUsageInfo>> getTopApps(int count) async {
    final usage = await getUsageForToday();
    usage.sort((a, b) => b.usageTimeMs.compareTo(a.usageTimeMs));
    return usage.take(count).toList();
  }

  /// Returns the list of installed apps with metadata.
  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    return _platform.getInstalledApps();
  }
}
