import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/database/preferences_service.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/providers.dart';
import '../models/friction_event.dart';
import 'friction_settings_provider.dart';

/// Immutable state for the friction overlay system.
class FrictionState {
  /// Whether a friction overlay is currently displayed.
  final bool isActive;

  /// The type of friction being shown.
  final FrictionType currentFrictionType;

  /// Package name of the app that triggered friction.
  final String currentPackageName;

  /// Human-readable name of the app that triggered friction.
  final String currentAppName;

  /// Seconds remaining on the current timer (wait/breath).
  final int remainingSeconds;

  /// Total duration for the current friction (for progress calculation).
  final int totalSeconds;

  /// Number of consecutive opens for escalation.
  final int consecutiveOpens;

  /// Number of times the app has been opened today (for grace period).
  final int dailyOpenCount;

  /// The intention the user selected (for intention-type friction).
  final IntentionType? selectedIntention;

  /// Whether the friction exercise/timer is complete and the user may proceed.
  final bool isCompleted;

  /// The timestamp when friction started, used for duration logging.
  final DateTime? startedAt;

  const FrictionState({
    this.isActive = false,
    this.currentFrictionType = FrictionType.wait,
    this.currentPackageName = '',
    this.currentAppName = '',
    this.remainingSeconds = 0,
    this.totalSeconds = 0,
    this.consecutiveOpens = 0,
    this.dailyOpenCount = 0,
    this.selectedIntention,
    this.isCompleted = false,
    this.startedAt,
  });

  FrictionState copyWith({
    bool? isActive,
    FrictionType? currentFrictionType,
    String? currentPackageName,
    String? currentAppName,
    int? remainingSeconds,
    int? totalSeconds,
    int? consecutiveOpens,
    int? dailyOpenCount,
    IntentionType? selectedIntention,
    bool? isCompleted,
    DateTime? startedAt,
    bool clearIntention = false,
    bool clearStartedAt = false,
  }) {
    return FrictionState(
      isActive: isActive ?? this.isActive,
      currentFrictionType: currentFrictionType ?? this.currentFrictionType,
      currentPackageName: currentPackageName ?? this.currentPackageName,
      currentAppName: currentAppName ?? this.currentAppName,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      consecutiveOpens: consecutiveOpens ?? this.consecutiveOpens,
      dailyOpenCount: dailyOpenCount ?? this.dailyOpenCount,
      selectedIntention:
          clearIntention ? null : (selectedIntention ?? this.selectedIntention),
      isCompleted: isCompleted ?? this.isCompleted,
      startedAt:
          clearStartedAt ? null : (startedAt ?? this.startedAt),
    );
  }
}

/// Manages the friction overlay lifecycle: starting, ticking, completing,
/// and logging friction events.
class FrictionNotifier extends StateNotifier<FrictionState> {
  final DatabaseHelper _db;
  final PreferencesService _prefs;
  final FrictionSettingsNotifier _settings;

  Timer? _timer;

  /// Tracks daily opens per package. Key: packageName, Value: open count.
  /// Resets when the date changes.
  final Map<String, int> _dailyOpens = {};

  /// Tracks consecutive opens per package for escalation.
  final Map<String, int> _consecutiveOpens = {};

  /// The date for which [_dailyOpens] is valid.
  DateTime _currentDay = DateTime.now();

  FrictionNotifier({
    required DatabaseHelper db,
    required PreferencesService prefs,
    required FrictionSettingsNotifier settings,
  })  : _db = db,
        _prefs = prefs,
        _settings = settings,
        super(const FrictionState());

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Called when a monitored app is opened. Decides whether to show friction
  /// and, if so, which type.
  ///
  /// Returns `true` if friction was started, `false` if skipped (grace period).
  Future<bool> handleAppOpen(String packageName, String appName) async {
    _resetDayIfNeeded();

    // Increment daily open count for this app.
    _dailyOpens[packageName] = (_dailyOpens[packageName] ?? 0) + 1;
    final opens = _dailyOpens[packageName]!;

    // Grace period check (FRIC-06): first N opens per day skip friction.
    final gracePeriod = _prefs.gracePeriodCount;
    if (opens <= gracePeriod) {
      return false;
    }

    // Determine friction type for this app (FRIC-05).
    final frictionType =
        await _settings.getFrictionTypeForApp(packageName);

    // Update consecutive opens for escalation.
    _consecutiveOpens[packageName] =
        (_consecutiveOpens[packageName] ?? 0) + 1;

    await startFriction(
      frictionType,
      packageName,
      appName,
      _consecutiveOpens[packageName]!,
      opens,
    );
    return true;
  }

  /// Starts a friction overlay of the given [type] for [packageName].
  Future<void> startFriction(
    FrictionType type,
    String packageName,
    String appName,
    int consecutiveOpens,
    int dailyOpenCount,
  ) async {
    _timer?.cancel();

    final escalationEnabled = _settings.state.escalationEnabled;

    int totalSeconds;
    switch (type) {
      case FrictionType.wait:
        // FRIC-01: Start at 5s, escalate +5s per consecutive open, max 30s.
        if (escalationEnabled) {
          totalSeconds = (consecutiveOpens * 5).clamp(5, 30);
        } else {
          totalSeconds = 5;
        }
        break;
      case FrictionType.breath:
        // FRIC-02: Fixed 15s breathing exercise.
        totalSeconds = 15;
        break;
      case FrictionType.intention:
        // FRIC-03: No timer, completes when user selects intention.
        totalSeconds = 0;
        break;
    }

    state = FrictionState(
      isActive: true,
      currentFrictionType: type,
      currentPackageName: packageName,
      currentAppName: appName,
      remainingSeconds: totalSeconds,
      totalSeconds: totalSeconds,
      consecutiveOpens: consecutiveOpens,
      dailyOpenCount: dailyOpenCount,
      isCompleted: type == FrictionType.intention ? false : totalSeconds == 0,
      startedAt: DateTime.now(),
    );

    // Start countdown for timed friction types.
    if (totalSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }

  /// Countdown tick for wait timer and breathing exercise.
  void tick() {
    if (!state.isActive || state.remainingSeconds <= 0) {
      _timer?.cancel();
      return;
    }

    final next = state.remainingSeconds - 1;
    if (next <= 0) {
      _timer?.cancel();
      state = state.copyWith(remainingSeconds: 0, isCompleted: true);
    } else {
      state = state.copyWith(remainingSeconds: next);
    }
  }

  /// User chose "Give Up" -- close the friction overlay and log the event.
  Future<void> dismissFriction() async {
    _timer?.cancel();

    // Reset consecutive opens since the user gave up (broke the chain).
    _consecutiveOpens[state.currentPackageName] = 0;

    await _logFrictionEvent(FrictionAction.gaveUp);

    // Update daily_stats friction_dismissed count.
    await _incrementDailyStat('friction_dismissed');

    state = const FrictionState();
  }

  /// User chose "Open Anyway" -- allow through and log the event.
  Future<void> proceedAnyway() async {
    _timer?.cancel();

    await _logFrictionEvent(FrictionAction.proceededAnyway);

    // Update daily_stats friction_bypassed count.
    await _incrementDailyStat('friction_bypassed');

    state = const FrictionState();
  }

  /// User selected an intention (for intention-type friction -- FRIC-03).
  void selectIntention(IntentionType intention) {
    state = state.copyWith(
      selectedIntention: intention,
      isCompleted: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Resets [_dailyOpens] if the calendar date has changed since last check.
  void _resetDayIfNeeded() {
    final now = DateTime.now();
    if (now.year != _currentDay.year ||
        now.month != _currentDay.month ||
        now.day != _currentDay.day) {
      _dailyOpens.clear();
      _consecutiveOpens.clear();
      _currentDay = now;
    }
  }

  /// Logs a friction event to the database.
  Future<void> _logFrictionEvent(FrictionAction action) async {
    if (_db.isStub) return;

    final duration = state.startedAt != null
        ? DateTime.now().difference(state.startedAt!).inSeconds
        : 0;

    final event = FrictionEvent(
      packageName: state.currentPackageName,
      appName: state.currentAppName,
      frictionType: state.currentFrictionType,
      timestamp: DateTime.now(),
      userAction: action,
      intention: state.selectedIntention,
      durationSeconds: duration,
    );

    final db = await _db.database;

    // Log to friction_events table.
    await db.insert('friction_events', event.toMap()..remove('id'));

    // If an intention was selected, also log to intention_logs.
    if (state.selectedIntention != null) {
      await db.insert('intention_logs', {
        'timestamp': DateTime.now().toIso8601String(),
        'app_package': state.currentPackageName,
        'intention_type': state.selectedIntention!.index,
        'did_proceed': action == FrictionAction.proceededAnyway ? 1 : 0,
        'session_duration': duration,
      });
    }
  }

  /// Increments a counter column in the daily_stats row for today.
  Future<void> _incrementDailyStat(String column) async {
    if (_db.isStub) return;
    final db = await _db.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Ensure a row exists for today.
    await db.insert(
      'daily_stats',
      {'date': today, column: 1},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // Increment the column and also friction_shown.
    await db.rawUpdate(
      'UPDATE daily_stats SET $column = $column + 1, '
      'friction_shown = friction_shown + 1 '
      'WHERE date = ?',
      [today],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Global provider for friction state management.
final frictionProvider =
    StateNotifierProvider<FrictionNotifier, FrictionState>((ref) {
  return FrictionNotifier(
    db: ref.watch(databaseProvider),
    prefs: ref.watch(preferencesServiceProvider),
    settings: ref.watch(frictionSettingsProvider.notifier),
  );
});
