import 'package:flutter/material.dart';

/// Custom alert dialog with consistent styling
class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? contentWidget;
  final List<Widget>? actions;
  final bool barrierDismissible;
  
  const CustomAlertDialog({
    super.key,
    required this.title,
    this.content,
    this.contentWidget,
    this.actions,
    this.barrierDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: contentWidget ?? (content != null ? Text(content!) : null),
      actions: actions,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// Show the dialog
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? content,
    Widget? contentWidget,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CustomAlertDialog(
        title: title,
        content: content,
        contentWidget: contentWidget,
        actions: actions,
        barrierDismissible: barrierDismissible,
      ),
    );
  }
}

/// Confirmation dialog with Yes/No buttons
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = '确认',
    this.cancelText = '取消',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomAlertDialog(
      title: title,
      content: message,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Show confirmation dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '确认',
    String cancelText = '取消',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
      ),
    );
  }
}

/// Input dialog for getting text input from user
class InputDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String? initialValue;
  final String? hint;
  final String confirmText;
  final String cancelText;
  final String? Function(String?)? validator;
  final int maxLines;
  
  const InputDialog({
    super.key,
    required this.title,
    this.message,
    this.initialValue,
    this.hint,
    this.confirmText = '确认',
    this.cancelText = '取消',
    this.validator,
    this.maxLines = 1,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();

  /// Show input dialog
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? message,
    String? initialValue,
    String? hint,
    String confirmText = '确认',
    String cancelText = '取消',
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => InputDialog(
        title: title,
        message: message,
        initialValue: initialValue,
        hint: hint,
        confirmText: confirmText,
        cancelText: cancelText,
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }
}

class _InputDialogState extends State<InputDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomAlertDialog(
      title: widget.title,
      contentWidget: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message != null) ...[
              Text(widget.message!),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _controller,
              validator: widget.validator,
              maxLines: widget.maxLines,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelText),
        ),
        ElevatedButton(
          onPressed: _confirm,
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}

/// Loading dialog
class LoadingDialog extends StatelessWidget {
  final String message;
  
  const LoadingDialog({
    super.key,
    this.message = '加载中...',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Text(message),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// Show loading dialog
  static void show(BuildContext context, {String message = '加载中...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  /// Hide loading dialog
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// Bottom sheet dialog
class CustomBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final bool isScrollControlled;
  final bool isDismissible;
  
  const CustomBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.isScrollControlled = false,
    this.isDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ],
          Flexible(child: child),
        ],
      ),
    );
  }

  /// Show bottom sheet
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget child,
    bool isScrollControlled = false,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) => CustomBottomSheet(
        title: title,
        child: child,
        isScrollControlled: isScrollControlled,
        isDismissible: isDismissible,
      ),
    );
  }
}