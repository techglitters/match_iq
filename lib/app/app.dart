import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'app_theme.dart';

class ConnectGrowApp extends StatelessWidget {
  const ConnectGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connect & Grow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
