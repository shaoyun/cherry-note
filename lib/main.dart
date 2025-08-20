import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/error/global_error_handler.dart';
import 'core/error/error_logger.dart';
import 'core/feedback/feedback_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize global error handling
  GlobalErrorHandler.initialize();
  
  // Initialize error logger
  await ErrorLogger().initialize();
  
  // Initialize dependency injection
  await configureDependencies();
  
  runApp(const CherryNoteApp());
}

class CherryNoteApp extends StatelessWidget {
  const CherryNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FeedbackListener(
      displayStyle: FeedbackDisplayStyle.toast,
      child: MaterialApp.router(
        title: 'Cherry Note',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: GetIt.instance<AppRouter>().router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return GlobalErrorListener(
            showSnackBars: true,
            showDialogs: true,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}