import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/database/preferences_service.dart';
import '../../../core/providers/providers.dart';
import '../models/premium_feature.dart';

/// RevenueCat API key placeholder.
const _revenueCatApiKey = 'YOUR_REVENUECAT_API_KEY';

/// Premium subscription state (MNTZ-02, MNTZ-05, MNTZ-06).
class PremiumState {
  final bool isPremium;
  final bool trialActive;
  final int trialDaysRemaining;
  final bool isLoading;

  const PremiumState({
    this.isPremium = false,
    this.trialActive = false,
    this.trialDaysRemaining = 0,
    this.isLoading = false,
  });

  PremiumState copyWith({
    bool? isPremium,
    bool? trialActive,
    int? trialDaysRemaining,
    bool? isLoading,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      trialActive: trialActive ?? this.trialActive,
      trialDaysRemaining: trialDaysRemaining ?? this.trialDaysRemaining,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Manages premium state, feature gates, and RevenueCat integration.
class PremiumNotifier extends StateNotifier<PremiumState> {
  final PreferencesService _prefs;
  bool _revenueCatConfigured = false;

  PremiumNotifier({required PreferencesService prefs})
      : _prefs = prefs,
        super(PremiumState(isPremium: prefs.isPremium)) {
    _checkTrialStatus();
    _initRevenueCat();
  }

  /// Checks if a premium feature is accessible (MNTZ-01, MNTZ-04).
  bool checkPremiumAccess(PremiumFeature feature) {
    if (state.isPremium || state.trialActive) return true;

    // All listed features require premium.
    return false;
  }

  /// Checks premium status and shows paywall if needed (MNTZ-04).
  /// Returns true if the feature is allowed, false if blocked.
  bool isFeatureAllowed(PremiumFeature feature) {
    return state.isPremium || state.trialActive;
  }

  // ---------------------------------------------------------------------------
  // Trial Management (MNTZ-05)
  // ---------------------------------------------------------------------------

  void _checkTrialStatus() {
    final trialStart = _prefs.trialStartDate;
    if (trialStart != null) {
      final elapsed = DateTime.now().difference(trialStart).inDays;
      if (elapsed < 7) {
        state = state.copyWith(
          trialActive: true,
          trialDaysRemaining: 7 - elapsed,
        );
      } else {
        state = state.copyWith(trialActive: false, trialDaysRemaining: 0);
      }
    }
  }

  /// Starts a 7-day free trial (MNTZ-05).
  Future<void> startFreeTrial() async {
    await _prefs.setTrialStartDate(DateTime.now());
    state = state.copyWith(
      trialActive: true,
      trialDaysRemaining: 7,
    );
  }

  // ---------------------------------------------------------------------------
  // RevenueCat Integration (MNTZ-06)
  // ---------------------------------------------------------------------------

  /// Initializes RevenueCat SDK with a placeholder API key.
  Future<void> _initRevenueCat() async {
    if (_revenueCatApiKey == 'YOUR_REVENUECAT_API_KEY') {
      // RevenueCat not configured — graceful fallback.
      debugPrint(
          'RevenueCat: API key not configured. Running in offline mode.');
      return;
    }

    try {
      final configuration = PurchasesConfiguration(_revenueCatApiKey);
      await Purchases.configure(configuration);
      _revenueCatConfigured = true;
      await checkSubscriptionStatus();
    } catch (e) {
      debugPrint('RevenueCat init failed: $e');
      // Graceful fallback — app continues without subscription management.
    }
  }

  /// Initiates a premium purchase flow (MNTZ-02).
  Future<bool> purchasePremium() async {
    if (!_revenueCatConfigured) {
      debugPrint('RevenueCat not configured. Cannot purchase.');
      // For development: toggle premium locally.
      await _prefs.setIsPremium(true);
      state = state.copyWith(isPremium: true);
      return true;
    }

    state = state.copyWith(isLoading: true);
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null || current.availablePackages.isEmpty) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final package = current.annual ?? current.availablePackages.first;
      await Purchases.purchasePackage(package);

      await checkSubscriptionStatus();
      state = state.copyWith(isLoading: false);
      return state.isPremium;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Restores purchases from the app stores (MNTZ-06).
  Future<void> restorePurchases() async {
    if (!_revenueCatConfigured) {
      debugPrint('RevenueCat not configured. Cannot restore.');
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      await Purchases.restorePurchases();
      await checkSubscriptionStatus();
    } catch (e) {
      debugPrint('Restore failed: $e');
    }
    state = state.copyWith(isLoading: false);
  }

  /// Fetches available offerings from RevenueCat.
  Future<Offerings?> getOfferings() async {
    if (!_revenueCatConfigured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('Failed to get offerings: $e');
      return null;
    }
  }

  /// Verifies the current subscription status (MNTZ-06).
  Future<void> checkSubscriptionStatus() async {
    if (!_revenueCatConfigured) return;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlements = customerInfo.entitlements.active;
      final hasPremium = entitlements.containsKey('premium');

      await _prefs.setIsPremium(hasPremium);
      state = state.copyWith(isPremium: hasPremium);
    } catch (e) {
      debugPrint('Failed to check subscription: $e');
    }
  }
}

/// Global provider for premium state management.
final premiumProvider =
    StateNotifierProvider<PremiumNotifier, PremiumState>((ref) {
  return PremiumNotifier(prefs: ref.watch(preferencesServiceProvider));
});
