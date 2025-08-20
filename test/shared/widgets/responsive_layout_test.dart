import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/shared/widgets/responsive_layout.dart';

void main() {
  group('Breakpoints', () {
    test('has correct breakpoint values', () {
      expect(Breakpoints.mobile, 600);
      expect(Breakpoints.tablet, 900);
      expect(Breakpoints.desktop, 1200);
      expect(Breakpoints.largeDesktop, 1600);
    });
  });

  group('ResponsiveLayout.getScreenSize', () {
    test('returns correct screen size for different widths', () {
      expect(ResponsiveLayout.getScreenSize(500), ScreenSize.mobile);
      expect(ResponsiveLayout.getScreenSize(700), ScreenSize.tablet);
      expect(ResponsiveLayout.getScreenSize(1000), ScreenSize.desktop);
      expect(ResponsiveLayout.getScreenSize(1700), ScreenSize.largeDesktop);
    });

    test('returns correct screen size for boundary values', () {
      expect(ResponsiveLayout.getScreenSize(600), ScreenSize.tablet);
      expect(ResponsiveLayout.getScreenSize(900), ScreenSize.desktop);
      expect(ResponsiveLayout.getScreenSize(1200), ScreenSize.desktop);
      expect(ResponsiveLayout.getScreenSize(1600), ScreenSize.largeDesktop);
    });
  });

  group('ResponsiveLayout', () {
    testWidgets('renders mobile layout for small screens', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              mobile: const Text('Mobile'),
              tablet: const Text('Tablet'),
              desktop: const Text('Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('renders tablet layout for medium screens', (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              mobile: const Text('Mobile'),
              tablet: const Text('Tablet'),
              desktop: const Text('Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('renders desktop layout for large screens', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              mobile: const Text('Mobile'),
              tablet: const Text('Tablet'),
              desktop: const Text('Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsOneWidget);
    });

    testWidgets('falls back to mobile when tablet is not provided', (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              mobile: const Text('Mobile'),
              desktop: const Text('Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
    });
  });

  group('ResponsiveBuilder', () {
    testWidgets('provides correct screen size to builder', (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 800));
      
      ScreenSize? capturedScreenSize;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBuilder(
              builder: (context, screenSize) {
                capturedScreenSize = screenSize;
                return Text('Screen: ${screenSize.name}');
              },
            ),
          ),
        ),
      );

      expect(capturedScreenSize, ScreenSize.tablet);
      expect(find.text('Screen: tablet'), findsOneWidget);
    });
  });

  group('ResponsiveValue', () {
    test('returns correct value for different screen sizes', () {
      const responsiveValue = ResponsiveValue<int>(
        mobile: 1,
        tablet: 2,
        desktop: 3,
        largeDesktop: 4,
      );

      expect(responsiveValue.getValue(ScreenSize.mobile), 1);
      expect(responsiveValue.getValue(ScreenSize.tablet), 2);
      expect(responsiveValue.getValue(ScreenSize.desktop), 3);
      expect(responsiveValue.getValue(ScreenSize.largeDesktop), 4);
    });

    test('falls back to smaller screen values when not provided', () {
      const responsiveValue = ResponsiveValue<int>(
        mobile: 1,
        desktop: 3,
      );

      expect(responsiveValue.getValue(ScreenSize.mobile), 1);
      expect(responsiveValue.getValue(ScreenSize.tablet), 1); // Falls back to mobile
      expect(responsiveValue.getValue(ScreenSize.desktop), 3);
      expect(responsiveValue.getValue(ScreenSize.largeDesktop), 3); // Falls back to desktop
    });
  });

  group('ResponsivePadding', () {
    testWidgets('applies correct padding for screen size', (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 800));
      
      const responsivePadding = ResponsiveValue<EdgeInsetsGeometry>(
        mobile: EdgeInsets.all(8),
        tablet: EdgeInsets.all(16),
        desktop: EdgeInsets.all(24),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsivePadding(
              padding: responsivePadding,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, const EdgeInsets.all(16));
    });
  });

  group('ResponsiveColumns', () {
    testWidgets('shows only center column on mobile by default', (tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveColumns(
              left: const Text('Left'),
              center: const Text('Center'),
              right: const Text('Right'),
            ),
          ),
        ),
      );

      expect(find.text('Left'), findsNothing);
      expect(find.text('Center'), findsOneWidget);
      expect(find.text('Right'), findsNothing);
    });

    testWidgets('shows left and center columns on tablet', (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveColumns(
              left: const Text('Left'),
              center: const Text('Center'),
              right: const Text('Right'),
            ),
          ),
        ),
      );

      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Center'), findsOneWidget);
      expect(find.text('Right'), findsNothing);
    });

    testWidgets('shows all columns on desktop', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveColumns(
              left: const Text('Left'),
              center: const Text('Center'),
              right: const Text('Right'),
            ),
          ),
        ),
      );

      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Center'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
    });
  });

  group('ScreenSizeExtension', () {
    testWidgets('provides correct screen size properties', (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 800));
      
      bool? isMobile, isTablet, isDesktop, isLargeDesktop;
      ScreenSize? screenSize;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                isMobile = context.isMobile;
                isTablet = context.isTablet;
                isDesktop = context.isDesktop;
                isLargeDesktop = context.isLargeDesktop;
                screenSize = context.screenSize;
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      expect(isMobile, false);
      expect(isTablet, true);
      expect(isDesktop, false);
      expect(isLargeDesktop, false);
      expect(screenSize, ScreenSize.tablet);
    });
  });
}