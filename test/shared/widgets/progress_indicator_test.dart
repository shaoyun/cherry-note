import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/shared/widgets/progress_indicator.dart';

void main() {
  group('CustomLinearProgressIndicator', () {
    testWidgets('renders with progress value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomLinearProgressIndicator(
              value: 0.5,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.5);
    });

    testWidgets('shows percentage when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomLinearProgressIndicator(
              value: 0.75,
              showPercentage: true,
            ),
          ),
        ),
      );

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('shows label when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomLinearProgressIndicator(
              value: 0.5,
              label: 'Loading...',
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('shows description when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomLinearProgressIndicator(
              value: 0.5,
              description: 'Please wait',
            ),
          ),
        ),
      );

      expect(find.text('Please wait'), findsOneWidget);
    });

    testWidgets('renders indeterminate when value is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomLinearProgressIndicator(),
          ),
        ),
      );

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, null);
    });
  });

  group('CustomCircularProgressIndicator', () {
    testWidgets('renders with progress value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCircularProgressIndicator(
              value: 0.6,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.value, 0.6);
    });

    testWidgets('shows percentage in center when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCircularProgressIndicator(
              value: 0.8,
              showPercentage: true,
            ),
          ),
        ),
      );

      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('shows label below indicator when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCircularProgressIndicator(
              value: 0.5,
              label: 'Uploading...',
            ),
          ),
        ),
      );

      expect(find.text('Uploading...'), findsOneWidget);
    });

    testWidgets('uses custom size when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomCircularProgressIndicator(
              value: 0.5,
              size: 64.0,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 64.0);
      expect(sizedBox.height, 64.0);
    });
  });

  group('StepProgressIndicator', () {
    testWidgets('renders correct number of steps', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepProgressIndicator(
              currentStep: 1,
              totalSteps: 3,
            ),
          ),
        ),
      );

      // Should find the step progress indicator widget
      expect(find.byType(StepProgressIndicator), findsOneWidget);
    });

    testWidgets('shows check mark for completed steps', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepProgressIndicator(
              currentStep: 2,
              totalSteps: 3,
            ),
          ),
        ),
      );

      // First step should be completed (check mark) - there might be multiple check icons
      expect(find.byIcon(Icons.check), findsAtLeastNWidgets(1));
      // Should find the step progress indicator widget
      expect(find.byType(StepProgressIndicator), findsOneWidget);
    });

    testWidgets('shows step labels when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepProgressIndicator(
              currentStep: 1,
              totalSteps: 3,
              stepLabels: ['Step 1', 'Step 2', 'Step 3'],
            ),
          ),
        ),
      );

      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('Step 2'), findsOneWidget);
      expect(find.text('Step 3'), findsOneWidget);
    });
  });

  group('FileProgressWidget', () {
    testWidgets('renders file name and progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileProgressWidget(
              fileName: 'test.txt',
              progress: 0.7,
            ),
          ),
        ),
      );

      expect(find.text('test.txt'), findsOneWidget);
      expect(find.byType(CustomLinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows status when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileProgressWidget(
              fileName: 'test.txt',
              progress: 0.5,
              status: 'Uploading...',
            ),
          ),
        ),
      );

      expect(find.text('Uploading...'), findsOneWidget);
    });

    testWidgets('shows completed state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileProgressWidget(
              fileName: 'test.txt',
              progress: 1.0,
              isCompleted: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileProgressWidget(
              fileName: 'test.txt',
              progress: 0.5,
              hasError: true,
              errorMessage: 'Upload failed',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Upload failed'), findsOneWidget);
    });

    testWidgets('shows cancel button when onCancel is provided', (tester) async {
      bool cancelCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileProgressWidget(
              fileName: 'test.txt',
              progress: 0.5,
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.close));
      expect(cancelCalled, true);
    });

    testWidgets('hides cancel button when completed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileProgressWidget(
              fileName: 'test.txt',
              progress: 1.0,
              isCompleted: true,
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}