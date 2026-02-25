import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/step_indicator.dart';
import '../widgets/steps/welcome_step.dart';
import '../widgets/steps/shock_stat_step.dart';
import '../widgets/steps/goal_step.dart';
import '../widgets/steps/app_selection_step.dart';
import '../widgets/steps/friction_step.dart';
import '../widgets/steps/permission_step.dart';
import '../widgets/steps/ready_step.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  static const _totalPages = 7;

  final _steps = const <Widget>[
    WelcomeStep(),
    ShockStatStep(),
    GoalStep(),
    AppSelectionStep(),
    FrictionStep(),
    PermissionStep(),
    ReadyStep(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current < _totalPages - 1) {
      _goToPage(current + 1);
    }
  }

  void _prevPage() {
    final current = ref.read(onboardingProvider).currentPage;
    if (current > 0) {
      _goToPage(current - 1);
    }
  }

  Future<void> _complete() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(onboardingProvider).currentPage;
    final isFirstPage = currentPage == 0;
    final isLastPage = currentPage == _totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isLastPage)
                    TextButton(
                      onPressed: () => _goToPage(_totalPages - 1),
                      child: Text(
                        'Skip',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                ],
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: _totalPages,
                onPageChanged: (page) {
                  ref.read(onboardingProvider.notifier).setPage(page);
                },
                itemBuilder: (context, index) => _steps[index],
              ),
            ),
            // Bottom navigation area
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                children: [
                  StepIndicator(currentStep: currentPage),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      // Back button
                      if (!isFirstPage)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _prevPage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.divider),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                              ),
                            ),
                            child: const Text('Back'),
                          ),
                        )
                      else
                        const Spacer(),
                      const SizedBox(width: AppSpacing.md),
                      // Next / Get Started / Complete button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isLastPage ? _complete : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textInverse,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                          ),
                          child: Text(
                            isFirstPage
                                ? 'Get Started'
                                : isLastPage
                                    ? 'Start Your Journey'
                                    : 'Next',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textInverse,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
