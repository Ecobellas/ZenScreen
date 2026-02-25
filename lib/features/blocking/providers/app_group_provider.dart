import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/models/app_group.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/providers.dart';
import '../../monetization/models/premium_feature.dart';

/// State holding loaded app groups and their member apps.
class AppGroupState {
  final List<AppGroup> groups;

  /// Map from group ID to list of blocked app entries.
  final Map<int, List<BlockedAppEntry>> groupApps;
  final bool isLoading;

  const AppGroupState({
    this.groups = const [],
    this.groupApps = const {},
    this.isLoading = false,
  });

  AppGroupState copyWith({
    List<AppGroup>? groups,
    Map<int, List<BlockedAppEntry>>? groupApps,
    bool? isLoading,
  }) {
    return AppGroupState(
      groups: groups ?? this.groups,
      groupApps: groupApps ?? this.groupApps,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Represents a single app entry within a group.
class BlockedAppEntry {
  final int? id;
  final int groupId;
  final String packageName;
  final String appName;

  const BlockedAppEntry({
    this.id,
    required this.groupId,
    required this.packageName,
    required this.appName,
  });
}

/// Preset app group definitions (BLCK-05).
const _presetGroups = [
  (name: 'Social Media', icon: 'people'),
  (name: 'Video', icon: 'play_circle'),
  (name: 'Games', icon: 'sports_esports'),
  (name: 'News', icon: 'newspaper'),
];

/// Manages CRUD for app groups (BLCK-05).
class AppGroupNotifier extends StateNotifier<AppGroupState> {
  final DatabaseHelper _db;

  AppGroupNotifier({required DatabaseHelper db})
      : _db = db,
        super(const AppGroupState(isLoading: true)) {
    loadGroups();
  }

  /// Loads all groups from the database, creating presets if needed.
  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true);

    // Ensure preset groups exist.
    await _ensurePresetGroups();

    final rows = await _db.getAppGroups();
    final groups = rows.map((r) => AppGroup.fromMap(r)).toList();

    // Load apps for each group.
    final groupApps = <int, List<BlockedAppEntry>>{};
    for (final group in groups) {
      if (group.id != null) {
        final appRows = await _db.getBlockedApps(group.id!);
        groupApps[group.id!] = appRows
            .map((r) => BlockedAppEntry(
                  id: r['id'] as int?,
                  groupId: r['group_id'] as int,
                  packageName: r['package_name'] as String,
                  appName: r['app_name'] as String,
                ))
            .toList();
      }
    }

    state = AppGroupState(
      groups: groups,
      groupApps: groupApps,
      isLoading: false,
    );
  }

  /// Creates preset groups if they don't already exist.
  Future<void> _ensurePresetGroups() async {
    final existing = await _db.getAppGroups();
    final existingNames = existing.map((r) => r['name'] as String).toSet();

    for (final preset in _presetGroups) {
      if (!existingNames.contains(preset.name)) {
        await _db.insertAppGroup(name: preset.name, icon: preset.icon);
      }
    }
  }

  /// Creates a new custom app group.
  Future<int> createGroup({
    required String name,
    String icon = 'apps',
    FrictionType frictionType = FrictionType.wait,
    int dailyLimitMinutes = 60,
  }) async {
    final id = await _db.insertAppGroup(
      name: name,
      icon: icon,
      frictionType: frictionType.index,
      dailyLimitMinutes: dailyLimitMinutes,
    );
    await loadGroups();
    return id;
  }

  /// Updates an existing group's properties.
  Future<void> updateGroup(int groupId, {
    String? name,
    String? icon,
    FrictionType? frictionType,
    int? dailyLimitMinutes,
    bool? isStrictMode,
  }) async {
    final values = <String, dynamic>{};
    if (name != null) values['name'] = name;
    if (icon != null) values['icon'] = icon;
    if (frictionType != null) values['friction_type'] = frictionType.index;
    if (dailyLimitMinutes != null) {
      values['daily_limit_minutes'] = dailyLimitMinutes;
    }
    if (isStrictMode != null) values['is_strict_mode'] = isStrictMode ? 1 : 0;

    if (values.isNotEmpty) {
      await _db.updateAppGroup(groupId, values);
      await loadGroups();
    }
  }

  /// Deletes an app group.
  Future<void> deleteGroup(int groupId) async {
    await _db.deleteAppGroup(groupId);
    await loadGroups();
  }

  /// Checks whether adding another app would exceed the free tier limit (MNTZ-04).
  /// Returns true if the user needs premium to add more apps.
  bool needsPremiumForNewApp() {
    return totalAppCount >= FreeTierLimits.maxApps;
  }

  /// Adds an app to a group.
  Future<void> addAppToGroup({
    required int groupId,
    required String packageName,
    required String appName,
  }) async {
    await _db.insertBlockedApp(
      groupId: groupId,
      packageName: packageName,
      appName: appName,
    );
    await loadGroups();
  }

  /// Removes an app from a group.
  Future<void> removeAppFromGroup({
    required int groupId,
    required String packageName,
  }) async {
    await _db.removeBlockedApp(groupId, packageName);
    await loadGroups();
  }

  /// Finds which group (if any) a package belongs to.
  AppGroup? getGroupForPackage(String packageName) {
    for (final group in state.groups) {
      final apps = state.groupApps[group.id] ?? [];
      if (apps.any((a) => a.packageName == packageName)) {
        return group;
      }
    }
    return null;
  }

  /// Returns total number of apps across all groups.
  int get totalAppCount =>
      state.groupApps.values.fold(0, (sum, apps) => sum + apps.length);
}

/// Global provider for app group management.
final appGroupProvider =
    StateNotifierProvider<AppGroupNotifier, AppGroupState>((ref) {
  return AppGroupNotifier(db: ref.watch(databaseProvider));
});
