import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/language_selection_page.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/language/providers/language_provider.dart';
import 'features/splash/presentation/pages/splash_page.dart';

class NabhKrishiApp extends StatelessWidget {
  const NabhKrishiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NabhKrishi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSplashFinished = ref.watch(isSplashFinishedProvider);
    final authState = ref.watch(authStateChangesProvider);
    final language = ref.watch(languageProvider);

    Widget activeWidget;
    if (!isSplashFinished) {
      activeWidget = const SplashPage();
    } else {
      activeWidget = authState.when(
        data: (user) {
          if (user != null) {
            return HomePage(language: language);
          } else {
            return const LanguageSelectionPage();
          }
        },
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF041525),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF6CE8BE)),
          ),
        ),
        error: (e, _) => const LanguageSelectionPage(),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: activeWidget,
    );
  }
}
