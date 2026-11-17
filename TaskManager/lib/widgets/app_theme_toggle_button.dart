// TASKMANAGER_UI_V1
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppThemeToggleButton extends StatelessWidget {
  const AppThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, _) {
        final dark = AppThemeController.instance.isDark;
        return IconButton(
          tooltip: dark
              ? 'B\u1EADt ch\u1EBF \u0111\u1ED9 s\u00E1ng'
              : 'B\u1EADt ch\u1EBF \u0111\u1ED9 t\u1ED1i',
          icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          onPressed: () => AppThemeController.instance.toggle(),
        );
      },
    );
  }
}