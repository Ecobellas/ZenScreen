import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/database/preferences_service.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/providers.dart';

/// Settings state for friction configuration (FRIC-05, FRIC-07).
class FrictionSettings {
  /// Whether escalation is enabled (FRIC-01: +5s per consecutive open).
  final bool escalationEnabled;

  /// Number of daily opens before friction kicks in (FRIC-06).
  final int gracePeriodCount;

  /// Default friction type when no app-group-specific type is set.
  final FrictionType defaultFrictionType;

  const FrictionSettings({
    this.escalationEnabled = true,
    this.gracePeriodCount = 3,
    this.defaultFrictionType = FrictionType.wait,
  });

  FrictionSettings copyWith({
    bool? escalationEnabled,
    int? gracePeriodCount,
    FrictionType? defaultFrictionType,
  }) {
    return FrictionSettings(
      escalationEnabled: escalationEnabled ?? this.escalationEnabled,
      gracePeriodCount: gracePeriodCount ?? this.gracePeriodCount,
      defaultFrictionType: defaultFrictionType ?? this.defaultFrictionType,
    );
  }
}

/// Manages friction settings: per-app-group friction types, escalation toggle,
/// grace period count, and the default/preferred friction type.
class FrictionSettingsNotifier extends StateNotifier<FrictionSettings> {
  final DatabaseHelper _db;
  final PreferencesService _prefs;

  FrictionSettingsNotifier({
    required DatabaseHelper db,
    required PreferencesService prefs,
  })  : _db = db,
        _prefs = prefs,
        super(FrictionSettings(
          escalationEnabled: prefs.escalationEnabled,
          gracePeriodCount: prefs.gracePeriodCount,
          defaultFrictionType: prefs.preferredFriction,
        ));

  // ---------------------------------------------------------------------------
  // Read settings
  // ---------------------------------------------------------------------------

  /// Determines the [FrictionType] for a given app package.
  ///
  /// Looks up which app_group (if any) the app belongs to and returns that
  /// group's friction_type. Falls back to the user's preferred friction type.
  Future<FrictionType> getFrictionTypeForApp(String packageName) async {
    final db = await _db.database;

    // Find the app group this package belongs to.
    final rows = await db.rawQuery('''
      SELECT ag.friction_type
      FROM blocked_apps ba
      INNER JOIN app_groups ag ON ba.group_id = ag.id
      WHERE ba.package_name = ?
      LIMIT 1
    ''', [packageName]);

    if (rows.isNotEmpty) {
      final index = rows.first['friction_type'] as int? ?? 0;
      return FrictionType.values[index];
    }

    // Fallback to user's preferred friction type.
    return state.defaultFrictionType;
  }

  /// Checks whether a given package is in any blocked app group.
  Future<bool> isAppBlocked(String packageName) async {
    final db = await _db.database;
    final rows = await db.query(
      'blocked_apps',
      where: 'package_name = ?',
      whereArgs: [packageName],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Write settings (FRIC-07)
  // ---------------------------------------------------------------------------

  /// Updates the friction type for a specific app group.
  Future<void> setFrictionTypeForGroup(
      int groupId, FrictionType type) async {
    final db = await _db.database;
    await db.update(
      'app_groups',
      {'friction_type': type.index},
      where: 'id = ?',
      whereArgs: [groupId],
    );
  }

  /// Toggles escalation on/off.
  Future<void> setEscalationEnabled(bool enabled) async {
    await _prefs.setEscalationEnabled(enabled);
    state = state.copyWith(escalationEnabled: enabled);
  }

  /// Updates the grace period count (how many free opens per day).
  Future<void> setGracePeriodCount(int count) async {
    await _prefs.setGracePeriodCount(count);
    state = state.copyWith(gracePeriodCount: count);
  }

  /// Updates the default/preferred friction type.
  Future<void> setDefaultFrictionType(FrictionType type) async {
    await _prefs.setPreferredFriction(type);
    state = state.copyWith(defaultFrictionType: type);
  }
}

/// Global provider for friction settings.
final frictionSettingsProvider =
    StateNotifierProvider<FrictionSettingsNotifier, FrictionSettings>((ref) {
  return FrictionSettingsNotifier(
    db: ref.watch(databaseProvider),
    prefs: ref.watch(preferencesServiceProvider),
  );
});
