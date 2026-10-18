import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Auth.init(); // stays off (and harmless) until Firebase is set up
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..load(),
      child: const Waste2TasteApp(),
    ),
  );
}

class Waste2TasteApp extends StatelessWidget {
  const Waste2TasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waste2Taste',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Keep the app phone-sized on wide screens (Chrome/desktop), centered with equal margins.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFF2B1A12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ClipRect(
              // Slightly smaller text so content fits a phone screen better.
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(0.9)),
                child: child!,
              ),
            ),
          ),
        ),
      ),
      home: const _Start(),
    );
  }
}

/// Picks the first screen: onboarding → login → app.
class _Start extends StatelessWidget {
  const _Start();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (!app.loaded) return const Scaffold(backgroundColor: W2T.rust);
    if (!app.seenOnboarding) return const OnboardingScreen();
    if (app.userName == null) return const LoginScreen();
    return const HomeShell();
  }
}
