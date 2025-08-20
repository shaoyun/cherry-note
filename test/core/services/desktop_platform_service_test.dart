import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/core/services/desktop_platform_service.dart';

void main() {
  group('DesktopPlatformService', () {
    late DesktopPlatformService service;

    setUp(() {
      service = DesktopPlatformService();
    });

    test('getPlatformInfo should return desktop platform information', () async {
      final info = await service.getPlatformInfo();
      
      expect(info, isA<Map<String, dynamic>>());
      // On non-desktop platforms, should return empty map
    });

    test('getSystemDirectories should return system directories', () async {
      final directories = await service.getSystemDirectories();
      
      expect(directories, isA<Map<String, String?>>());
      expect(directories.containsKey('documents'), isTrue);
      expect(directories.containsKey('downloads'), isTrue);
    });

    testWidgets('createDesktopUI should wrap child with desktop adaptations', (tester) async {
      const testWidget = Text('Test');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: service.createDesktopUI(
                child: testWidget,
                context: context,
              ),
            ),
          ),
        ),
      );
      
      expect(find.text('Test'), findsOneWidget);
      expect(find.byType(MediaQuery), findsWidgets);
    });

    testWidgets('createDesktopAppBar should create appropriate app bar', (tester) async {
      final appBar = service.createDesktopAppBar(
        title: 'Test App',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: appBar,
            body: const Text('Test Body'),
          ),
        ),
      );
      
      expect(find.text('Test App'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    test('handleApplicationExit should return boolean', () async {
      final shouldExit = await service.handleApplicationExit();
      
      expect(shouldExit, isA<bool>());
    });

    test('dispose should clean up resources', () {
      expect(() => service.dispose(), returnsNormally);
    });
  });
}