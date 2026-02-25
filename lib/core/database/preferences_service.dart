import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';

class PreferencesService {
  final SharedPreferences _prefs;
  PreferencesService(this._prefs);

  // Onboarding
  bool get isOnboardingComplete =>
      _prefs.getBool('onboarding_complete') ?? false;
  Future<void> setOnboardingComplete(bool v) =>
      _prefs.setBool('onboarding_complete', v);

  // Friction
  FrictionType get preferredFriction =>
      FrictionType.values[_prefs.getInt('preferred_friction') ?? 0];
  Future<void> setPreferredFriction(FrictionType v) =>
      _prefs.setInt('preferred_friction', v.index);

  // Goal
  GoalType get selectedGoal =>
      GoalType.values[_prefs.getInt('selected_goal') ?? 0];
  Future<void> setSelectedGoal(GoalType v) =>
      _prefs.setInt('selected_goal', v.index);

  // Screen time goal
  int get dailyGoalMinutes => _prefs.getInt('daily_goal') ?? 120;
  Future<void> setDailyGoalMinutes(int v) => _prefs.setInt('daily_goal', v);

  // Premium
  bool get isPremium => _prefs.getBool('is_premium') ?? false;
  Future<void> setIsPremium(bool v) => _prefs.setBool('is_premium', v);

  // Grace period
  int get gracePeriodCount => _prefs.getInt('grace_period') ?? 3;
  Future<void> setGracePeriodCount(int v) => _prefs.setInt('grace_period', v);

  // Friction escalation
  bool get escalationEnabled =>
      _prefs.getBool('escalation_enabled') ?? true;
  Future<void> setEscalationEnabled(bool v) =>
      _prefs.setBool('escalation_enabled', v);
}
