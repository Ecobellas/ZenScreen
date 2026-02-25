import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('Statistics', style: AppTextStyles.headingMedium)),
      body: Center(
          child:
              Text('Statistics coming soon', style: AppTextStyles.bodyLarge)),
    );
  }
}
