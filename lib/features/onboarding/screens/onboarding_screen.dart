import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/providers.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to ZenScreen', style: AppTextStyles.headingLarge),
            const SizedBox(height: 16),
            Text('Mindful screen time control',
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () async {
                await ref
                    .read(preferencesServiceProvider)
                    .setOnboardingComplete(true);
                if (context.mounted) context.go('/dashboard');
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
