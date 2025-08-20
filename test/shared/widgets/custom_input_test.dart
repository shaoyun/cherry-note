import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/shared/widgets/custom_input.dart';

void main() {
  group('CustomTextField', () {
    testWidgets('renders with label and hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Test Label',
              hint: 'Test Hint',
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('Test Hint'), findsOneWidget);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      String? changedValue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test input');
      expect(changedValue, 'test input');
    });

    testWidgets('shows initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              initialValue: 'Initial Value',
            ),
          ),
        ),
      );

      expect(find.text('Initial Value'), findsOneWidget);
    });

    testWidgets('validates input when validator is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: CustomTextField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Field is required';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      final formState = tester.state<FormState>(find.byType(Form));
      formState.validate();
      await tester.pump();

      expect(find.text('Field is required'), findsOneWidget);
    });

    testWidgets('shows prefix and suffix icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              prefixIcon: const Icon(Icons.person),
              suffixIcon: const Icon(Icons.visibility),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  group('SearchTextField', () {
    testWidgets('renders with search icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTextField(),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows clear button when text is entered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTextField(),
          ),
        ),
      );

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'search text');
      await tester.pump();

      // Clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clears text when clear button is tapped', (tester) async {
      String? searchValue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTextField(
              onChanged: (value) => searchValue = value,
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'search text');
      await tester.pump();
      expect(searchValue, 'search text');

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(searchValue, '');
      expect(find.text('search text'), findsNothing);
    });

    testWidgets('calls onClear when clear button is tapped', (tester) async {
      bool clearCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTextField(
              onClear: () => clearCalled = true,
            ),
          ),
        ),
      );

      // Enter text to show clear button
      await tester.enterText(find.byType(TextField), 'search text');
      await tester.pump();

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(clearCalled, true);
    });
  });

  group('CustomDropdownField', () {
    testWidgets('renders with items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDropdownField<String>(
              items: const [
                DropdownMenuItem(value: 'item1', child: Text('Item 1')),
                DropdownMenuItem(value: 'item2', child: Text('Item 2')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows selected value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDropdownField<String>(
              value: 'item1',
              items: const [
                DropdownMenuItem(value: 'item1', child: Text('Item 1')),
                DropdownMenuItem(value: 'item2', child: Text('Item 2')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
    });
  });

  group('MultiLineTextField', () {
    testWidgets('renders as multiline input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiLineTextField(
              label: 'Notes',
              minLines: 3,
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('shows label and hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiLineTextField(
              label: 'Notes',
              hint: 'Enter your notes here',
            ),
          ),
        ),
      );

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Enter your notes here'), findsOneWidget);
    });
  });
}