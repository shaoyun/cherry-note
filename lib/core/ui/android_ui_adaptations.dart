import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android-specific UI adaptations and optimizations
class AndroidUIAdaptations {
  
  /// Configure Android-specific system UI
  static void configureSystemUI() {
    if (!Platform.isAndroid) return;
    
    // Configure system navigation bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Enable edge-to-edge display
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }
  
  /// Get Android-specific safe area padding
  static EdgeInsets getAndroidSafeAreaPadding(BuildContext context) {
    if (!Platform.isAndroid) return EdgeInsets.zero;
    
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
    );
  }
  
  /// Get Android-specific app bar height
  static double getAndroidAppBarHeight(BuildContext context) {
    if (!Platform.isAndroid) return kToolbarHeight;
    
    final mediaQuery = MediaQuery.of(context);
    return kToolbarHeight + mediaQuery.padding.top;
  }
  
  /// Create Android-specific floating action button
  static Widget createAndroidFAB({
    required VoidCallback onPressed,
    required Widget icon,
    String? tooltip,
  }) {
    if (!Platform.isAndroid) {
      return FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        child: icon,
      );
    }
    
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: icon,
      label: Text(tooltip ?? ''),
      elevation: 6.0,
      highlightElevation: 12.0,
    );
  }
  
  /// Create Android-specific bottom navigation bar
  static Widget createAndroidBottomNavBar({
    required int currentIndex,
    required List<BottomNavigationBarItem> items,
    required ValueChanged<int> onTap,
  }) {
    if (!Platform.isAndroid) {
      return BottomNavigationBar(
        currentIndex: currentIndex,
        items: items,
        onTap: onTap,
      );
    }
    
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: items.map((item) => NavigationDestination(
        icon: item.icon,
        selectedIcon: item.activeIcon ?? item.icon,
        label: item.label ?? '',
      )).toList(),
    );
  }
  
  /// Handle Android back button
  static Future<bool> handleAndroidBackButton(BuildContext context) async {
    if (!Platform.isAndroid) return false;
    
    // Check if there are any dialogs or overlays to close first
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return true;
    }
    
    // Show exit confirmation dialog
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    
    return shouldExit ?? false;
  }
  
  /// Configure Android-specific text scaling
  static TextScaler getAndroidTextScaler(BuildContext context) {
    if (!Platform.isAndroid) return TextScaler.noScaling;
    
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);
    
    // Limit text scaling on Android to prevent UI breaking
    final clampedScale = textScaleFactor.clamp(0.8, 1.3);
    return TextScaler.linear(clampedScale);
  }
  
  /// Create Android-specific context menu
  static Widget createAndroidContextMenu({
    required Widget child,
    required List<PopupMenuEntry> menuItems,
  }) {
    if (!Platform.isAndroid) {
      return child;
    }
    
    return GestureDetector(
      onLongPress: () {
        // Show context menu on long press
      },
      child: child,
    );
  }
  
  /// Handle Android-specific keyboard visibility
  static void handleAndroidKeyboard(BuildContext context) {
    if (!Platform.isAndroid) return;
    
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    
    if (isKeyboardVisible) {
      // Adjust UI when keyboard is visible
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    } else {
      // Reset UI when keyboard is hidden
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white,
        ),
      );
    }
  }
  
  /// Get Android-specific ripple effect
  static Widget createAndroidRipple({
    required Widget child,
    required VoidCallback onTap,
    Color? rippleColor,
  }) {
    if (!Platform.isAndroid) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: rippleColor?.withOpacity(0.3),
        highlightColor: rippleColor?.withOpacity(0.1),
        child: child,
      ),
    );
  }
}