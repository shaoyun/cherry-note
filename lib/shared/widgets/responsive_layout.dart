import 'package:flutter/material.dart';

/// Breakpoints for responsive design
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;
}

/// Screen size enum
enum ScreenSize {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Responsive layout builder
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = getScreenSize(constraints.maxWidth);
        
        switch (screenSize) {
          case ScreenSize.mobile:
            return mobile;
          case ScreenSize.tablet:
            return tablet ?? mobile;
          case ScreenSize.desktop:
            return desktop ?? tablet ?? mobile;
          case ScreenSize.largeDesktop:
            return largeDesktop ?? desktop ?? tablet ?? mobile;
        }
      },
    );
  }

  static ScreenSize getScreenSize(double width) {
    if (width >= Breakpoints.largeDesktop) {
      return ScreenSize.largeDesktop;
    } else if (width >= Breakpoints.desktop) {
      return ScreenSize.desktop;
    } else if (width >= Breakpoints.tablet) {
      return ScreenSize.tablet;
    } else {
      return ScreenSize.mobile;
    }
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = ResponsiveLayout.getScreenSize(constraints.maxWidth);
        return builder(context, screenSize);
      },
    );
  }
}

/// Responsive value helper
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;
  final T? largeDesktop;
  
  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  T getValue(ScreenSize screenSize) {
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final ResponsiveValue<EdgeInsetsGeometry> padding;
  
  const ResponsivePadding({
    super.key,
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        return Padding(
          padding: padding.getValue(screenSize),
          child: child,
        );
      },
    );
  }
}

/// Responsive grid view
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final ResponsiveValue<int> crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  
  const ResponsiveGridView({
    super.key,
    required this.children,
    required this.crossAxisCount,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        return GridView.count(
          crossAxisCount: crossAxisCount.getValue(screenSize),
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
          padding: padding,
          physics: physics,
          shrinkWrap: shrinkWrap,
          children: children,
        );
      },
    );
  }
}

/// Responsive columns widget for three-pane layout
class ResponsiveColumns extends StatelessWidget {
  final Widget left;
  final Widget center;
  final Widget right;
  final ResponsiveValue<List<int>> flexValues;
  final double spacing;
  final bool showAllOnMobile;
  
  const ResponsiveColumns({
    super.key,
    required this.left,
    required this.center,
    required this.right,
    this.flexValues = const ResponsiveValue(
      mobile: [1],
      tablet: [2, 3],
      desktop: [2, 3, 5],
    ),
    this.spacing = 8.0,
    this.showAllOnMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        final flex = flexValues.getValue(screenSize);
        
        if (screenSize == ScreenSize.mobile && !showAllOnMobile) {
          // On mobile, show only center column by default
          return center;
        }
        
        final widgets = <Widget>[];
        
        if (flex.length >= 1) {
          widgets.add(Expanded(flex: flex[0], child: left));
        }
        
        if (flex.length >= 2) {
          if (widgets.isNotEmpty) {
            widgets.add(SizedBox(width: spacing));
          }
          widgets.add(Expanded(flex: flex[1], child: center));
        }
        
        if (flex.length >= 3) {
          if (widgets.isNotEmpty) {
            widgets.add(SizedBox(width: spacing));
          }
          widgets.add(Expanded(flex: flex[2], child: right));
        }
        
        return Row(children: widgets);
      },
    );
  }
}

/// Responsive sidebar layout
class ResponsiveSidebar extends StatelessWidget {
  final Widget sidebar;
  final Widget body;
  final double sidebarWidth;
  final bool showSidebarOnMobile;
  final VoidCallback? onToggleSidebar;
  
  const ResponsiveSidebar({
    super.key,
    required this.sidebar,
    required this.body,
    this.sidebarWidth = 280,
    this.showSidebarOnMobile = false,
    this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        if (screenSize == ScreenSize.mobile) {
          return Scaffold(
            body: body,
            drawer: showSidebarOnMobile 
                ? Drawer(
                    width: sidebarWidth,
                    child: sidebar,
                  )
                : null,
          );
        }
        
        return Row(
          children: [
            SizedBox(
              width: sidebarWidth,
              child: sidebar,
            ),
            Expanded(child: body),
          ],
        );
      },
    );
  }
}

/// Responsive layout builder with constraints
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;
  
  const ResponsiveLayoutBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: builder);
  }
}

/// Extension for getting screen size from context
extension ScreenSizeExtension on BuildContext {
  ScreenSize get screenSize {
    final width = MediaQuery.of(this).size.width;
    return ResponsiveLayout.getScreenSize(width);
  }
  
  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isTablet => screenSize == ScreenSize.tablet;
  bool get isDesktop => screenSize == ScreenSize.desktop;
  bool get isLargeDesktop => screenSize == ScreenSize.largeDesktop;
}