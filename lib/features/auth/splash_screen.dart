import 'package:flutter/material.dart';

import '../../core/ui/brand_logo.dart';

/// 인증 상태(토큰) 확인 중 잠깐 보이는 화면. 확정되면 게이트가 홈/로그인으로 보낸다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(size: 64, radius: 18),
            const SizedBox(height: 20),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
