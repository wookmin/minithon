import 'dart:async';
import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_needs/app.dart';
import 'package:senior_needs/core/firebase/firebase_providers.dart';
import 'package:senior_needs/features/auth/auth_providers.dart';
import 'package:senior_needs/features/auth/auth_repository.dart';
import 'package:senior_needs/features/care/care_providers.dart';
import 'package:senior_needs/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 성공을 시뮬레이션하는 가짜 인증 저장소.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({AppUser? initialUser}) : _currentUser = initialUser;

  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _currentUser = AppUser(uid: 'test-user', email: email);
    _controller.add(_currentUser);
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    _currentUser = AppUser(uid: 'test-user', email: email, displayName: name);
    _controller.add(_currentUser);
  }

  @override
  Future<void> signInWithGoogle() async {
    _currentUser = const AppUser(uid: 'google-user');
    _controller.add(_currentUser);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

/// 지정 uid에 돌봄 대상자 1명을 미리 넣은 가짜 Firestore.
Future<FakeFirebaseFirestore> _firestoreWithRecipient(String uid) async {
  final firestore = FakeFirebaseFirestore();
  await firestore
      .collection('users')
      .doc(uid)
      .collection('recipients')
      .doc('r1')
      .set(const {
        'id': 'r1',
        'name': '김순자',
        'phoneNumber': '010-1234-5678',
        'relationship': '어머니',
        'address': '전북 남원시 향단로 10',
        'favoriteHospital': '남원의료원',
      });
  return firestore;
}

Future<void> _pumpApp(
  WidgetTester tester, {
  String initialLocation = '/login',
  _FakeAuthRepository? authRepository,
  FakeFirebaseFirestore? firestore,
}) async {
  // 자동 분석을 켜진 상태로 시드해 홈에서 설정 유도 시트가 뜨지 않게 한다.
  SharedPreferences.setMockInitialValues({
    'recordingSetupState':
        '{"isCompleted":true,"backgroundDetectionEnabled":true}',
  });
  final prefs = await SharedPreferences.getInstance();
  final auth = authRepository ?? _FakeAuthRepository();
  addTearDown(auth.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(auth),
        firebaseFirestoreProvider.overrideWithValue(
          firestore ?? FakeFirebaseFirestore(),
        ),
      ],
      child: SeniorNeedsApp(
        router: createRouter(
          initialLocation: initialLocation,
          authRepository: auth,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('앱은 로그인 화면에서 시작한다', (tester) async {
    await _pumpApp(tester);

    expect(find.text('똥강아지'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('대상자가 있으면 로그인 후 홈으로 이동하고 탭 전환이 된다', (tester) async {
    await _pumpApp(
      tester,
      firestore: await _firestoreWithRecipient('test-user'),
    );

    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    expect(find.text('오늘 확인할 일정'), findsOneWidget);

    final errandTab = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('심부름'),
    );
    await tester.tap(errandTab);
    await tester.pumpAndSettle();

    expect(find.text('지역 심부름'), findsOneWidget);
  });

  testWidgets('대상자가 없으면 로그인 후 온보딩으로 이동한다', (tester) async {
    await _pumpApp(tester);

    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    expect(find.text('누구를 돌보고 계신가요?'), findsOneWidget);
  });

  testWidgets('회원가입 이름은 내 정보 기본값으로 저장된다', (tester) async {
    await _pumpApp(tester, initialLocation: '/signup');

    await tester.enterText(find.byType(TextField).at(0), '이민욱');
    await tester.enterText(find.byType(TextField).at(1), 'minwook@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, '가입하고 시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('누구를 돌보고 계신가요?'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('myProfile')!);
    expect(saved['name'], '이민욱');
    expect(saved['phoneNumber'], '');
  });

  testWidgets('미로그인 딥링크는 로그인 화면으로 보호된다', (tester) async {
    await _pumpApp(tester, initialLocation: '/general');

    expect(find.text('똥강아지'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
  });

  testWidgets('로그인 상태에서는 로그인 화면을 건너뛰고 홈으로 간다', (tester) async {
    await _pumpApp(
      tester,
      authRepository: _FakeAuthRepository(
        initialUser: const AppUser(uid: 'signed-in-user'),
      ),
      firestore: await _firestoreWithRecipient('signed-in-user'),
    );

    expect(find.text('오늘 확인할 일정'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '로그인'), findsNothing);
  });

  testWidgets('딥링크 보호 후 로그인하면 원래 경로로 돌아간다', (tester) async {
    await _pumpApp(
      tester,
      initialLocation: '/analysis-history',
      firestore: await _firestoreWithRecipient('test-user'),
    );

    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    expect(find.text('통화 분석 모아보기'), findsOneWidget);
  });
}
