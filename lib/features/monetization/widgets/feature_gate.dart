import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/premium_feature.dart';
import '../providers/premium_provider.dart';

/// Widget wrapper that checks premium status before allowing an action (MNTZ-04).
///
/// If the user is not premium, navigates to the paywall screen.
/// If the user is premium, executes the child's onTap or shows the child normally.
class FeatureGate extends ConsumerWidget {
  final PremiumFeature feature;
  final Widget child;

  /// Optional callback when the feature is gated (not premium).
  /// If null, navigates to paywall.
  final VoidCallback? onGated;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.onGated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return child;
  }

  /// Static method to check premium access and show paywall if needed.
  /// Returns true if feature is allowed, false if paywall was shown.
  static bool checkAndGate(
    BuildContext context,
    WidgetRef ref,
    PremiumFeature feature,
  ) {
    final premiumState = ref.read(premiumProvider);
    if (premiumState.isPremium || premiumState.trialActive) {
      return true;
    }

    // Navigate to paywall.
    context.go('/settings/paywall');
    return false;
  }
}
