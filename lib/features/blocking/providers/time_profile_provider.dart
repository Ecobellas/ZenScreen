import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/models/time_profile.dart';
import '../../../core/providers/providers.dart';

/// State holding all time profiles.
class TimeProfileState {
  final List<TimeProfile> profiles;

  /// Map from profile ID to blocked group IDs.
  final Map<int, List<int>> profileBlockedGroups;
  final bool isLoading;

  /// Which profile (by ID) is currently active, or null.
  final int? activeProfileId;

  const TimeProfileState({
    this.profiles = const [],
    this.profileBlockedGroups = const {},
    this.isLoading = false,
    this.activeProfileId,
  });

  TimeProfileState copyWith({
    List<TimeProfile>? profiles,
    Map<int, List<int>>? profileBlockedGroups,
    bool? isLoading,
    int? activeProfileId,
    bool clearActiveProfile = false,
  }) {
    return TimeProfileState(
      profiles: profiles ?? this.profiles,
      profileBlockedGroups:
          profileBlockedGroups ?? this.profileBlockedGroups,
      isLoading: isLoading ?? this.isLoading,
      activeProfileId: clearActiveProfile
          ? null
          : (activeProfileId ?? this.activeProfileId),
    );
  }
}

/// Preset time profile definitions (BLCK-06).
class _PresetProfile {
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> activeDays;
  final bool isStrictMode;

  const _PresetProfile({
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.activeDays,
    this.isStrictMode = false,
  });
}

const _presets = [
  _PresetProfile(
    name: 'Work',
    startTime: TimeOfDay(hour: 9, minute: 0),
    endTime: TimeOfDay(hour: 17, minute: 0),
    activeDays: [1, 2, 3, 4, 5], // Mon-Fri
  ),
  _PresetProfile(
    name: 'Night',
    startTime: TimeOfDay(hour: 22, minute: 0),
    endTime: TimeOfDay(hour: 7, minute: 0),
    activeDays: [1, 2, 3, 4, 5, 6, 7], // Every day
    isStrictMode: true,
  ),
  _PresetProfile(
    name: 'Weekend',
    startTime: TimeOfDay(hour: 0, minute: 0),
    endTime: TimeOfDay(hour: 23, minute: 59),
    activeDays: [6, 7], // Sat-Sun
  ),
];

/// Manages time profiles (BLCK-06).
class TimeProfileNotifier extends StateNotifier<TimeProfileState> {
  final DatabaseHelper _db;

  TimeProfileNotifier({required DatabaseHelper db})
      : _db = db,
        super(const TimeProfileState(isLoading: true)) {
    loadProfiles();
  }

  /// Loads all profiles from the database, creating presets if needed.
  Future<void> loadProfiles() async {
    if (_db.isStub) {
      state = const TimeProfileState(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      await _ensurePresetProfiles();

      final rows = await _db.getTimeProfiles();
      final profiles = rows.map((r) => TimeProfile.fromMap(r)).toList();

      // Load blocked groups for each profile.
      final blockedGroups = <int, List<int>>{};
      for (final profile in profiles) {
        if (profile.id != null) {
          blockedGroups[profile.id!] =
              await _db.getProfileBlockedGroups(profile.id!);
        }
      }

      state = TimeProfileState(
        profiles: profiles,
        profileBlockedGroups: blockedGroups,
        isLoading: false,
        activeProfileId: state.activeProfileId,
      );
    } catch (_) {
      state = const TimeProfileState(isLoading: false);
    }
  }

  /// Creates preset profiles if they don't already exist.
  Future<void> _ensurePresetProfiles() async {
    if (_db.isStub) return;
    final existing = await _db.getTimeProfiles();
    final existingNames = existing.map((r) => r['name'] as String).toSet();

    for (final preset in _presets) {
      if (!existingNames.contains(preset.name)) {
        await _db.insertTimeProfile({
          'name': preset.name,
          'start_hour': preset.startTime.hour,
          'start_minute': preset.startTime.minute,
          'end_hour': preset.endTime.hour,
          'end_minute': preset.endTime.minute,
          'active_days': preset.activeDays.join(','),
          'is_strict_mode': preset.isStrictMode ? 1 : 0,
        });
      }
    }
  }

  /// Activates a profile. Only one can be active at a time.
  void activateProfile(int profileId) {
    state = state.copyWith(activeProfileId: profileId);
  }

  /// Deactivates the currently active profile.
  void deactivateProfile() {
    state = state.copyWith(clearActiveProfile: true);
  }

  /// Creates a new custom profile.
  Future<int> createProfile({
    required String name,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    List<int> activeDays = const [1, 2, 3, 4, 5, 6, 7],
    bool isStrictMode = false,
    List<int> blockedGroupIds = const [],
  }) async {
    if (_db.isStub) return -1;
    final id = await _db.insertTimeProfile({
      'name': name,
      'start_hour': startTime.hour,
      'start_minute': startTime.minute,
      'end_hour': endTime.hour,
      'end_minute': endTime.minute,
      'active_days': activeDays.join(','),
      'is_strict_mode': isStrictMode ? 1 : 0,
    });

    if (blockedGroupIds.isNotEmpty) {
      await _db.setProfileBlockedGroups(id, blockedGroupIds);
    }

    await loadProfiles();
    return id;
  }

  /// Updates a profile.
  Future<void> updateProfile(
    int profileId, {
    String? name,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? activeDays,
    bool? isStrictMode,
    List<int>? blockedGroupIds,
  }) async {
    if (_db.isStub) return;
    final values = <String, dynamic>{};
    if (name != null) values['name'] = name;
    if (startTime != null) {
      values['start_hour'] = startTime.hour;
      values['start_minute'] = startTime.minute;
    }
    if (endTime != null) {
      values['end_hour'] = endTime.hour;
      values['end_minute'] = endTime.minute;
    }
    if (activeDays != null) values['active_days'] = activeDays.join(',');
    if (isStrictMode != null) {
      values['is_strict_mode'] = isStrictMode ? 1 : 0;
    }

    if (values.isNotEmpty) {
      await _db.updateTimeProfile(profileId, values);
    }
    if (blockedGroupIds != null) {
      await _db.setProfileBlockedGroups(profileId, blockedGroupIds);
    }

    await loadProfiles();
  }

  /// Deletes a profile.
  Future<void> deleteProfile(int profileId) async {
    if (_db.isStub) return;
    await _db.deleteTimeProfile(profileId);
    if (state.activeProfileId == profileId) {
      state = state.copyWith(clearActiveProfile: true);
    }
    await loadProfiles();
  }

  /// Returns blocked group IDs for the currently active profile, or empty.
  List<int> get activeBlockedGroupIds {
    if (state.activeProfileId == null) return [];
    return state.profileBlockedGroups[state.activeProfileId!] ?? [];
  }

  /// Returns the currently active profile, or null.
  TimeProfile? get activeProfile {
    if (state.activeProfileId == null) return null;
    try {
      return state.profiles.firstWhere((p) => p.id == state.activeProfileId);
    } catch (_) {
      return null;
    }
  }
}

/// Global provider for time profiles.
final timeProfileProvider =
    StateNotifierProvider<TimeProfileNotifier, TimeProfileState>((ref) {
  return TimeProfileNotifier(db: ref.watch(databaseProvider));
});
