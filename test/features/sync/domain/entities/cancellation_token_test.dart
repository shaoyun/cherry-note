import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/features/sync/domain/entities/cancellation_token.dart';

void main() {
  group('CancellationToken', () {
    test('should not be cancelled initially', () {
      final token = CancellationToken();
      
      expect(token.isCancelled, false);
      expect(token.reason, null);
    });

    test('should be cancelled when cancel is called', () {
      final token = CancellationToken();
      
      token.cancel('Test cancellation');
      
      expect(token.isCancelled, true);
      expect(token.reason, 'Test cancellation');
    });

    test('should complete future when cancelled', () async {
      final token = CancellationToken();
      
      // Start listening to the future
      final futureCompleted = token.future.then((_) => true);
      
      // Cancel the token
      token.cancel();
      
      // Future should complete
      final completed = await futureCompleted;
      expect(completed, true);
    });

    test('should throw when throwIfCancelled is called on cancelled token', () {
      final token = CancellationToken();
      
      token.cancel('Operation cancelled');
      
      expect(() => token.throwIfCancelled(), 
             throwsA(isA<OperationCancelledException>()));
    });

    test('should not throw when throwIfCancelled is called on active token', () {
      final token = CancellationToken();
      
      expect(() => token.throwIfCancelled(), returnsNormally);
    });

    test('should create already cancelled token', () {
      final token = CancellationToken.cancelled('Already cancelled');
      
      expect(token.isCancelled, true);
      expect(token.reason, 'Already cancelled');
    });

    test('should ignore multiple cancel calls', () {
      final token = CancellationToken();
      
      token.cancel('First cancel');
      token.cancel('Second cancel');
      
      expect(token.isCancelled, true);
      expect(token.reason, 'First cancel'); // Should keep first reason
    });

    test('should use default reason when none provided', () {
      final token = CancellationToken();
      
      token.cancel();
      
      expect(token.reason, 'Operation was cancelled');
    });
  });

  group('CancellationTokenSource', () {
    test('should provide access to token', () {
      final source = CancellationTokenSource();
      
      expect(source.token, isA<CancellationToken>());
      expect(source.token.isCancelled, false);
    });

    test('should cancel token when source is cancelled', () {
      final source = CancellationTokenSource();
      
      source.cancel('Source cancelled');
      
      expect(source.token.isCancelled, true);
      expect(source.token.reason, 'Source cancelled');
    });

    test('should create timeout token', () async {
      final token = CancellationTokenSource.timeout(
        const Duration(milliseconds: 100),
        'Timeout reached',
      );
      
      expect(token.isCancelled, false);
      
      // Wait for timeout
      await Future.delayed(const Duration(milliseconds: 150));
      
      expect(token.isCancelled, true);
      expect(token.reason, 'Timeout reached');
    });

    test('should combine multiple tokens', () async {
      final token1 = CancellationToken();
      final token2 = CancellationToken();
      final token3 = CancellationToken();
      
      final combined = CancellationTokenSource.combine([token1, token2, token3]);
      
      expect(combined.isCancelled, false);
      
      // Cancel one of the tokens
      token2.cancel('Token 2 cancelled');
      
      // Wait for the combined token to react
      await Future.delayed(Duration.zero);
      
      // Combined token should be cancelled
      expect(combined.isCancelled, true);
      expect(combined.reason, 'Token 2 cancelled');
    });

    test('should combine with already cancelled token', () {
      final token1 = CancellationToken();
      final token2 = CancellationToken.cancelled('Already cancelled');
      final token3 = CancellationToken();
      
      final combined = CancellationTokenSource.combine([token1, token2, token3]);
      
      expect(combined.isCancelled, true);
      expect(combined.reason, 'Already cancelled');
    });

    test('should handle empty token list', () {
      final combined = CancellationTokenSource.combine([]);
      
      expect(combined.isCancelled, false);
    });
  });

  group('OperationCancelledException', () {
    test('should have correct message', () {
      const exception = OperationCancelledException('Test message');
      
      expect(exception.message, 'Test message');
      expect(exception.toString(), 'OperationCancelledException: Test message');
    });
  });
}