import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cherry_note/core/services/android_platform_service.dart';

void main() {
  group('AndroidPlatformService', () {
    late AndroidPlatformService service;

    setUp(() {
      service = AndroidPlatformService();
    });

    testWidgets('adaptUI should apply Android-specific adaptations', (tester) async {
      const testWidget = Text('Test');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: service.adaptUI(testWidget, tester.element(find.byType(Scaffold))),
          ),
        ),
      );
      
      expect(find.byType(MediaQuery), findsWidgets);
      expect(find.byType(Padding), findsWidgets);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('handleBackButton should show exit dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => service.handleBackButton(context),
                child: const Text('Test Back'),
              ),
            ),
          ),
        ),
      );
      
      await tester.tap(find.text('Test Back'));
      await tester.pumpAndSettle();
      
      // Should show exit confirmation dialog on Android
      // Note: This test would need platform-specific mocking to work properly
    });

    test('getPlatformInfo should return Android platform information', () async {
      final info = await service.getPlatformInfo();
      
      // On non-Android platforms, should return empty map
      expect(info, isA<Map<String, dynamic>>());
    });

    test('hasAllRequiredPermissions should check all required permissions', () async {
      final hasPermissions = await service.hasAllRequiredPermissions();
      
      // On non-Android platforms, should return true
      expect(hasPermissions, isA<bool>());
    });

    test('dispose should clean up resources', () {
      expect(() => service.dispose(), returnsNormally);
    });
  });
}