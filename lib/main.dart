import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await configureDependencies();
  
  runApp(const CherryNoteApp());
}

class CherryNoteApp extends StatelessWidget {
  const CherryNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cherry Note',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: GetIt.instance<AppRouter>().router,
      debugShowCheckedModeBanner: false,
    );
  }
}