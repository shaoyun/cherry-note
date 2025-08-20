import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/core/feedback/feedback_service.dart';

void main() {
  group('FeedbackService', () {
    late FeedbackService feedbackService;

    setUp(() {
      feedbackService = FeedbackService();
    });

    group('Message Creation', () {
      test('should create success message', () async {
        // Arrange
        const message = 'Operation completed successfully';
        const title = 'Success';

        // Act & Assert
        expectLater(
          feedbackService.messageStream,
          emits(isA<FeedbackMessage>()
              .having((m) => m.type, 'type', FeedbackType.success)
              .having((m) => m.message, 'message', message)
              .having((m) => m.title, 'title', title)),
        );

        feedbackService.showSuccess(message, title: title);
      });

      test('should create error message with retry callback', () async {
        // Arrange
        const message = 'Operation failed';
        const title = 'Error';
        var retryCallbackCalled = false;
        void retryCallback() => retryCallbackCalled = true;

        // Act & Assert
        expectLater(
          feedbackService.messageStream,
          emits(isA<FeedbackMessage>()
              .having((m) => m.type, 'type', FeedbackType.error)
              .having((m) => m.message, 'message', message)
              .having((m) => m.title, 'title', title)
              .having((m) => m.onRetry, 'onRetry', isNotNull)),
        );

        feedbackService.showError(message, title: title, onRetry: retryCallback);
      });

      test('should create warning message', () async {
        // Arrange
        const message = 'This is a warning';

        // Act & Assert
        expectLater(
          feedbackService.messageStream,
          emits(isA<FeedbackMessage>()
              .having((m) => m.type, 'type', FeedbackType.warning)
              .having((m) => m.message, 'message', message)),
        );

        feedbackService.showWarning(message);
      });

      test('should create info message', () async {
        // Arrange
        const message = 'This is information';

        // Act & Assert
        expectLater(
          feedbackService.messageStream,
          emits(isA<FeedbackMessage>()
              .having((m) => m.type, 'type', FeedbackType.info)
              .having((m) => m.message, 'message', message)),
        );

        feedbackService.showInfo(message);
      });

      test('should create loading message', () async {
        // Arrange
        const message = 'Loading...';

        // Act & Assert
        expectLater(
          feedbackService.messageStream,
          emits(isA<FeedbackMessage>()
              .having((m) => m.type, 'type', FeedbackType.loading)
              .having((m) => m.message, 'message', message)
              .having((m) => m.duration, 'duration', isNull)),
        );

        feedbackService.showLoading(message);
      });

      test('should create hide loading message', () async {
        // Act & Assert
        expectLater(
          feedbackService.messageStream,
          emits(isA<FeedbackMessage>()
              .having((m) => m.type, 'type', FeedbackType.hideLoading)),
        );

        feedbackService.hideLoading();
      });
    });

    group('Message Properties', () {
      test('should have correct default durations', () async {
        // Test success message duration
        expectLater(
          feedbackService.messageStream,
          emits(isA<FeedbackMessage>()
              .having((m) => m.duration, 'duration', const Duration(seconds: 3))),
        );
        feedbackService.showSuccess('Success');

        // Test error message duration
        expectLater(
          feedbackService.messageStream,
          emits(isA<FeedbackMessage>()
              .having((m) => m.duration, 'duration', const Duration(seconds: 5))),
        );
        feedbackService.showError('Error');

        // Test warning message duration
        expectLater(
          feedbackService.messageStream,
          emits(isA<FeedbackMessage>()
              .having((m) => m.duration, 'duration', const Duration(seconds: 4))),
        );
        feedbackService.showWarning('Warning');

        // Test info message duration
        expectLater(
          feedbackService.messageStream,
          emits(isA<FeedbackMessage>()
              .having((m) => m.duration, 'duration', const Duration(seconds: 3))),
        );
        feedbackService.showInfo('Info');
      });

      test('should allow custom duration', () async {
        // Arrange
        const customDuration = Duration(seconds: 10);

        // Act & Assert
        expectLater(
          feedbackService.messageStream,
          emits(isA<FeedbackMessage>()
              .having((m) => m.duration, 'duration', customDuration)),
        );

        feedbackService.showSuccess('Success', duration: customDuration);
      });

      test('should have timestamp', () async {
        // Arrange
        final beforeTime = DateTime.now();

        // Act & Assert
        expectLater(
          feedbackService.messageStream,
          emits(isA<FeedbackMessage>()
              .having((m) => m.timestamp.isAfter(beforeTime), 'timestamp after', isTrue)),
        );

        feedbackService.showInfo('Info');
      });
    });

    group('FeedbackMessage', () {
      test('should create message with all properties', () {
        // Arrange
        const message = 'Test message';
        const title = 'Test title';
        const duration = Duration(seconds: 5);
        var tapCallbackCalled = false;
        var retryCallbackCalled = false;
        void tapCallback() => tapCallbackCalled = true;
        void retryCallback() => retryCallbackCalled = true;

        // Act
        final feedbackMessage = FeedbackMessage(
          type: FeedbackType.error,
          message: message,
          title: title,
          duration: duration,
          onTap: tapCallback,
          onRetry: retryCallback,
        );

        // Assert
        expect(feedbackMessage.type, FeedbackType.error);
        expect(feedbackMessage.message, message);
        expect(feedbackMessage.title, title);
        expect(feedbackMessage.duration, duration);
        expect(feedbackMessage.onTap, isNotNull);
        expect(feedbackMessage.onRetry, isNotNull);
        expect(feedbackMessage.timestamp, isA<DateTime>());

        // Test callbacks
        feedbackMessage.onTap!();
        feedbackMessage.onRetry!();
        expect(tapCallbackCalled, isTrue);
        expect(retryCallbackCalled, isTrue);
      });

      test('should have string representation', () {
        // Arrange
        const message = 'Test message';
        const title = 'Test title';

        // Act
        final feedbackMessage = FeedbackMessage(
          type: FeedbackType.info,
          message: message,
          title: title,
        );

        // Assert
        final stringRep = feedbackMessage.toString();
        expect(stringRep, contains('FeedbackMessage'));
        expect(stringRep, contains('info'));
        expect(stringRep, contains(message));
        expect(stringRep, contains(title));
      });
    });

    group('FeedbackType Extension', () {
      test('should have correct icons', () {
        expect(FeedbackType.success.icon, Icons.check_circle);
        expect(FeedbackType.error.icon, Icons.error);
        expect(FeedbackType.warning.icon, Icons.warning);
        expect(FeedbackType.info.icon, Icons.info);
        expect(FeedbackType.loading.icon, Icons.hourglass_empty);
        expect(FeedbackType.hideLoading.icon, Icons.close);
      });

      test('should have correct default titles', () {
        expect(FeedbackType.success.defaultTitle, '成功');
        expect(FeedbackType.error.defaultTitle, '错误');
        expect(FeedbackType.warning.defaultTitle, '警告');
        expect(FeedbackType.info.defaultTitle, '提示');
        expect(FeedbackType.loading.defaultTitle, '加载中');
        expect(FeedbackType.hideLoading.defaultTitle, '');
      });
    });

    group('Multiple Messages', () {
      test('should emit multiple messages in order', () async {
        // Arrange
        final messages = [
          'First message',
          'Second message',
          'Third message',
        ];

        // Act & Assert
        expectLater(
          feedbackService.messageStream,
          emitsInOrder([
            isA<FeedbackMessage>().having((m) => m.message, 'message', messages[0]),
            isA<FeedbackMessage>().having((m) => m.message, 'message', messages[1]),
            isA<FeedbackMessage>().having((m) => m.message, 'message', messages[2]),
          ]),
        );

        for (final message in messages) {
          feedbackService.showInfo(message);
        }
      });
    });
  });
}