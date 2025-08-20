import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Desktop-specific UI adaptations and optimizations
class DesktopUIAdaptations {
  
  /// Configure desktop-specific system UI
  static void configureSystemUI() {
    if (!_isDesktop()) return;
    
    // Configure system chrome for desktop
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Set preferred orientations (desktop supports all)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  
  /// Create desktop-specific app bar
  static PreferredSizeWidget createDesktopAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool showWindowControls = true,
  }) {
    if (!_isDesktop()) {
      return AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
      );
    }
    
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            if (leading != null) leading,
            Expanded(
              child: DragToMoveArea(
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            if (actions != null) ...actions,
            if (showWindowControls) const WindowControls(),
          ],
        ),
      ),
    );
  }
  
  /// Create desktop-specific context menu
  static Widget createDesktopContextMenu({
    required Widget child,
    required List<PopupMenuEntry> menuItems,
  }) {
    if (!_isDesktop()) {
      return child;
    }
    
    return GestureDetector(
      onSecondaryTapUp: (details) {
        _showContextMenu(child.key?.currentContext, details.globalPosition, menuItems);
      },
      child: child,
    );
  }
  
  /// Show context menu at position
  static void _showContextMenu(
    BuildContext? context,
    Offset position,
    List<PopupMenuEntry> items,
  ) {
    if (context == null) return;
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
    );
  }
  
  /// Create desktop-specific tooltip
  static Widget createDesktopTooltip({
    required String message,
    required Widget child,
    Duration? waitDuration,
  }) {
    if (!_isDesktop()) {
      return Tooltip(
        message: message,
        child: child,
      );
    }
    
    return Tooltip(
      message: message,
      waitDuration: waitDuration ?? const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
      child: child,
    );
  }
  
  /// Create desktop-specific scrollbar
  static Widget createDesktopScrollbar({
    required Widget child,
    ScrollController? controller,
    bool isAlwaysShown = false,
  }) {
    if (!_isDesktop()) {
      return child;
    }
    
    return Scrollbar(
      controller: controller,
      thumbVisibility: isAlwaysShown,
      trackVisibility: isAlwaysShown,
      thickness: 12,
      radius: const Radius.circular(6),
      child: child,
    );
  }
  
  /// Create desktop-specific resizable pane
  static Widget createResizablePane({
    required Widget child,
    required double initialSize,
    required double minSize,
    required double maxSize,
    required ValueChanged<double> onSizeChanged,
    bool isVertical = false,
  }) {
    if (!_isDesktop()) {
      return child;
    }
    
    return ResizablePane(
      initialSize: initialSize,
      minSize: minSize,
      maxSize: maxSize,
      onSizeChanged: onSizeChanged,
      isVertical: isVertical,
      child: child,
    );
  }
  
  /// Get desktop-specific text scale factor
  static double getDesktopTextScaleFactor(BuildContext context) {
    if (!_isDesktop()) return 1.0;
    
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);
    
    // Desktop can handle larger text scaling
    return textScaleFactor.clamp(0.7, 2.0);
  }
  
  /// Create desktop-specific button
  static Widget createDesktopButton({
    required VoidCallback onPressed,
    required Widget child,
    ButtonStyle? style,
  }) {
    if (!_isDesktop()) {
      return ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      );
    }
    
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ).merge(style),
      child: child,
    );
  }
  
  /// Handle desktop-specific focus management
  static void handleDesktopFocus(BuildContext context, FocusNode focusNode) {
    if (!_isDesktop()) return;
    
    // Desktop focus behavior
    focusNode.requestFocus();
  }
  
  static bool _isDesktop() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}

/// Widget for dragging window on desktop
class DragToMoveArea extends StatelessWidget {
  final Widget child;
  
  const DragToMoveArea({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return child;
    }
    
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        // Start window drag
      },
      child: child,
    );
  }
}

/// Window control buttons for desktop
class WindowControls extends StatelessWidget {
  const WindowControls({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return const SizedBox.shrink();
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowControlButton(
          icon: Icons.minimize,
          onPressed: () {
            // Minimize window
          },
        ),
        _WindowControlButton(
          icon: Icons.crop_square,
          onPressed: () {
            // Maximize/restore window
          },
        ),
        _WindowControlButton(
          icon: Icons.close,
          onPressed: () {
            // Close window
          },
          isClose: true,
        ),
      ],
    );
  }
}

class _WindowControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;
  
  const _WindowControlButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  }) : super(key: key);
  
  @override
  State<_WindowControlButton> createState() => _WindowControlButtonState();
}

class _WindowControlButtonState extends State<_WindowControlButton> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isClose ? Colors.red : Colors.grey[200])
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: _isHovered && widget.isClose ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// Resizable pane widget for desktop
class ResizablePane extends StatefulWidget {
  final Widget child;
  final double initialSize;
  final double minSize;
  final double maxSize;
  final ValueChanged<double> onSizeChanged;
  final bool isVertical;
  
  const ResizablePane({
    Key? key,
    required this.child,
    required this.initialSize,
    required this.minSize,
    required this.maxSize,
    required this.onSizeChanged,
    this.isVertical = false,
  }) : super(key: key);
  
  @override
  State<ResizablePane> createState() => _ResizablePaneState();
}

class _ResizablePaneState extends State<ResizablePane> {
  late double _currentSize;
  
  @override
  void initState() {
    super.initState();
    _currentSize = widget.initialSize;
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.isVertical ? null : _currentSize,
      height: widget.isVertical ? _currentSize : null,
      child: Column(
        children: [
          Expanded(child: widget.child),
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                if (widget.isVertical) {
                  _currentSize += details.delta.dy;
                } else {
                  _currentSize += details.delta.dx;
                }
                _currentSize = _currentSize.clamp(widget.minSize, widget.maxSize);
              });
              widget.onSizeChanged(_currentSize);
            },
            child: MouseRegion(
              cursor: widget.isVertical
                  ? SystemMouseCursors.resizeUpDown
                  : SystemMouseCursors.resizeLeftRight,
              child: Container(
                width: widget.isVertical ? double.infinity : 4,
                height: widget.isVertical ? 4 : double.infinity,
                color: Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }
}