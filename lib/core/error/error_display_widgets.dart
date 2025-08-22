import 'package:flutter/material.dart';
import 'global_error_handler.dart';

/// Widget to display error messages in a user-friendly way
class ErrorDisplayWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showTechnicalDetails;

  const ErrorDisplayWidget({
    Key? key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showTechnicalDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForSeverity(error.severity),
                  color: _getColorForSeverity(error.severity),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getTitleForSeverity(error.severity),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _getColorForSeverity(error.severity),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              error.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (showTechnicalDetails && error.technicalMessage != null) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                title: const Text('技术详情'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error.technicalMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Icons.info_outline;
      case ErrorSeverity.medium:
        return Icons.warning_amber_outlined;
      case ErrorSeverity.high:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous_outlined;
    }
  }

  Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.blue;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade800;
    }
  }

  String _getTitleForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return '提示';
      case ErrorSeverity.medium:
        return '警告';
      case ErrorSeverity.high:
        return '错误';
      case ErrorSeverity.critical:
        return '严重错误';
    }
  }
}

/// Snackbar for displaying quick error messages
class ErrorSnackBar extends SnackBar {
  ErrorSnackBar({
    Key? key,
    required AppError error,
    VoidCallback? onRetry,
  }) : super(
          key: key,
          content: Row(
            children: [
              Icon(
                _getIconForSeverity(error.severity),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: _getColorForSeverity(error.severity),
          action: onRetry != null
              ? SnackBarAction(
                  label: '重试',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : null,
          duration: Duration(
            seconds: error.severity == ErrorSeverity.critical ? 10 : 4,
          ),
        );

  static IconData _getIconForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Icons.info_outline;
      case ErrorSeverity.medium:
        return Icons.warning_amber_outlined;
      case ErrorSeverity.high:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous_outlined;
    }
  }

  static Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.blue;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade800;
    }
  }
}

/// Dialog for displaying detailed error information
class ErrorDialog extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const ErrorDialog({
    Key? key,
    required this.error,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getIconForSeverity(error.severity),
            color: _getColorForSeverity(error.severity),
          ),
          const SizedBox(width: 8),
          Text(_getTitleForSeverity(error.severity)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error.message),
          if (error.code != null) ...[
            const SizedBox(height: 8),
            Text(
              '错误代码: ${error.code}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        if (onRetry != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: const Text('重试'),
          ),
      ],
    );
  }

  IconData _getIconForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Icons.info_outline;
      case ErrorSeverity.medium:
        return Icons.warning_amber_outlined;
      case ErrorSeverity.high:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous_outlined;
    }
  }

  Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.blue;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade800;
    }
  }

  String _getTitleForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return '提示';
      case ErrorSeverity.medium:
        return '警告';
      case ErrorSeverity.high:
        return '错误';
      case ErrorSeverity.critical:
        return '严重错误';
    }
  }

  /// Show error dialog
  static Future<void> show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: error.severity != ErrorSeverity.critical,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: onRetry,
      ),
    );
  }
}

/// Widget that listens to global errors and displays them
class GlobalErrorListener extends StatefulWidget {
  final Widget child;
  final bool showSnackBars;
  final bool showDialogs;

  const GlobalErrorListener({
    Key? key,
    required this.child,
    this.showSnackBars = true,
    this.showDialogs = false,
  }) : super(key: key);

  @override
  State<GlobalErrorListener> createState() => _GlobalErrorListenerState();
}

class _GlobalErrorListenerState extends State<GlobalErrorListener> {
  late final GlobalErrorHandler _errorHandler;

  @override
  void initState() {
    super.initState();
    _errorHandler = GlobalErrorHandler();
    _errorHandler.errorStream.listen(_handleError);
  }

  void _handleError(AppError error) {
    if (!mounted) return;

    if (widget.showDialogs && error.severity.index >= ErrorSeverity.high.index) {
      // Check if Navigator is available before showing dialog
      final navigator = Navigator.maybeOf(context);
      if (navigator != null) {
        ErrorDialog.show(context, error);
      } else {
        // Fallback to debug print if Navigator is not available
        debugPrint('Error (Navigator not available): ${error.message}');
      }
    } else if (widget.showSnackBars) {
      // Check if ScaffoldMessenger is available before showing snackbar
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      if (scaffoldMessenger != null) {
        scaffoldMessenger.showSnackBar(
          ErrorSnackBar(error: error),
        );
      } else {
        // Fallback to debug print if ScaffoldMessenger is not available
        debugPrint('Error (ScaffoldMessenger not available): ${error.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}