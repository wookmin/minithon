import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/login_screen.dart';
import 'features/dev_input/dev_input_screen.dart';
import 'features/general/general_screen.dart';
import 'features/home/home_dashboard_screen.dart';
import 'features/hospital/hospital_screen.dart';
import 'features/my/my_page_screen.dart';
import 'features/professional/professional_screen.dart';
import 'features/recording/recording_setup_screen.dart';
import 'features/shell/home_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter({String initialLocation = '/login'}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
        path: '/dev-input',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => DevInputScreen(
          autoAnalyzeLatest: state.uri.queryParameters['auto'] == '1',
        ),
      ),
    ],
  );
}
