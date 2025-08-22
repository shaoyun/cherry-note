import 'package:flutter/material.dart';
import 'feedback_service.dart';

/// Toast-style notification widget
class FeedbackToast extends StatefulWidget {
  final FeedbackMessage message;
  final VoidCallback? onDismiss;

  const FeedbackToast({
    Key? key,
    required this.message,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<FeedbackToast> createState() => _FeedbackToastState();
}

class _FeedbackToastState extends State<FeedbackToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Auto-dismiss if duration is specified
    if (widget.message.duration != null) {
      Future.delayed(widget.message.duration!, () {
        if (mounted) {
          _dismiss();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: widget.message.type.getColor(context),
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: widget.message.onTap ?? _dismiss,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (widget.message.type == FeedbackType.loading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.message.type.getColor(context),
                            ),
                          ),
                        )
                      else
                        Icon(
                          widget.message.type.icon,
                          color: widget.message.type.getColor(context),
                          size: 20,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.message.title != null)
                              Text(
                                widget.message.title!,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: widget.message.type.getColor(context),
                                ),
                              ),
                            Text(
                              widget.message.message,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (widget.message.onRetry != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            widget.message.onRetry!();
                            _dismiss();
                          },
                          child: const Text('重试'),
                        ),
                      ],
                      if (widget.message.duration != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _dismiss,
                          icon: const Icon(Icons.close),
                          iconSize: 18,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner-style notification widget
class FeedbackBanner extends StatelessWidget {
  final FeedbackMessage message;
  final VoidCallback? onDismiss;

  const FeedbackBanner({
    Key? key,
    required this.message,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: message.type.getColor(context).withOpacity(0.1),
        border: Border(
          left: BorderSide(
            color: message.type.getColor(context),
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (message.type == FeedbackType.loading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    message.type.getColor(context),
                  ),
                ),
              )
            else
              Icon(
                message.type.icon,
                color: message.type.getColor(context),
                size: 20,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.title != null)
                    Text(
                      message.title!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: message.type.getColor(context),
                      ),
                    ),
                  Text(
                    message.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (message.onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: message.onRetry,
                child: const Text('重试'),
              ),
            ],
            if (onDismiss != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
                iconSize: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Snackbar-style notification
class FeedbackSnackBar extends SnackBar {
  FeedbackSnackBar({
    Key? key,
    required FeedbackMessage message,
  }) : super(
          key: key,
          content: Row(
            children: [
              if (message.type == FeedbackType.loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  message.type.icon,
                  color: Colors.white,
                  size: 16,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.title != null)
                      Text(
                        message.title!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    Text(
                      message.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: _getBackgroundColor(message.type),
          action: message.onRetry != null
              ? SnackBarAction(
                  label: '重试',
                  textColor: Colors.white,
                  onPressed: message.onRetry!,
                )
              : null,
          duration: message.duration ?? const Duration(seconds: 4),
        );

  static Color _getBackgroundColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.success:
        return Colors.green;
      case FeedbackType.error:
        return Colors.red;
      case FeedbackType.warning:
        return Colors.orange;
      case FeedbackType.info:
      case FeedbackType.loading:
        return Colors.blue;
      case FeedbackType.hideLoading:
        return Colors.grey;
    }
  }
}

/// Widget that listens to feedback messages and displays them
class FeedbackListener extends StatefulWidget {
  final Widget child;
  final FeedbackDisplayStyle displayStyle;

  const FeedbackListener({
    Key? key,
    required this.child,
    this.displayStyle = FeedbackDisplayStyle.toast,
  }) : super(key: key);

  @override
  State<FeedbackListener> createState() => _FeedbackListenerState();
}

class _FeedbackListenerState extends State<FeedbackListener> {
  late final FeedbackService _feedbackService;
  final List<FeedbackMessage> _activeMessages = [];
  FeedbackMessage? _currentLoadingMessage;

  @override
  void initState() {
    super.initState();
    _feedbackService = FeedbackService();
    _feedbackService.messageStream.listen(_handleMessage);
  }

  void _handleMessage(FeedbackMessage message) {
    if (!mounted) return;

    setState(() {
      if (message.type == FeedbackType.hideLoading) {
        _currentLoadingMessage = null;
      } else if (message.type == FeedbackType.loading) {
        _currentLoadingMessage = message;
      } else {
        // Remove any existing loading message when showing other messages
        if (message.type != FeedbackType.loading) {
          _currentLoadingMessage = null;
        }

        switch (widget.displayStyle) {
          case FeedbackDisplayStyle.toast:
          case FeedbackDisplayStyle.banner:
            _activeMessages.add(message);
            break;
          case FeedbackDisplayStyle.snackbar:
            ScaffoldMessenger.of(context).showSnackBar(
              FeedbackSnackBar(message: message),
            );
            break;
        }
      }
    });

    // Auto-remove messages after their duration
    if (message.duration != null && 
        (widget.displayStyle == FeedbackDisplayStyle.toast ||
         widget.displayStyle == FeedbackDisplayStyle.banner)) {
      Future.delayed(message.duration!, () {
        if (mounted) {
          setState(() {
            _activeMessages.remove(message);
          });
        }
      });
    }
  }

  void _dismissMessage(FeedbackMessage message) {
    setState(() {
      _activeMessages.remove(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        widget.child,
        if (_currentLoadingMessage != null || _activeMessages.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  if (_currentLoadingMessage != null)
                    _buildMessageWidget(_currentLoadingMessage!),
                  ..._activeMessages.map((message) => _buildMessageWidget(message)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageWidget(FeedbackMessage message) {
    switch (widget.displayStyle) {
      case FeedbackDisplayStyle.toast:
        return FeedbackToast(
          message: message,
          onDismiss: () => _dismissMessage(message),
        );
      case FeedbackDisplayStyle.banner:
        return FeedbackBanner(
          message: message,
          onDismiss: () => _dismissMessage(message),
        );
      case FeedbackDisplayStyle.snackbar:
        return const SizedBox.shrink(); // Handled in _handleMessage
    }
  }
}

/// Display styles for feedback messages
enum FeedbackDisplayStyle {
  toast,    // Floating toast notifications
  banner,   // Banner at top of screen
  snackbar, // Material snackbar at bottom
}