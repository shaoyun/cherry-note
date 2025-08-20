import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cherry_note/core/error/error_handling_extensions.dart';
import 'package:cherry_note/core/error/exceptions.dart';
import 'package:cherry_note/core/error/failures.dart';
import 'package:cherry_note/core/error/global_error_handler.dart';
import 'package:cherry_note/core/feedback/feedback_service.dart';

// Test BLoC
class TestEvent {}
class TestState {}

class TestBloc extends Bloc<TestEvent, TestState> {
  TestBloc() : super(TestState()) {
    on<TestEvent>((event, emit) {});
  }
}

// Test Cubit
class TestCubit extends Cubit<TestState> {
  TestCubit() : super(TestState());
}

// Test widget with mixin
class TestWidget with ErrorHandlingMixin {
  void testHandleException(Exception exception) {
    handleException(exception);
  }

  void testHandleFailure(Failure failure) {
    handleFailure(failure);
  }

  void testShowSuccess(String message) {
    showSuccess(message);
  }

  void testShowError(String message) {
    showError(message);
  }

  void testShowLoading(String message) {
    showLoading(message);
  }

  void testHideLoading() {
    hideLoading();
  }
}

void main() {
  group('ErrorHandlingBloc Extension', () {
    late TestBloc bloc;
    late GlobalErrorHandler errorHandler;
    late FeedbackService feedbackService;

    setUp(() {
      bloc = TestBloc();
      errorHandler = GlobalErrorHandler();
      feedbackService = FeedbackService();
    });

    tearDown(() {
      bloc.close();
    });

    test('should handle exception with user feedback', () async {
      // Arrange
      const exception = NetworkException('Network error');

      // Act & Assert
      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.warning)
            .having((m) => m.message, 'message', contains('网络连接失败'))),
      );

      bloc.handleException(exception);
    });

    test('should handle exception without user feedback', () async {
      // Arrange
      const exception = NetworkException('Network error');

      // Act
      bloc.handleException(exception, showUserFeedback: false);

      // Assert
      await expectLater(
        feedbackService.messageStream,
        emitsDone,
      );
    });

    test('should handle failure with user feedback', () async {
      // Arrange
      const failure = StorageFailure('Storage error');

      // Act & Assert
      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.error)
            .having((m) => m.message, 'message', contains('存储操作失败'))),
      );

      bloc.handleFailure(failure);
    });

    test('should handle app error directly', () async {
      // Arrange
      final error = AppError(
        message: 'Test error',
        severity: ErrorSeverity.low,
        category: ErrorCategory.unknown,
      );

      // Act & Assert
      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.info)
            .having((m) => m.message, 'message', 'Test error')),
      );

      bloc.handleAppError(error);
    });

    test('should show different feedback types based on severity', () async {
      // Test low severity -> info
      final lowError = AppError(
        message: 'Low severity error',
        severity: ErrorSeverity.low,
        category: ErrorCategory.unknown,
      );

      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.info)),
      );
      bloc.handleAppError(lowError);

      // Test medium severity -> warning
      final mediumError = AppError(
        message: 'Medium severity error',
        severity: ErrorSeverity.medium,
        category: ErrorCategory.unknown,
      );

      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.warning)),
      );
      bloc.handleAppError(mediumError);

      // Test high severity -> error
      final highError = AppError(
        message: 'High severity error',
        severity: ErrorSeverity.high,
        category: ErrorCategory.unknown,
      );

      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.error)),
      );
      bloc.handleAppError(highError);
    });
  });

  group('ErrorHandlingCubit Extension', () {
    late TestCubit cubit;
    late FeedbackService feedbackService;

    setUp(() {
      cubit = TestCubit();
      feedbackService = FeedbackService();
    });

    tearDown(() {
      cubit.close();
    });

    test('should handle exception with user feedback', () async {
      // Arrange
      const exception = ValidationException('Validation error');

      // Act & Assert
      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.info)
            .having((m) => m.message, 'message', contains('输入数据格式不正确'))),
      );

      cubit.handleException(exception);
    });

    test('should handle failure with user feedback', () async {
      // Arrange
      const failure = AuthenticationFailure('Auth error');

      // Act & Assert
      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.error)
            .having((m) => m.message, 'message', contains('身份验证失败'))),
      );

      cubit.handleFailure(failure);
    });
  });

  group('SuccessFeedback Extension', () {
    late FeedbackService feedbackService;
    late TestWidget testObject;

    setUp(() {
      feedbackService = FeedbackService();
      testObject = TestWidget();
    });

    test('should show success feedback', () async {
      // Arrange
      const message = 'Operation successful';
      const title = 'Success';

      // Act & Assert
      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.success)
            .having((m) => m.message, 'message', message)
            .having((m) => m.title, 'title', title)),
      );

      testObject.showSuccess(message, title: title);
    });

    test('should show loading feedback', () async {
      // Arrange
      const message = 'Loading...';

      // Act & Assert
      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.loading)
            .having((m) => m.message, 'message', message)),
      );

      testObject.showLoading(message);
    });

    test('should hide loading feedback', () async {
      // Act & Assert
      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.hideLoading)),
      );

      testObject.hideLoading();
    });

    test('should show info feedback', () async {
      // Arrange
      const message = 'Information message';

      // Act & Assert
      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.info)
            .having((m) => m.message, 'message', message)),
      );

      testObject.showInfo(message);
    });
  });

  group('ErrorHandlingMixin', () {
    late TestWidget widget;
    late FeedbackService feedbackService;

    setUp(() {
      widget = TestWidget();
      feedbackService = FeedbackService();
    });

    test('should handle exception', () {
      // Arrange
      const exception = NetworkException('Network error');

      // Act
      widget.testHandleException(exception);

      // Assert - no exception should be thrown
      expect(true, isTrue);
    });

    test('should handle failure', () {
      // Arrange
      const failure = StorageFailure('Storage error');

      // Act
      widget.testHandleFailure(failure);

      // Assert - no exception should be thrown
      expect(true, isTrue);
    });

    test('should show success message', () async {
      // Arrange
      const message = 'Success message';

      // Act & Assert
      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.success)
            .having((m) => m.message, 'message', message)),
      );

      widget.testShowSuccess(message);
    });

    test('should show error message', () async {
      // Arrange
      const message = 'Error message';

      // Act & Assert
      expectLater(
        feedbackService.messageStream,
        emits(isA<FeedbackMessage>()
            .having((m) => m.type, 'type', FeedbackType.error)
            .having((m) => m.message, 'message', message)),
      );

      widget.testShowError(message);
    });

    test('should show and hide loading', () async {
      // Test show loading
      expectLater(
        feedbackService.messageStream,
        emitsInOrder([
          isA<FeedbackMessage>()
              .having((m) => m.type, 'type', FeedbackType.loading),
          isA<FeedbackMessage>()
              .having((m) => m.type, 'type', FeedbackType.hideLoading),
        ]),
      );

      widget.testShowLoading('Loading...');
      widget.testHideLoading();
    });
  });
}