import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/screens/details_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screens.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/success_screen.dart';
import '../features/listings/presentation/screens/listing_detail_screen.dart';
import '../features/shell/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge the auth state to GoRouter so the redirect re-runs on sign-in/out.
  final authListenable = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (_, __) {
    authListenable.value++;
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authListenable,
    redirect: (ctx, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      // Multi-step signup keeps issuing API calls (OTP, details) after the
      // user is authenticated, so we keep those screens reachable while
      // signed in. Only the entry-point auth screens redirect away.
      final isAuthEntry = loc == '/login' || loc == '/signup' || loc == '/forgot/email';

      if (auth.status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }
      if (auth.status == AuthStatus.signedOut) {
        final isAuthFlow = loc.startsWith('/login') ||
            loc.startsWith('/signup') ||
            loc.startsWith('/forgot');
        return isAuthFlow ? null : '/login';
      }
      // signedIn
      if (loc == '/splash' || isAuthEntry) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
        routes: [
          GoRoute(path: 'otp', builder: (_, __) => const OtpScreen()),
          GoRoute(path: 'details', builder: (_, __) => const DetailsScreen()),
          GoRoute(
            path: 'done',
            builder: (_, __) => const SuccessScreen(
              title: "You're all set!",
              subtitle:
                  'Your account has been created. Redirecting you to sign in…',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/forgot/email',
        builder: (_, __) => const FpEmailScreen(),
      ),
      GoRoute(
        path: '/forgot/otp',
        builder: (_, __) => const FpOtpScreen(),
      ),
      GoRoute(
        path: '/forgot/new',
        builder: (_, __) => const FpNewPwScreen(),
      ),
      GoRoute(
        path: '/forgot/done',
        builder: (_, __) => const SuccessScreen(
          title: 'Password reset!',
          subtitle:
              'Your password has been updated. Redirecting you to sign in…',
        ),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const MainShell(),
      ),
      GoRoute(
        path: '/detail/:type/:uid',
        builder: (ctx, state) => ListingDetailScreen(
          type: state.pathParameters['type']!,
          uid: state.pathParameters['uid']!,
        ),
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
