import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/theme/app_theme.dart';
import 'package:rendez/features/auth/auth_profile_screen.dart';
import 'package:rendez/features/navigation/main_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RendezApp()));
}

class RendezApp extends ConsumerStatefulWidget {
  const RendezApp({super.key});

  @override
  ConsumerState<RendezApp> createState() => _RendezAppState();
}

class _RendezAppState extends ConsumerState<RendezApp> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(authProvider).isLoggedIn;
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isLoggedIn == true && !next.isLoggedIn) {
        _navigator.currentState?.popUntil((route) => route.isFirst);
      }
    });
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Rendez',
      navigatorKey: _navigator,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: signedIn ? const MainScaffold() : const AuthProfileScreen(),
    );
  }
}
