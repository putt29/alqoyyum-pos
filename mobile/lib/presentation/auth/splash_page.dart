import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/config.dart';
import '../../widgets/common.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          AppLogo(height: 190, full: true),
          SizedBox(height: 22),
          Text(AppConfig.clinicName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy, letterSpacing: 0.5)),
          SizedBox(height: 22),
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.navy),
          ),
        ]),
      ),
    );
  }
}
