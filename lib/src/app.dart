import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'home_shell.dart';

/// Lets the user drag to scroll (and pull-to-refresh) with a mouse/trackpad,
/// not just touch — essential on desktop where the default behaviour ignores
/// mouse drags.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}

class KickOffApp extends ConsumerWidget {
  const KickOffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'KickOff',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Defaults to the signature black & teal; user can switch in Settings.
      themeMode: ref.watch(themeModeProvider),
      home: const HomeShell(),
    );
  }
}
