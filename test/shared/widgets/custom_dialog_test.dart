import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/shared/widgets/custom_dialog.dart';

void main() {
  group('CustomAlertDialog', () {
    testWidgets('renders with title and content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CustomAlertDialog.show(
                  context,
                  title: 'Test Title',
                  content: 'Test Content',
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('renders with custom content widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CustomAlertDialog.show(
                  context,
                  title: 'Test Title',
                  contentWidget: const Text('Custom Widget'),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Custom Widget'), findsOneWidget);
    });

    testWidgets('renders with actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CustomAlertDialog.show(
                  context,
                  title: 'Test Title',
                  content: 'Test Content',
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('ConfirmationDialog', () {
    testWidgets('renders with title and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ConfirmationDialog.show(
                  context,
                  title: 'Confirm Action',
                  message: 'Are you sure?',
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('确认'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('returns true when confirm is tapped', (tester) async {
      bool? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ConfirmationDialog.show(
                    context,
                    title: 'Confirm Action',
                    message: 'Are you sure?',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('returns false when cancel is tapped', (tester) async {
      bool? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ConfirmationDialog.show(
                    context,
                    title: 'Confirm Action',
                    message: 'Are you sure?',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('shows destructive styling when isDestructive is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ConfirmationDialog.show(
                  context,
                  title: 'Delete Item',
                  message: 'This action cannot be undone',
                  isDestructive: true,
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Find the confirm button and check if it has error styling
      final confirmButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '确认'),
      );
      expect(confirmButton.style, isNotNull);
    });
  });

  group('InputDialog', () {
    testWidgets('renders with title and input field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => InputDialog.show(
                  context,
                  title: 'Enter Name',
                  hint: 'Your name',
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Enter Name'), findsOneWidget);
      expect(find.text('Your name'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('returns input text when confirmed', (tester) async {
      String? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await InputDialog.show(
                    context,
                    title: 'Enter Name',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Test Input');
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(result, 'Test Input');
    });

    testWidgets('shows initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => InputDialog.show(
                  context,
                  title: 'Enter Name',
                  initialValue: 'Initial Value',
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Initial Value'), findsOneWidget);
    });
  });

  group('LoadingDialog', () {
    testWidgets('renders with loading indicator and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => LoadingDialog.show(
                  context,
                  message: 'Loading data...',
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading data...'), findsOneWidget);
    });

    testWidgets('can be hidden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  LoadingDialog.show(context);
                  // Hide after showing
                  Future.delayed(const Duration(milliseconds: 10), () {
                    LoadingDialog.hide(context);
                  });
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for hide
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}