import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/error/global_error_handler.dart';
import 'core/error/error_logger.dart';
import 'core/feedback/feedback_widgets.dart';
import 'core/ui/web_ui_adaptations.dart';
import 'core/services/web_platform_service.dart';
import 'core/error/error_display_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Web-specific initialization
  if (kIsWeb) {
    // Update page title for web
    WebPlatformService.updateTitle('Cherry Note - 专业的跨平台云端笔记应用');
    
    // Check browser compatibility
    if (!WebPlatformService.supportsRequiredFeatures) {
      debugPrint('Warning: Browser may not support all features');
    }
  }
  
  // Initialize global error handling
  GlobalErrorHandler.initialize();
  
  // Initialize error logger (safe for all platforms)
  try {
    await ErrorLogger().initialize();
  } catch (e) {
    debugPrint('Error logger initialization failed: $e');
  }
  
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
      theme: kIsWeb 
        ? WebUIAdaptations.adaptThemeForWeb(AppTheme.lightTheme, context)
        : AppTheme.lightTheme,
      darkTheme: kIsWeb 
        ? WebUIAdaptations.adaptThemeForWeb(AppTheme.darkTheme, context)
        : AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: GetIt.instance<AppRouter>().router,
      debugShowCheckedModeBanner: false,
      scrollBehavior: kIsWeb 
        ? WebUIAdaptations.getWebScrollBehavior()
        : null,
      builder: (context, child) {
        return FeedbackListener(
          displayStyle: FeedbackDisplayStyle.toast,
          child: GlobalErrorListener(
            showSnackBars: true,
            showDialogs: true,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}