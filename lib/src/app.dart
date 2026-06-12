import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
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

class KickOffApp extends StatelessWidget {
  const KickOffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KickOff',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Black & teal is the signature look, so default to the dark theme.
      themeMode: ThemeMode.dark,
      home: const HomeShell(),
    );
  }
}
