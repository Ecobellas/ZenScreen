import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/providers/providers.dart';
import '../models/strict_mode_config.dart';

/// State for Strict Mode (STRK-01 to STRK-04).
class StrictModeState {
  final StrictModeConfig config;
  final bool isLoading;

  /// Number of emergency bypasses remaining this session (max 1).
  final int remainingEmergencyBypasses;

  /// Seconds remaining on the emergency bypass countdown (STRK-03).
  final int emergencyCountdownSeconds;

  /// Whether an emergency bypass is currently counting down.
  final bool isEmergencyCountdownActive;

  /// Whether a temporary bypass is active (5 min after emergency bypass).
  final bool isBypassActive;

  /// The package temporarily bypassed, or null.
  final String? bypassedPackage;

  const StrictModeState({
    this.config = const StrictModeConfig(),
    this.isLoading = false,
    this.remainingEmergencyBypasses = 1,
    this.emergencyCountdownSeconds = 0,
    this.isEmergencyCountdownActive = false,
    this.isBypassActive = false,
    this.bypassedPackage,
  });

  StrictModeState copyWith({
    StrictModeConfig? config,
    bool? isLoading,
    int? remainingEmergencyBypasses,
    int? emergencyCountdownSeconds,
    bool? isEmergencyCountdownActive,
    bool? isBypassActive,
    String? bypassedPackage,
    bool clearBypassedPackage = false,
  }) {
    return StrictModeState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      remainingEmergencyBypasses:
          remainingEmergencyBypasses ?? this.remainingEmergencyBypasses,
      emergencyCountdownSeconds:
          emergencyCountdownSeconds ?? this.emergencyCountdownSeconds,
      isEmergencyCountdownActive:
          isEmergencyCountdownActive ?? this.isEmergencyCountdownActive,
      isBypassActive: isBypassActive ?? this.isBypassActive,
      bypassedPackage: clearBypassedPackage
          ? null
          : (bypassedPackage ?? this.bypassedPackage),
    );
  }
}

/// Manages Strict Mode activation, emergency bypass, and scheduling.
class StrictModeNotifier extends StateNotifier<StrictModeState> {
  final DatabaseHelper _db;
  Timer? _countdownTimer;
  Timer? _bypassTimer;

  StrictModeNotifier({required DatabaseHelper db})
      : _db = db,
        super(const StrictModeState(isLoading: true)) {
    _loadConfig();
  }

  /// Loads strict mode config from the database.
  Future<void> _loadConfig() async {
    if (_db.isStub) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final row = await _db.getStrictModeConfig();
      if (row != null) {
        state = state.copyWith(
          config: StrictModeConfig.fromMap(row),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Whether strict mode is currently in effect.
  bool isStrictModeActive() => state.config.isCurrentlyActive();

  /// Checks whether activating Strict Mode requires premium (MNTZ-04).
  /// Strict Mode is a premium-only feature.
  bool get needsPremium => true;

  /// Activates Strict Mode for a one-off period (STRK-01).
  ///
  /// The [endTime] determines when it will auto-deactivate.
  /// This is irreversible until the period ends.
  Future<void> activateStrictMode({
    required TimeOfDay endTime,
  }) async {
    final now = DateTime.now();
    final config = state.config.copyWith(
      isActive: true,
      startTime: TimeOfDay(hour: now.hour, minute: now.minute),
      endTime: endTime,
      isScheduled: false,
      activatedAt: now,
    );
    if (!_db.isStub) {
      await _db.updateStrictModeConfig(config.toMap());
    }
    state = state.copyWith(
      config: config,
      remainingEmergencyBypasses: 1,
      isBypassActive: false,
      clearBypassedPackage: true,
    );
  }

  /// Deactivates Strict Mode. Only callable when scheduled period ends.
  Future<void> deactivateStrictMode() async {
    final config = state.config.copyWith(
      isActive: false,
      clearActivatedAt: true,
    );
    if (!_db.isStub) {
      await _db.updateStrictModeConfig(config.toMap());
    }
    state = state.copyWith(config: config);
  }

  /// Schedules recurring Strict Mode periods (STRK-04).
  Future<void> scheduleRecurring({
    required List<int> days,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    final config = state.config.copyWith(
      isActive: true,
      startTime: startTime,
      endTime: endTime,
      isScheduled: true,
      scheduledDays: days,
    );
    if (!_db.isStub) {
      await _db.updateStrictModeConfig(config.toMap());
    }
    state = state.copyWith(config: config);
  }

  /// Removes the recurring schedule.
  Future<void> removeSchedule() async {
    final config = state.config.copyWith(
      isActive: false,
      isScheduled: false,
      scheduledDays: [],
      clearActivatedAt: true,
    );
    if (!_db.isStub) {
      await _db.updateStrictModeConfig(config.toMap());
    }
    state = state.copyWith(config: config);
  }

  /// Starts the 60-second emergency bypass countdown (STRK-03).
  void startEmergencyBypass(String packageName) {
    if (state.remainingEmergencyBypasses <= 0) return;

    _countdownTimer?.cancel();
    state = state.copyWith(
      emergencyCountdownSeconds: 60,
      isEmergencyCountdownActive: true,
      bypassedPackage: packageName,
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.emergencyCountdownSeconds - 1;
      if (remaining <= 0) {
        _countdownTimer?.cancel();
        state = state.copyWith(
          emergencyCountdownSeconds: 0,
          isEmergencyCountdownActive: false,
        );
      } else {
        state = state.copyWith(emergencyCountdownSeconds: remaining);
      }
    });
  }

  /// Cancels the emergency bypass countdown.
  void cancelEmergencyBypass() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      emergencyCountdownSeconds: 0,
      isEmergencyCountdownActive: false,
      clearBypassedPackage: true,
    );
  }

  /// Confirms emergency bypass after the 60s countdown (STRK-03).
  ///
  /// Grants a temporary 5-minute bypass for the specified package.
  void confirmEmergencyBypass() {
    if (state.emergencyCountdownSeconds > 0) return; // Countdown not done.

    _countdownTimer?.cancel();
    _bypassTimer?.cancel();

    state = state.copyWith(
      isBypassActive: true,
      remainingEmergencyBypasses: state.remainingEmergencyBypasses - 1,
      isEmergencyCountdownActive: false,
    );

    // Auto-revoke bypass after 5 minutes.
    _bypassTimer = Timer(const Duration(minutes: 5), () {
      state = state.copyWith(
        isBypassActive: false,
        clearBypassedPackage: true,
      );
    });
  }

  /// Checks if a package is currently bypassed via emergency bypass.
  bool isPackageBypassed(String packageName) {
    return state.isBypassActive &&
        state.bypassedPackage == packageName;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bypassTimer?.cancel();
    super.dispose();
  }
}

/// Global provider for strict mode management.
final strictModeProvider =
    StateNotifierProvider<StrictModeNotifier, StrictModeState>((ref) {
  return StrictModeNotifier(db: ref.watch(databaseProvider));
});
