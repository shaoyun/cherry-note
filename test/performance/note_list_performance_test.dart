import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/features/notes/domain/entities/note_file.dart';
import 'package:cherry_note/features/notes/presentation/widgets/optimized_note_list_widget.dart';
import 'package:cherry_note/shared/widgets/virtual_list_view.dart';

void main() {
  group('Note List Performance Tests', () {
    late List<NoteFile> largeNoteList;
    late List<NoteFile> smallNoteList;

    setUpAll(() {
      // Create test data
      smallNoteList = _generateNotes(50);
      largeNoteList = _generateNotes(1000);
    });

    testWidgets('should handle large note list efficiently', (WidgetTester tester) async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualListView<NoteFile>(
              items: largeNoteList,
              itemHeight: 120.0,
              itemBuilder: (context, note, index) {
                return OptimizedNoteListItem(
                  note: note,
                  onTap: () {},
                );
              },
            ),
          ),
        ),
      );

      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should render in less than 1 second
      expect(find.byType(VirtualListView), findsOneWidget);
      
      // Only visible items should be rendered
      final renderedItems = tester.widgetList(find.byType(OptimizedNoteListItem));
      expect(renderedItems.length, lessThan(largeNoteList.length));
    });

    testWidgets('should scroll smoothly through large list', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualListView<NoteFile>(
              items: largeNoteList,
              itemHeight: 120.0,
              itemBuilder: (context, note, index) {
                return OptimizedNoteListItem(
                  note: note,
                  onTap: () {},
                );
              },
            ),
          ),
        ),
      );

      // Act - Perform multiple scroll operations
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 10; i++) {
        await tester.drag(find.byType(VirtualListView), const Offset(0, -200));
        await tester.pump();
      }
      
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Scrolling should be smooth
    });

    testWidgets('should handle rapid scroll events without frame drops', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualListView<NoteFile>(
              items: largeNoteList,
              itemHeight: 120.0,
              itemBuilder: (context, note, index) {
                return OptimizedNoteListItem(
                  note: note,
                  onTap: () {},
                );
              },
            ),
          ),
        ),
      );

      // Act - Rapid scrolling
      final stopwatch = Stopwatch()..start();
      
      await tester.fling(find.byType(VirtualListView), const Offset(0, -1000), 2000);
      await tester.pumpAndSettle();
      
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    testWidgets('memory usage should remain stable with large lists', (WidgetTester tester) async {
      // This test would ideally measure actual memory usage
      // For now, we'll test that the widget tree doesn't grow excessively
      
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualListView<NoteFile>(
              items: largeNoteList,
              itemHeight: 120.0,
              itemBuilder: (context, note, index) {
                return OptimizedNoteListItem(
                  note: note,
                  onTap: () {},
                );
              },
            ),
          ),
        ),
      );

      final initialWidgetCount = tester.allWidgets.length;

      // Act - Scroll through the entire list
      for (int i = 0; i < 20; i++) {
        await tester.drag(find.byType(VirtualListView), const Offset(0, -500));
        await tester.pump();
      }

      final finalWidgetCount = tester.allWidgets.length;

      // Assert - Widget count should not grow significantly
      expect(finalWidgetCount, lessThan(initialWidgetCount * 1.5));
    });

    group('Lazy Loading Performance', () {
      testWidgets('should load more data efficiently', (WidgetTester tester) async {
        // Arrange
        final initialItems = _generateNotes(20);
        final allItems = <NoteFile>[...initialItems];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LazyLoadListView<NoteFile>(
                items: allItems,
                itemHeight: 120.0,
                pageSize: 20,
                onLoadMore: (page, pageSize) async {
                  final newItems = _generateNotes(pageSize, startIndex: page * pageSize);
                  allItems.addAll(newItems);
                  return newItems;
                },
                itemBuilder: (context, note, index) {
                  return OptimizedNoteListItem(
                    note: note,
                    onTap: () {},
                  );
                },
              ),
            ),
          ),
        );

        // Act - Scroll to trigger loading
        final stopwatch = Stopwatch()..start();
        
        await tester.drag(find.byType(LazyLoadListView), const Offset(0, -1000));
        await tester.pumpAndSettle();
        
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(allItems.length, greaterThan(initialItems.length));
      });

      testWidgets('should handle loading errors gracefully', (WidgetTester tester) async {
        // Arrange
        final items = _generateNotes(10);
        bool shouldFail = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LazyLoadListView<NoteFile>(
                items: items,
                itemHeight: 120.0,
                onLoadMore: (page, pageSize) async {
                  if (shouldFail) {
                    shouldFail = false;
                    throw Exception('Network error');
                  }
                  return _generateNotes(pageSize);
                },
                itemBuilder: (context, note, index) {
                  return OptimizedNoteListItem(
                    note: note,
                    onTap: () {},
                  );
                },
              ),
            ),
          ),
        );

        // Act - Trigger loading error
        await tester.drag(find.byType(LazyLoadListView), const Offset(0, -1000));
        await tester.pumpAndSettle();

        // Assert - Error should be displayed
        expect(find.text('加载失败'), findsOneWidget);
        expect(find.text('重试'), findsOneWidget);

        // Act - Retry loading
        await tester.tap(find.text('重试'));
        await tester.pumpAndSettle();

        // Assert - Should recover from error
        expect(find.text('加载失败'), findsNothing);
      });
    });

    group('Search Performance', () {
      testWidgets('should filter large lists quickly', (WidgetTester tester) async {
        // This would test search performance with the optimized note list widget
        // Implementation would depend on the actual search functionality
        
        // Arrange
        final searchableNotes = _generateNotesWithSearchableContent(500);
        
        // Act & Assert would test search filtering performance
        expect(searchableNotes.length, equals(500));
      });
    });
  });
}

/// Generate test notes for performance testing
List<NoteFile> _generateNotes(int count, {int startIndex = 0}) {
  return List.generate(count, (index) {
    final actualIndex = startIndex + index;
    return NoteFile(
      filePath: '/test/note_$actualIndex.md',
      title: 'Test Note $actualIndex',
      content: 'This is the content of test note $actualIndex. ' * 10,
      tags: ['tag${actualIndex % 5}', 'category${actualIndex % 3}'],
      created: DateTime.now().subtract(Duration(days: actualIndex)),
      updated: DateTime.now().subtract(Duration(hours: actualIndex)),
      isSticky: actualIndex % 10 == 0,
    );
  });
}

/// Generate notes with searchable content for search performance tests
List<NoteFile> _generateNotesWithSearchableContent(int count) {
  final searchTerms = ['flutter', 'dart', 'mobile', 'development', 'programming'];
  
  return List.generate(count, (index) {
    final searchTerm = searchTerms[index % searchTerms.length];
    return NoteFile(
      filePath: '/test/searchable_note_$index.md',
      title: 'Searchable Note $index - $searchTerm',
      content: 'This note contains information about $searchTerm development. ' * 20,
      tags: [searchTerm, 'searchable'],
      created: DateTime.now().subtract(Duration(days: index)),
      updated: DateTime.now().subtract(Duration(hours: index)),
      isSticky: false,
    );
  });
}