import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/enums.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/preferences_service.dart';
import '../../../core/providers/providers.dart';

class OnboardingState {
  final int currentPage;
  final GoalType? selectedGoal;
  final Map<String, List<String>> selectedApps;
  final FrictionType? selectedFriction;

  const OnboardingState({
    this.currentPage = 0,
    this.selectedGoal,
    this.selectedApps = const {},
    this.selectedFriction,
  });

  OnboardingState copyWith({
    int? currentPage,
    GoalType? selectedGoal,
    Map<String, List<String>>? selectedApps,
    FrictionType? selectedFriction,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      selectedGoal: selectedGoal ?? this.selectedGoal,
      selectedApps: selectedApps ?? this.selectedApps,
      selectedFriction: selectedFriction ?? this.selectedFriction,
    );
  }

  /// Total number of selected apps across all categories.
  int get totalSelectedApps =>
      selectedApps.values.fold(0, (sum, list) => sum + list.length);
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final PreferencesService _prefs;
  final DatabaseHelper _db;

  OnboardingNotifier(this._prefs, this._db) : super(const OnboardingState());

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void setGoal(GoalType goal) {
    state = state.copyWith(selectedGoal: goal);
  }

  void toggleApp(String category, String appName) {
    final current = Map<String, List<String>>.from(state.selectedApps);
    final categoryApps = List<String>.from(current[category] ?? []);

    if (categoryApps.contains(appName)) {
      categoryApps.remove(appName);
    } else {
      categoryApps.add(appName);
    }

    if (categoryApps.isEmpty) {
      current.remove(category);
    } else {
      current[category] = categoryApps;
    }

    state = state.copyWith(selectedApps: current);
  }

  void setFriction(FrictionType friction) {
    state = state.copyWith(selectedFriction: friction);
  }

  Future<void> completeOnboarding() async {
    // Save goal
    if (state.selectedGoal != null) {
      await _prefs.setSelectedGoal(state.selectedGoal!);
    }

    // Save friction preference
    if (state.selectedFriction != null) {
      await _prefs.setPreferredFriction(state.selectedFriction!);
    }

    // Save selected apps as app groups in the database
    try {
      final frictionIndex =
          (state.selectedFriction ?? FrictionType.wait).index;

      for (final entry in state.selectedApps.entries) {
        final category = entry.key;
        final apps = entry.value;
        if (apps.isEmpty) continue;

        final groupId = await _db.insertAppGroup(
          name: category,
          icon: _iconForCategory(category),
          frictionType: frictionIndex,
        );

        for (final appName in apps) {
          await _db.insertBlockedApp(
            groupId: groupId,
            packageName: _packageForApp(appName),
            appName: appName,
          );
        }
      }
    } catch (e) {
      debugPrint('DB write skipped (web): $e');
    }

    // Mark onboarding complete
    await _prefs.setOnboardingComplete(true);
  }

  String _iconForCategory(String category) {
    switch (category) {
      case 'Social Media':
        return 'people';
      case 'Video':
        return 'play_circle';
      case 'Games':
        return 'sports_esports';
      case 'News':
        return 'article';
      default:
        return 'apps';
    }
  }

  String _packageForApp(String appName) {
    // Map display names to approximate package names
    switch (appName) {
      case 'Instagram':
        return 'com.instagram.android';
      case 'TikTok':
        return 'com.zhiliaoapp.musically';
      case 'Twitter/X':
        return 'com.twitter.android';
      case 'Facebook':
        return 'com.facebook.katana';
      case 'Snapchat':
        return 'com.snapchat.android';
      case 'Reddit':
        return 'com.reddit.frontpage';
      case 'YouTube':
        return 'com.google.android.youtube';
      case 'Netflix':
        return 'com.netflix.mediaclient';
      case 'Twitch':
        return 'tv.twitch.android.app';
      case 'Games':
        return 'com.android.games';
      case 'News':
        return 'com.google.android.apps.magazines';
      default:
        return 'com.unknown.$appName';
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  final db = ref.watch(databaseProvider);
  return OnboardingNotifier(prefs, db);
});
