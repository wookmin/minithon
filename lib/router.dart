import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/analysis/analysis_history_screen.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/dev_input/dev_input_screen.dart';
import 'features/general/general_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/home/home_dashboard_screen.dart';
import 'features/hospital/hospital_screen.dart';
import 'features/my/my_page_screen.dart';
import 'features/professional/professional_screen.dart';
import 'features/recording/recording_diagnostic_screen.dart';
import 'features/recording/recording_setup_screen.dart';
import 'features/shell/home_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter({
  String initialLocation = '/splash',
  AuthRepository? authRepository,
}) {
  final auth = authRepository ?? FirebaseAuthRepository();
  final gate = AuthGateNotifier(auth.authStateChanges());

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: gate,
    redirect: (context, state) {
      final location = state.uri.toString();
      final path = state.uri.path;
      const authRoutes = {'/login', '/signup'};

      // 인증 상태 확정 전 → 스플래시에서 대기 (원래 목적지는 from에 실어둔다).
      if (!gate.loaded) {
        return path == '/splash'
            ? null
            : '/splash?from=${Uri.encodeComponent(location)}';
      }

      final isSignedIn = gate.user != null;

      // 스플래시에서 확정되면 토큰 유무로 분기.
      if (path == '/splash') {
        final from = state.uri.queryParameters['from'];
        return isSignedIn ? _homeOrFrom(from) : _loginWithFrom(from);
      }

      if (!isSignedIn && !authRoutes.contains(path)) {
        return '/login?from=${Uri.encodeComponent(location)}';
      }
      if (isSignedIn && authRoutes.contains(path)) {
        return _homeOrFrom(state.uri.queryParameters['from']);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/general',
                builder: (context, state) => const GeneralScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/hospital',
                builder: (context, state) => const HospitalScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/professional',
                builder: (context, state) => const ProfessionalScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my',
                builder: (context, state) => const MyPageScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/recording-setup',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RecordingSetupScreen(),
      ),
      GoRoute(
        path: '/call-analysis',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => CallAnalysisScreen(
          autoAnalyzeLatest: state.uri.queryParameters['auto'] == '1',
          analyzeSharedAudio: state.uri.queryParameters['shared'] == '1',
        ),
      ),
      GoRoute(
        path: '/analysis-history',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AnalysisHistoryScreen(),
      ),
      GoRoute(
        path: '/recording-diagnostic',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RecordingDiagnosticScreen(),
      ),
    ],
  );
}

String? _homeOrFrom(String? from) {
  if (from == null || from.isEmpty) return '/home';
  final path = Uri.parse(from).path;
  if (path == '/login' || path == '/signup' || path == '/splash') {
    return '/home';
  }
  return from;
}

String _loginWithFrom(String? from) {
  if (from == null || from.isEmpty) return '/login';
  final path = Uri.parse(from).path;
  if (path == '/login' || path == '/signup' || path == '/splash') {
    return '/login';
  }
  return '/login?from=${Uri.encodeComponent(from)}';
}

/// 로그인 상태 스트림을 구독해 (확정 여부 + 사용자)를 들고 있는 라우터 갱신 소스.
class AuthGateNotifier extends ChangeNotifier {
  AuthGateNotifier(Stream<AppUser?> stream) {
    _subscription = stream.listen((user) {
      this.user = user;
      loaded = true;
      notifyListeners();
    });
  }

  AppUser? user;
  bool loaded = false;
  late final StreamSubscription<AppUser?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
