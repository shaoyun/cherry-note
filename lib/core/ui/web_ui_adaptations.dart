import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import '../services/web_platform_service.dart';

/// Web-specific UI adaptations for Cherry Note
class WebUIAdaptations {
  
  /// Get responsive breakpoints for web
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;

  /// Get layout type based on screen width
  static LayoutType getLayoutType(BuildContext context) {
    if (!kIsWeb) return LayoutType.desktop;
    
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return LayoutType.mobile;
    if (width < tabletBreakpoint) return LayoutType.tablet;
    return LayoutType.desktop;
  }

  /// Get responsive padding based on layout type
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final layoutType = getLayoutType(context);
    switch (layoutType) {
      case LayoutType.mobile:
        return const EdgeInsets.all(8.0);
      case LayoutType.tablet:
        return const EdgeInsets.all(16.0);
      case LayoutType.desktop:
        return const EdgeInsets.all(24.0);
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final layoutType = getLayoutType(context);
    switch (layoutType) {
      case LayoutType.mobile:
        return baseFontSize * 0.9;
      case LayoutType.tablet:
        return baseFontSize;
      case LayoutType.desktop:
        return baseFontSize * 1.1;
    }
  }

  /// Get responsive column count for grid layouts
  static int getResponsiveColumnCount(BuildContext context) {
    final layoutType = getLayoutType(context);
    switch (layoutType) {
      case LayoutType.mobile:
        return 1;
      case LayoutType.tablet:
        return 2;
      case LayoutType.desktop:
        return 3;
    }
  }

  /// Get responsive sidebar width
  static double getResponsiveSidebarWidth(BuildContext context) {
    final layoutType = getLayoutType(context);
    switch (layoutType) {
      case LayoutType.mobile:
        return MediaQuery.of(context).size.width * 0.8;
      case LayoutType.tablet:
        return 300;
      case LayoutType.desktop:
        return 350;
    }
  }

  /// Check if sidebar should be persistent
  static bool shouldShowPersistentSidebar(BuildContext context) {
    return getLayoutType(context) == LayoutType.desktop;
  }

  /// Get responsive app bar height
  static double getResponsiveAppBarHeight(BuildContext context) {
    final layoutType = getLayoutType(context);
    switch (layoutType) {
      case LayoutType.mobile:
        return kToolbarHeight;
      case LayoutType.tablet:
        return kToolbarHeight + 8;
      case LayoutType.desktop:
        return kToolbarHeight + 16;
    }
  }

  /// Get web-specific scroll behavior
  static ScrollBehavior getWebScrollBehavior() {
    return const MaterialScrollBehavior().copyWith(
      dragDevices: {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      },
    );
  }

  /// Get responsive dialog constraints
  static BoxConstraints getResponsiveDialogConstraints(BuildContext context) {
    final layoutType = getLayoutType(context);
    final screenSize = MediaQuery.of(context).size;
    
    switch (layoutType) {
      case LayoutType.mobile:
        return BoxConstraints(
          maxWidth: screenSize.width * 0.95,
          maxHeight: screenSize.height * 0.9,
        );
      case LayoutType.tablet:
        return BoxConstraints(
          maxWidth: 600,
          maxHeight: screenSize.height * 0.8,
        );
      case LayoutType.desktop:
        return BoxConstraints(
          maxWidth: 800,
          maxHeight: screenSize.height * 0.8,
        );
    }
  }

  /// Get responsive button size
  static Size getResponsiveButtonSize(BuildContext context) {
    final layoutType = getLayoutType(context);
    switch (layoutType) {
      case LayoutType.mobile:
        return const Size(120, 40);
      case LayoutType.tablet:
        return const Size(140, 44);
      case LayoutType.desktop:
        return const Size(160, 48);
    }
  }

  /// Get web-specific theme adaptations
  static ThemeData adaptThemeForWeb(ThemeData baseTheme, BuildContext context) {
    final layoutType = getLayoutType(context);
    
    return baseTheme.copyWith(
      // Adjust text theme for web
      textTheme: baseTheme.textTheme.copyWith(
        headlineLarge: baseTheme.textTheme.headlineLarge?.copyWith(
          fontSize: getResponsiveFontSize(context, 32),
        ),
        headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
          fontSize: getResponsiveFontSize(context, 28),
        ),
        headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
          fontSize: getResponsiveFontSize(context, 24),
        ),
        bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
          fontSize: getResponsiveFontSize(context, 16),
        ),
        bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
          fontSize: getResponsiveFontSize(context, 14),
        ),
      ),
      
      // Adjust app bar theme
      appBarTheme: baseTheme.appBarTheme.copyWith(
        toolbarHeight: getResponsiveAppBarHeight(context),
      ),
      
      // Adjust dialog theme
      dialogTheme: baseTheme.dialogTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(layoutType == LayoutType.mobile ? 8 : 12),
        ),
      ),
      
      // Adjust card theme
      cardTheme: baseTheme.cardTheme.copyWith(
        margin: getResponsivePadding(context),
      ),
    );
  }

  /// Create responsive layout builder
  static Widget responsiveBuilder({
    required Widget Function(BuildContext context, LayoutType layoutType) builder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutType = getLayoutType(context);
        return builder(context, layoutType);
      },
    );
  }

  /// Create web-optimized list view
  static Widget createWebOptimizedListView({
    required List<Widget> children,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return Scrollbar(
      controller: controller,
      child: ListView(
        controller: controller,
        padding: padding,
        children: children,
      ),
    );
  }

  /// Create responsive grid view
  static Widget createResponsiveGridView({
    required List<Widget> children,
    required BuildContext context,
    double childAspectRatio = 1.0,
    double crossAxisSpacing = 8.0,
    double mainAxisSpacing = 8.0,
  }) {
    final columnCount = getResponsiveColumnCount(context);
    
    return GridView.count(
      crossAxisCount: columnCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      padding: getResponsivePadding(context),
      children: children,
    );
  }
}

enum LayoutType {
  mobile,
  tablet,
  desktop,
}