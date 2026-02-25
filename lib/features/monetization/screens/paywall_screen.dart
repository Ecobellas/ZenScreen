import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/premium_provider.dart';

/// Beautiful paywall screen (MNTZ-03).
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumState = ref.watch(premiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Premium', style: AppTextStyles.headingMedium),
      ),
      body: premiumState.isPremium
          ? _buildActiveSubscription(context, premiumState)
          : _buildPaywall(context, ref, premiumState),
    );
  }

  Widget _buildActiveSubscription(
      BuildContext context, PremiumState premiumState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary,
                    AppColors.secondary.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.star_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text('You\'re Premium!', style: AppTextStyles.headingLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You have access to all ZenScreen features.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (premiumState.trialActive) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${premiumState.trialDaysRemaining} days left in trial',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaywall(
      BuildContext context, WidgetRef ref, PremiumState premiumState) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.lg),
        _buildHeader(),
        const SizedBox(height: AppSpacing.xxl),
        _buildFeatureComparison(),
        const SizedBox(height: AppSpacing.xxl),
        _buildTestimonials(),
        const SizedBox(height: AppSpacing.xxl),
        _buildPricing(context, ref, premiumState),
        const SizedBox(height: AppSpacing.lg),
        _buildRestoreButton(context, ref),
        const SizedBox(height: AppSpacing.lg),
        _buildFooterLinks(),
        const SizedBox(height: AppSpacing.huge),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ).createShader(bounds),
          child: const Icon(Icons.workspace_premium_rounded,
              size: 64, color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Unlock ZenScreen',
          style: AppTextStyles.headingLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Premium',
          style: AppTextStyles.headingLarge.copyWith(
            color: AppColors.secondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Take full control of your digital wellbeing',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureComparison() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Header row.
            Row(
              children: [
                Expanded(
                    flex: 3,
                    child:
                        Text('Feature', style: AppTextStyles.labelMedium)),
                Expanded(
                  flex: 2,
                  child: Text('Free',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.textHint),
                      textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Premium',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.secondary),
                      textAlign: TextAlign.center),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            _featureRow('Apps to monitor', '5', 'Unlimited'),
            _featureRow('Friction types', 'Wait Timer', 'All 3'),
            _featureRow('Intention Journal', '7 days', 'Unlimited'),
            _featureRow('Strict Mode', null, 'Included'),
            _featureRow('Detailed Reports', null, 'Included'),
            _featureRow('CSV Export', null, 'Included'),
            _featureRow('Time Profiles', '1', 'Unlimited'),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(String feature, String? freeValue, String premiumValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(feature, style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textPrimary)),
          ),
          Expanded(
            flex: 2,
            child: freeValue != null
                ? Text(freeValue,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textHint),
                    textAlign: TextAlign.center)
                : Icon(Icons.remove,
                    size: 16, color: AppColors.textHint),
          ),
          Expanded(
            flex: 2,
            child: premiumValue == 'Included'
                ? const Icon(Icons.check_circle,
                    size: 18, color: AppColors.secondary)
                : Text(premiumValue,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.secondary),
                    textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Text('What users say',
              style: AppTextStyles.headingSmall.copyWith(fontSize: 18)),
        ),
        const SizedBox(height: AppSpacing.md),
        _testimonialCard(
          quote:
              'ZenScreen Premium helped me cut my screen time by 40% in just two weeks. The Strict Mode is a game-changer!',
          author: 'Sarah M.',
          rating: 5,
        ),
        const SizedBox(height: AppSpacing.sm),
        _testimonialCard(
          quote:
              'The breathing exercise friction actually made me more mindful. I no longer mindlessly scroll through social media.',
          author: 'James K.',
          rating: 5,
        ),
        const SizedBox(height: AppSpacing.sm),
        _testimonialCard(
          quote:
              'Worth every penny. The detailed reports show me exactly where my time goes.',
          author: 'Alex R.',
          rating: 5,
        ),
      ],
    );
  }

  Widget _testimonialCard({
    required String quote,
    required String author,
    required int rating,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                rating,
                (_) => const Icon(Icons.star_rounded,
                    color: Color(0xFFFFD700), size: 16),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('"$quote"',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary, fontStyle: FontStyle.italic)),
            const SizedBox(height: AppSpacing.sm),
            Text('- $author', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildPricing(
      BuildContext context, WidgetRef ref, PremiumState premiumState) {
    return Column(
      children: [
        Text('\$44.99', style: AppTextStyles.metricMedium),
        const SizedBox(height: AppSpacing.xs),
        Text('/year', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              onPressed: premiumState.isLoading
                  ? null
                  : () async {
                      // Start with free trial first (MNTZ-05).
                      final notifier = ref.read(premiumProvider.notifier);
                      await notifier.startFreeTrial();
                      await notifier.purchasePremium();
                    },
              child: premiumState.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Start 7-Day Free Trial',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white, fontSize: 18),
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Cancel anytime. No charge during trial.',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRestoreButton(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton(
        onPressed: () async {
          await ref.read(premiumProvider.notifier).restorePurchases();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Purchases restored successfully')),
            );
          }
        },
        child: Text(
          'Already purchased? Restore',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Privacy Policy',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textHint)),
        const SizedBox(width: AppSpacing.lg),
        Text('Terms of Use',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textHint)),
      ],
    );
  }
}
