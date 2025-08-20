import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// Web-specific platform service for Cherry Note
class WebPlatformService {
  static const String _storagePrefix = 'cherry_note_';

  /// Check if running in web environment
  static bool get isWeb => kIsWeb;

  /// Get browser information
  static String get browserInfo {
    if (!kIsWeb) return 'Not Web';
    return '${html.window.navigator.userAgent}';
  }

  /// Check if browser supports required features
  static bool get supportsRequiredFeatures {
    if (!kIsWeb) return false;
    
    // Check for required web APIs
    return html.window.localStorage != null &&
           js.context.hasProperty('fetch') &&
           html.window.navigator.onLine != null;
  }

  /// Get current URL
  static String get currentUrl {
    if (!kIsWeb) return '';
    return html.window.location.href;
  }

  /// Update page title
  static void updateTitle(String title) {
    if (!kIsWeb) return;
    html.document.title = title;
  }

  /// Show browser notification (if supported)
  static Future<void> showNotification(String title, String body) async {
    if (!kIsWeb) return;
    
    try {
      final permission = await html.Notification.requestPermission();
      if (permission == 'granted') {
        html.Notification(title, body: body);
      }
    } catch (e) {
      debugPrint('Notification not supported: $e');
    }
  }

  /// Download file in browser
  static void downloadFile(String filename, List<int> bytes, String mimeType) {
    if (!kIsWeb) return;
    
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// Check if device is mobile (responsive design)
  static bool get isMobileDevice {
    if (!kIsWeb) return false;
    return html.window.innerWidth! < 768;
  }

  /// Check if device is tablet
  static bool get isTabletDevice {
    if (!kIsWeb) return false;
    final width = html.window.innerWidth!;
    return width >= 768 && width < 1024;
  }

  /// Check if device is desktop
  static bool get isDesktopDevice {
    if (!kIsWeb) return false;
    return html.window.innerWidth! >= 1024;
  }

  /// Get device pixel ratio
  static double get devicePixelRatio {
    if (!kIsWeb) return 1.0;
    return (html.window.devicePixelRatio ?? 1.0).toDouble();
  }

  /// Check if browser supports PWA installation
  static bool get supportsPWAInstall {
    if (!kIsWeb) return false;
    return js.context.hasProperty('BeforeInstallPromptEvent');
  }

  /// Trigger PWA install prompt
  static Future<bool> promptPWAInstall() async {
    if (!kIsWeb || !supportsPWAInstall) return false;
    
    try {
      // This would be handled by beforeinstallprompt event
      // Implementation depends on specific PWA setup
      return false;
    } catch (e) {
      debugPrint('PWA install prompt failed: $e');
      return false;
    }
  }

  /// Check if app is running as PWA
  static bool get isRunningAsPWA {
    if (!kIsWeb) return false;
    try {
      return html.window.matchMedia('(display-mode: standalone)').matches;
    } catch (e) {
      return false;
    }
  }

  /// Get preferred language
  static String get preferredLanguage {
    if (!kIsWeb) return 'en';
    return html.window.navigator.language ?? 'en';
  }

  /// Check if browser is online
  static bool get isOnline {
    if (!kIsWeb) return true;
    return html.window.navigator.onLine ?? true;
  }

  /// Listen to online/offline status changes
  static Stream<bool> get onlineStatusStream {
    if (!kIsWeb) return Stream.value(true);
    
    return html.window.onOnline.map((_) => true)
        .mergeWith([html.window.onOffline.map((_) => false)]);
  }
}

extension on Stream<bool> {
  Stream<bool> mergeWith(List<Stream<bool>> others) {
    return Stream.multi((controller) {
      final subscriptions = <Stream<bool>>[this, ...others]
          .map((stream) => stream.listen(controller.add))
          .toList();
      
      controller.onCancel = () {
        for (final subscription in subscriptions) {
          subscription.cancel();
        }
      };
    });
  }
}