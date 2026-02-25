import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('ZenScreen', style: AppTextStyles.headingMedium)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 6),
              ),
              child: Center(
                child: Text('85',
                    style: AppTextStyles.metricLarge
                        .copyWith(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Digital Health Score', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Text('Today', style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
