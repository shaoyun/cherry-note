import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/core/feedback/sync_status_widget.dart';

void main() {
  group('SyncStatusWidget', () {
    testWidgets('should display idle status correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusWidget(
              status: SyncStatus.idle,
              message: 'All files synced',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.text('已同步'), findsOneWidget);
    });

    testWidgets('should display syncing status with progress', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusWidget(
              status: SyncStatus.syncing,
              message: 'Syncing files...',
              progress: 0.5,
              showDetails: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('同步中'), findsOneWidget);
      expect(find.text('Syncing files...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error status with retry button', (tester) async {
      // Arrange
      var retryPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusWidget(
              status: SyncStatus.error,
              message: 'Sync failed',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('同步失败'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Act
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Assert
      expect(retryPressed, isTrue);
    });

    testWidgets('should display success status', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusWidget(
              status: SyncStatus.success,
              message: 'Sync completed',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('同步成功'), findsOneWidget);
    });

    testWidgets('should display conflict status', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusWidget(
              status: SyncStatus.conflict,
              message: 'Conflicts detected',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('存在冲突'), findsOneWidget);
    });

    testWidgets('should display offline status', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusWidget(
              status: SyncStatus.offline,
              message: 'No internet connection',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('离线'), findsOneWidget);
    });

    testWidgets('should show cancel button when syncing', (tester) async {
      // Arrange
      var cancelPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusWidget(
              status: SyncStatus.syncing,
              onCancel: () => cancelPressed = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Act
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Assert
      expect(cancelPressed, isTrue);
    });
  });

  group('CompactSyncStatusIndicator', () {
    testWidgets('should display compact status correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactSyncStatusIndicator(
              status: SyncStatus.success,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('成功'), findsOneWidget);
    });

    testWidgets('should handle tap callback', (tester) async {
      // Arrange
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactSyncStatusIndicator(
              status: SyncStatus.idle,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(CompactSyncStatusIndicator));
      await tester.pump();

      // Assert
      expect(tapped, isTrue);
    });
  });

  group('SyncStatusPanel', () {
    testWidgets('should display detailed sync information', (tester) async {
      // Arrange
      final lastSyncTime = DateTime.now().subtract(const Duration(minutes: 5));
      final recentFiles = ['file1.md', 'file2.md', 'file3.md'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusPanel(
              status: SyncStatus.success,
              message: 'All files synchronized',
              lastSyncTime: lastSyncTime,
              recentFiles: recentFiles,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('All files synchronized'), findsOneWidget);
      expect(find.text('上次同步: 5 分钟前'), findsOneWidget);
      expect(find.text('最近同步的文件:'), findsOneWidget);
      expect(find.text('file1.md'), findsOneWidget);
      expect(find.text('file2.md'), findsOneWidget);
      expect(find.text('file3.md'), findsOneWidget);
    });

    testWidgets('should show progress when syncing', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusPanel(
              status: SyncStatus.syncing,
              message: 'Syncing files...',
              progress: 0.75,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('75% 完成'), findsOneWidget);
    });

    testWidgets('should show retry button on error', (tester) async {
      // Arrange
      var retryPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusPanel(
              status: SyncStatus.error,
              message: 'Sync failed',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('重试'), findsOneWidget);

      // Act
      await tester.tap(find.text('重试'));
      await tester.pump();

      // Assert
      expect(retryPressed, isTrue);
    });

    testWidgets('should show cancel button when syncing', (tester) async {
      // Arrange
      var cancelPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusPanel(
              status: SyncStatus.syncing,
              onCancel: () => cancelPressed = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('取消'), findsOneWidget);

      // Act
      await tester.tap(find.text('取消'));
      await tester.pump();

      // Assert
      expect(cancelPressed, isTrue);
    });

    testWidgets('should show view details button for many files', (tester) async {
      // Arrange
      final manyFiles = List.generate(10, (index) => 'file$index.md');
      var viewDetailsPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusPanel(
              status: SyncStatus.success,
              recentFiles: manyFiles,
              onViewDetails: () => viewDetailsPressed = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('查看全部 10 个文件'), findsOneWidget);

      // Act
      await tester.tap(find.text('查看全部 10 个文件'));
      await tester.pump();

      // Assert
      expect(viewDetailsPressed, isTrue);
    });
  });

  group('SyncStatus enum', () {
    test('should have all expected values', () {
      final values = SyncStatus.values;
      expect(values, contains(SyncStatus.idle));
      expect(values, contains(SyncStatus.syncing));
      expect(values, contains(SyncStatus.success));
      expect(values, contains(SyncStatus.error));
      expect(values, contains(SyncStatus.conflict));
      expect(values, contains(SyncStatus.offline));
    });
  });
}