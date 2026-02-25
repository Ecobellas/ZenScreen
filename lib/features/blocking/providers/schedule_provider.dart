import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/providers/providers.dart';
import '../models/blocking_schedule.dart';

/// State holding all blocking schedules.
class ScheduleState {
  final List<BlockingSchedule> schedules;
  final bool isLoading;

  const ScheduleState({
    this.schedules = const [],
    this.isLoading = false,
  });

  ScheduleState copyWith({
    List<BlockingSchedule>? schedules,
    bool? isLoading,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Manages CRUD for blocking schedules (BLCK-01).
class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final DatabaseHelper _db;

  ScheduleNotifier({required DatabaseHelper db})
      : _db = db,
        super(const ScheduleState(isLoading: true)) {
    loadSchedules();
  }

  /// Loads all schedules from the database.
  Future<void> loadSchedules() async {
    state = state.copyWith(isLoading: true);
    final rows = await _db.getBlockingSchedules();
    final schedules = rows.map((r) => BlockingSchedule.fromMap(r)).toList();
    state = ScheduleState(schedules: schedules, isLoading: false);
  }

  /// Creates a new blocking schedule.
  Future<int> createSchedule({
    required int groupId,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    List<int> daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    bool isActive = true,
  }) async {
    final schedule = BlockingSchedule(
      groupId: groupId,
      startTime: startTime,
      endTime: endTime,
      daysOfWeek: daysOfWeek,
      isActive: isActive,
    );
    final id = await _db.insertBlockingSchedule(schedule.toMap());
    await loadSchedules();
    return id;
  }

  /// Updates an existing schedule.
  Future<void> updateSchedule(BlockingSchedule schedule) async {
    if (schedule.id == null) return;
    await _db.updateBlockingSchedule(schedule.id!, schedule.toMap());
    await loadSchedules();
  }

  /// Deletes a schedule.
  Future<void> deleteSchedule(int id) async {
    await _db.deleteBlockingSchedule(id);
    await loadSchedules();
  }

  /// Toggles a schedule's active state.
  Future<void> toggleSchedule(int id) async {
    final schedule = state.schedules.firstWhere((s) => s.id == id);
    await updateSchedule(schedule.copyWith(isActive: !schedule.isActive));
  }

  /// Returns all schedules for a specific group.
  List<BlockingSchedule> getSchedulesForGroup(int groupId) {
    return state.schedules.where((s) => s.groupId == groupId).toList();
  }

  /// Checks if any schedule for a group is currently active.
  bool isGroupScheduleActive(int groupId) {
    return state.schedules
        .where((s) => s.groupId == groupId)
        .any((s) => s.isCurrentlyActive());
  }

  /// Returns the currently active schedule for a group, or null.
  BlockingSchedule? getActiveScheduleForGroup(int groupId) {
    try {
      return state.schedules
          .where((s) => s.groupId == groupId)
          .firstWhere((s) => s.isCurrentlyActive());
    } catch (_) {
      return null;
    }
  }
}

/// Global provider for blocking schedules.
final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  return ScheduleNotifier(db: ref.watch(databaseProvider));
});
