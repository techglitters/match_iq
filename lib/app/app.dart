import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/persistence/progress_store.dart';
import '../core/persistence/shared_preferences_progress_store.dart';
import '../features/themes/data/theme_catalog.dart';
import '../features/themes/presentation/controllers/app_progress_controller.dart';
import 'active_theme_shell.dart';
import 'app_routes.dart';
import 'app_theme.dart';

class ConnectGrowApp extends StatelessWidget {
  const ConnectGrowApp({super.key, this.progressStore});

  final ProgressStore? progressStore;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProgressController(
        store: progressStore ?? SharedPreferencesProgressStore(),
        themes: ThemeCatalog.all,
      ),
      child: MaterialApp(
        title: 'Link & Learn',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        builder: (context, child) {
          return ActiveThemeShell(child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}
