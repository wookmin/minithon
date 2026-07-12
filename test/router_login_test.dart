import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/app.dart';
import 'package:senior_needs/features/care/care_providers.dart';
import 'package:senior_needs/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('앱은 로그인 화면에서 시작한다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: SeniorNeedsApp(router: createRouter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('시작하기'), findsOneWidget);

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('가까이'), findsOneWidget);
    expect(find.textContaining('케어 현황'), findsOneWidget);

    final hospitalTab = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('건강'),
    );
    await tester.tap(hospitalTab);
    await tester.pumpAndSettle();

    expect(find.text('가까운 병원 찾기'), findsOneWidget);
  });
}
