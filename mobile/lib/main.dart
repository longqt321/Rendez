import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rendez/core/providers/app_providers.dart';
import 'package:rendez/core/theme/app_theme.dart';
import 'package:rendez/features/navigation/main_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RendezApp()));
}

class RendezApp extends ConsumerWidget {
  const RendezApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    const maxWidth = 1100.0;

    return MaterialApp(
      title: 'Rendez - Khám phá không gian & minh bạch giá',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        if (!kIsWeb) {
          return child ?? const SizedBox.shrink();
        }
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        );
      },
      home: const MainScaffold(),
    );
  }
}
