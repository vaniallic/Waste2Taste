import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
