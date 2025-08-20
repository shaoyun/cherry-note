import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/shared/widgets/virtual_list_view.dart';

void main() {
  group('VirtualListView', () {
    testWidgets('should render items correctly', (WidgetTester tester) async {
      // Arrange
      final items = List.generate(100, (index) => 'Item $index');
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualListView<String>(
              items: items,
              itemHeight: 50.0,
              itemBuilder: (context, item, index) {
                return Container(
                  height: 50,
                  child: Text(item),
                );
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      
      // Items that are not visible should not be rendered
      expect(find.text('Item 50'), findsNothing);
    });

    testWidgets('should handle empty list', (WidgetTester tester) async {
      // Arrange
      final items = <String>[];
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualListView<String>(
              items: items,
              itemHeight: 50.0,
              itemBuilder: (context, item, index) {
                return Container(
                  height: 50,
                  child: Text(item),
                );
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should call onEndReached when scrolled to bottom', (WidgetTester tester) async {
      // Arrange
      final items = List.generate(10, (index) => 'Item $index');
      bool endReachedCalled = false;
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualListView<String>(
              items: items,
              itemHeight: 50.0,
              onEndReached: () {
                endReachedCalled = true;
              },
              itemBuilder: (context, item, index) {
                return Container(
                  height: 50,
                  child: Text(item),
                );
              },
            ),
          ),
        ),
      );

      // Scroll to bottom
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      // Assert
      expect(endReachedCalled, isTrue);
    });
  });

  group('VirtualGridView', () {
    testWidgets('should render grid items correctly', (WidgetTester tester) async {
      // Arrange
      final items = List.generate(20, (index) => 'Item $index');
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualGridView<String>(
              items: items,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemBuilder: (context, item, index) {
                return Container(
                  child: Text(item),
                );
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should handle empty grid', (WidgetTester tester) async {
      // Arrange
      final items = <String>[];
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualGridView<String>(
              items: items,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemBuilder: (context, item, index) {
                return Container(
                  child: Text(item),
                );
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('LazyLoadListView', () {
    testWidgets('should render initial items', (WidgetTester tester) async {
      // Arrange
      final items = List.generate(10, (index) => 'Item $index');
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyLoadListView<String>(
              items: items,
              itemHeight: 50.0,
              onLoadMore: (page, pageSize) async {
                return List.generate(pageSize, (index) => 'New Item ${page * pageSize + index}');
              },
              itemBuilder: (context, item, index) {
                return Container(
                  height: 50,
                  child: Text(item),
                );
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading more', (WidgetTester tester) async {
      // Arrange
      final items = List.generate(5, (index) => 'Item $index');
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyLoadListView<String>(
              items: items,
              itemHeight: 50.0,
              onLoadMore: (page, pageSize) async {
                // Simulate loading delay
                await Future.delayed(const Duration(milliseconds: 100));
                return List.generate(pageSize, (index) => 'New Item ${page * pageSize + index}');
              },
              itemBuilder: (context, item, index) {
                return Container(
                  height: 50,
                  child: Text(item),
                );
              },
            ),
          ),
        ),
      );

      // Scroll to trigger loading
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error widget on load failure', (WidgetTester tester) async {
      // Arrange
      final items = List.generate(5, (index) => 'Item $index');
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyLoadListView<String>(
              items: items,
              itemHeight: 50.0,
              onLoadMore: (page, pageSize) async {
                throw Exception('Load failed');
              },
              itemBuilder: (context, item, index) {
                return Container(
                  height: 50,
                  child: Text(item),
                );
              },
            ),
          ),
        ),
      );

      // Scroll to trigger loading
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('should retry loading on error', (WidgetTester tester) async {
      // Arrange
      final items = List.generate(5, (index) => 'Item $index');
      int loadAttempts = 0;
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LazyLoadListView<String>(
              items: items,
              itemHeight: 50.0,
              onLoadMore: (page, pageSize) async {
                loadAttempts++;
                if (loadAttempts == 1) {
                  throw Exception('Load failed');
                }
                return List.generate(pageSize, (index) => 'New Item ${page * pageSize + index}');
              },
              itemBuilder: (context, item, index) {
                return Container(
                  height: 50,
                  child: Text(item),
                );
              },
            ),
          ),
        ),
      );

      // Scroll to trigger loading (first attempt - should fail)
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Tap retry button
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();

      // Assert
      expect(loadAttempts, equals(2));
    });
  });
}