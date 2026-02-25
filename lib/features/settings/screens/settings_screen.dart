import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('Settings', style: AppTextStyles.headingMedium)),
      body:
          Center(child: Text('Settings coming soon', style: AppTextStyles.bodyLarge)),
    );
  }
}
