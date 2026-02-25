import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/models/app_group.dart';
import '../../../core/providers/providers.dart';
import '../models/daily_limit.dart';
import 'app_group_provider.dart';
import 'schedule_provider.dart';
import 'strict_mode_provider.dart';

/// Reason why an app is blocked.
enum BlockReason {
  /// Blocked by a time-based schedule (BLCK-01).
  schedule,

  /// Daily time limit reached (BLCK-02).
  dailyLimit,

  /// Strict Mode is active (STRK-02).
  strictMode,

  /// Not blocked.
  none,
}

/// Overall blocking state.
class BlockingState {
  final Map<int, DailyLimit> dailyLimits;
  final bool isLoading;

  /// Date string for which daily limits are valid.
  final String currentDate;

  const BlockingState({
    this.dailyLimits = const {},
    this.isLoading = false,
    this.currentDate = '',
  });

  BlockingState copyWith({
    Map<int, DailyLimit>? dailyLimits,
    bool? isLoading,
    String? currentDate,
  }) {
    return BlockingState(
      dailyLimits: dailyLimits ?? this.dailyLimits,
      isLoading: isLoading ?? this.isLoading,
      currentDate: currentDate ?? this.currentDate,
    );
  }
}

/// Central blocking engine that checks schedules, limits, and strict mode
/// to determine if an app should be blocked.
class BlockingNotifier extends StateNotifier<BlockingState> {
  final DatabaseHelper _db;
  final Ref _ref;

  BlockingNotifier({required DatabaseHelper db, required Ref ref})
      : _db = db,
        _ref = ref,
        super(const BlockingState(isLoading: true)) {
    _loadDailyLimits();
  }

  /// Loads daily limits from the database.
  Future<void> _loadDailyLimits() async {
    state = state.copyWith(isLoading: true);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Reset usage if the date has changed.
    if (state.currentDate.isNotEmpty && state.currentDate != today) {
      await _db.resetAllDailyUsage();
    }

    final rows = await _db.getDailyLimits();
    final limits = <int, DailyLimit>{};
    for (final row in rows) {
      final limit = DailyLimit.fromMap(row);
      limits[limit.groupId] = limit;
    }

    state = BlockingState(
      dailyLimits: limits,
      isLoading: false,
      currentDate: today,
    );
  }

  /// Reloads daily limits from the database.
  Future<void> reload() => _loadDailyLimits();

  /// Checks whether a given app is currently blocked (BLCK-01, BLCK-02, STRK-02).
  bool isAppBlocked(String packageName) {
    return getBlockReason(packageName) != BlockReason.none;
  }

  /// Determines the reason an app is blocked.
  BlockReason getBlockReason(String packageName) {
    final appGroupState = _ref.read(appGroupProvider);
    final scheduleState = _ref.read(scheduleProvider);
    final strictState = _ref.read(strictModeProvider);

    // 1. Check Strict Mode first (highest priority).
    if (strictState.config.isCurrentlyActive()) {
      // In strict mode, check if the app belongs to any group.
      final group = _findGroupForPackage(packageName, appGroupState);
      if (group != null) {
        // Allow emergency bypass.
        if (_ref
            .read(strictModeProvider.notifier)
            .isPackageBypassed(packageName)) {
          return BlockReason.none;
        }
        return BlockReason.strictMode;
      }
    }

    // 2. Check blocking schedules.
    final group = _findGroupForPackage(packageName, appGroupState);
    if (group != null && group.id != null) {
      final schedules = scheduleState.schedules
          .where((s) => s.groupId == group.id!)
          .toList();
      for (final schedule in schedules) {
        if (schedule.isCurrentlyActive()) {
          return BlockReason.schedule;
        }
      }

      // 3. Check daily limits.
      final limit = state.dailyLimits[group.id];
      if (limit != null && limit.isExhausted) {
        return BlockReason.dailyLimit;
      }
    }

    return BlockReason.none;
  }

  /// Returns a human-readable block reason string.
  String getBlockReasonMessage(String packageName) {
    final reason = getBlockReason(packageName);
    switch (reason) {
      case BlockReason.schedule:
        return 'Blocked by schedule';
      case BlockReason.dailyLimit:
        return 'Daily limit reached';
      case BlockReason.strictMode:
        return 'Strict Mode is active';
      case BlockReason.none:
        return '';
    }
  }

  /// Increments daily usage for the group that contains this package.
  Future<void> updateUsage(String packageName, int minutes) async {
    final appGroupState = _ref.read(appGroupProvider);
    final group = _findGroupForPackage(packageName, appGroupState);
    if (group == null || group.id == null) return;

    final limit = state.dailyLimits[group.id];
    if (limit == null) return;

    final newUsage = limit.currentUsageMinutes + minutes;
    await _db.updateDailyLimitUsage(group.id!, newUsage);

    final updatedLimits = Map<int, DailyLimit>.from(state.dailyLimits);
    updatedLimits[group.id!] = limit.copyWith(currentUsageMinutes: newUsage);
    state = state.copyWith(dailyLimits: updatedLimits);
  }

  /// Sets a daily limit for a group.
  Future<void> setDailyLimit({
    required int groupId,
    required int limitMinutes,
    bool isActive = true,
  }) async {
    final limit = DailyLimit(
      groupId: groupId,
      limitMinutes: limitMinutes,
      currentUsageMinutes:
          state.dailyLimits[groupId]?.currentUsageMinutes ?? 0,
      isActive: isActive,
    );
    await _db.upsertDailyLimit(limit.toMap());

    final updatedLimits = Map<int, DailyLimit>.from(state.dailyLimits);
    updatedLimits[groupId] = limit;
    state = state.copyWith(dailyLimits: updatedLimits);
  }

  /// Removes a daily limit for a group.
  Future<void> removeDailyLimit(int groupId) async {
    await _db.deleteDailyLimit(groupId);
    final updatedLimits = Map<int, DailyLimit>.from(state.dailyLimits);
    updatedLimits.remove(groupId);
    state = state.copyWith(dailyLimits: updatedLimits);
  }

  /// Checks if a 5-minute warning should be shown for this package (BLCK-03).
  bool shouldShowWarning(String packageName) {
    final appGroupState = _ref.read(appGroupProvider);
    final group = _findGroupForPackage(packageName, appGroupState);
    if (group == null || group.id == null) return false;

    final limit = state.dailyLimits[group.id];
    return limit != null && limit.isWarning;
  }

  /// Returns daily limit for a group, if any.
  DailyLimit? getDailyLimit(int groupId) => state.dailyLimits[groupId];

  /// Finds which group a package belongs to.
  AppGroup? _findGroupForPackage(
      String packageName, AppGroupState appGroupState) {
    for (final group in appGroupState.groups) {
      final apps = appGroupState.groupApps[group.id] ?? [];
      if (apps.any((a) => a.packageName == packageName)) {
        return group;
      }
    }
    return null;
  }
}

/// Global provider for blocking state management.
final blockingProvider =
    StateNotifierProvider<BlockingNotifier, BlockingState>((ref) {
  return BlockingNotifier(
    db: ref.watch(databaseProvider),
    ref: ref,
  );
});
