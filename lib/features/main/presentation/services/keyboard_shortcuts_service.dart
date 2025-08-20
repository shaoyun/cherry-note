import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 键盘快捷键服务
class KeyboardShortcutsService {
  static final KeyboardShortcutsService _instance = KeyboardShortcutsService._internal();
  factory KeyboardShortcutsService() => _instance;
  KeyboardShortcutsService._internal();

  final Map<LogicalKeySet, VoidCallback> _shortcuts = {};

  /// 注册快捷键
  void registerShortcut(LogicalKeySet keySet, VoidCallback callback) {
    _shortcuts[keySet] = callback;
  }

  /// 注销快捷键
  void unregisterShortcut(LogicalKeySet keySet) {
    _shortcuts.remove(keySet);
  }

  /// 清除所有快捷键
  void clearShortcuts() {
    _shortcuts.clear();
  }

  /// 获取所有快捷键
  Map<LogicalKeySet, VoidCallback> get shortcuts => Map.unmodifiable(_shortcuts);

  /// 处理键盘事件
  bool handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
      
      for (final keySet in _shortcuts.keys) {
        if (_isKeySetPressed(keySet, pressedKeys)) {
          _shortcuts[keySet]?.call();
          return true;
        }
      }
    }
    return false;
  }

  /// 检查按键组合是否被按下
  bool _isKeySetPressed(LogicalKeySet keySet, Set<LogicalKeyboardKey> pressedKeys) {
    return keySet.keys.every((key) => pressedKeys.contains(key)) &&
           keySet.keys.length == pressedKeys.length;
  }

  /// 注册默认快捷键
  void registerDefaultShortcuts({
    VoidCallback? onNewNote,
    VoidCallback? onNewFolder,
    VoidCallback? onOpenFile,
    VoidCallback? onSave,
    VoidCallback? onSaveAs,
    VoidCallback? onUndo,
    VoidCallback? onRedo,
    VoidCallback? onCut,
    VoidCallback? onCopy,
    VoidCallback? onPaste,
    VoidCallback? onSelectAll,
    VoidCallback? onFind,
    VoidCallback? onReplace,
    VoidCallback? onTogglePreview,
    VoidCallback? onToggleSidebar,
    VoidCallback? onZoomIn,
    VoidCallback? onZoomOut,
    VoidCallback? onResetZoom,
    VoidCallback? onFullScreen,
    VoidCallback? onSettings,
  }) {
    // 文件操作
    if (onNewNote != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN),
        onNewNote,
      );
    }
    
    if (onNewFolder != null) {
      registerShortcut(
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyN,
        ),
        onNewFolder,
      );
    }
    
    if (onOpenFile != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO),
        onOpenFile,
      );
    }
    
    if (onSave != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS),
        onSave,
      );
    }
    
    if (onSaveAs != null) {
      registerShortcut(
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyS,
        ),
        onSaveAs,
      );
    }

    // 编辑操作
    if (onUndo != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ),
        onUndo,
      );
    }
    
    if (onRedo != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY),
        onRedo,
      );
    }
    
    if (onCut != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX),
        onCut,
      );
    }
    
    if (onCopy != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC),
        onCopy,
      );
    }
    
    if (onPaste != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV),
        onPaste,
      );
    }
    
    if (onSelectAll != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA),
        onSelectAll,
      );
    }
    
    if (onFind != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF),
        onFind,
      );
    }
    
    if (onReplace != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyH),
        onReplace,
      );
    }

    // 视图操作
    if (onTogglePreview != null) {
      registerShortcut(
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyP,
        ),
        onTogglePreview,
      );
    }
    
    if (onToggleSidebar != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB),
        onToggleSidebar,
      );
    }
    
    if (onZoomIn != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.equal),
        onZoomIn,
      );
    }
    
    if (onZoomOut != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.minus),
        onZoomOut,
      );
    }
    
    if (onResetZoom != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit0),
        onResetZoom,
      );
    }
    
    if (onFullScreen != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.f11),
        onFullScreen,
      );
    }

    // 应用操作
    if (onSettings != null) {
      registerShortcut(
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma),
        onSettings,
      );
    }
  }

  /// 获取快捷键描述
  static String getShortcutDescription(LogicalKeySet keySet) {
    final keys = keySet.keys.toList();
    final parts = <String>[];
    
    // 修饰键
    if (keys.contains(LogicalKeyboardKey.control)) {
      parts.add('Ctrl');
    }
    if (keys.contains(LogicalKeyboardKey.shift)) {
      parts.add('Shift');
    }
    if (keys.contains(LogicalKeyboardKey.alt)) {
      parts.add('Alt');
    }
    if (keys.contains(LogicalKeyboardKey.meta)) {
      parts.add('Cmd');
    }
    
    // 主键
    final mainKeys = keys.where((key) => 
      key != LogicalKeyboardKey.control &&
      key != LogicalKeyboardKey.shift &&
      key != LogicalKeyboardKey.alt &&
      key != LogicalKeyboardKey.meta
    );
    
    for (final key in mainKeys) {
      parts.add(_getKeyDisplayName(key));
    }
    
    return parts.join('+');
  }

  /// 获取按键显示名称
  static String _getKeyDisplayName(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.keyA) return 'A';
    if (key == LogicalKeyboardKey.keyB) return 'B';
    if (key == LogicalKeyboardKey.keyC) return 'C';
    if (key == LogicalKeyboardKey.keyD) return 'D';
    if (key == LogicalKeyboardKey.keyE) return 'E';
    if (key == LogicalKeyboardKey.keyF) return 'F';
    if (key == LogicalKeyboardKey.keyG) return 'G';
    if (key == LogicalKeyboardKey.keyH) return 'H';
    if (key == LogicalKeyboardKey.keyI) return 'I';
    if (key == LogicalKeyboardKey.keyJ) return 'J';
    if (key == LogicalKeyboardKey.keyK) return 'K';
    if (key == LogicalKeyboardKey.keyL) return 'L';
    if (key == LogicalKeyboardKey.keyM) return 'M';
    if (key == LogicalKeyboardKey.keyN) return 'N';
    if (key == LogicalKeyboardKey.keyO) return 'O';
    if (key == LogicalKeyboardKey.keyP) return 'P';
    if (key == LogicalKeyboardKey.keyQ) return 'Q';
    if (key == LogicalKeyboardKey.keyR) return 'R';
    if (key == LogicalKeyboardKey.keyS) return 'S';
    if (key == LogicalKeyboardKey.keyT) return 'T';
    if (key == LogicalKeyboardKey.keyU) return 'U';
    if (key == LogicalKeyboardKey.keyV) return 'V';
    if (key == LogicalKeyboardKey.keyW) return 'W';
    if (key == LogicalKeyboardKey.keyX) return 'X';
    if (key == LogicalKeyboardKey.keyY) return 'Y';
    if (key == LogicalKeyboardKey.keyZ) return 'Z';
    
    if (key == LogicalKeyboardKey.digit0) return '0';
    if (key == LogicalKeyboardKey.digit1) return '1';
    if (key == LogicalKeyboardKey.digit2) return '2';
    if (key == LogicalKeyboardKey.digit3) return '3';
    if (key == LogicalKeyboardKey.digit4) return '4';
    if (key == LogicalKeyboardKey.digit5) return '5';
    if (key == LogicalKeyboardKey.digit6) return '6';
    if (key == LogicalKeyboardKey.digit7) return '7';
    if (key == LogicalKeyboardKey.digit8) return '8';
    if (key == LogicalKeyboardKey.digit9) return '9';
    
    if (key == LogicalKeyboardKey.f1) return 'F1';
    if (key == LogicalKeyboardKey.f2) return 'F2';
    if (key == LogicalKeyboardKey.f3) return 'F3';
    if (key == LogicalKeyboardKey.f4) return 'F4';
    if (key == LogicalKeyboardKey.f5) return 'F5';
    if (key == LogicalKeyboardKey.f6) return 'F6';
    if (key == LogicalKeyboardKey.f7) return 'F7';
    if (key == LogicalKeyboardKey.f8) return 'F8';
    if (key == LogicalKeyboardKey.f9) return 'F9';
    if (key == LogicalKeyboardKey.f10) return 'F10';
    if (key == LogicalKeyboardKey.f11) return 'F11';
    if (key == LogicalKeyboardKey.f12) return 'F12';
    
    if (key == LogicalKeyboardKey.equal) return '=';
    if (key == LogicalKeyboardKey.minus) return '-';
    if (key == LogicalKeyboardKey.comma) return ',';
    if (key == LogicalKeyboardKey.period) return '.';
    if (key == LogicalKeyboardKey.slash) return '/';
    if (key == LogicalKeyboardKey.backslash) return '\\';
    if (key == LogicalKeyboardKey.semicolon) return ';';
    if (key == LogicalKeyboardKey.quote) return "'";
    if (key == LogicalKeyboardKey.bracketLeft) return '[';
    if (key == LogicalKeyboardKey.bracketRight) return ']';
    if (key == LogicalKeyboardKey.backquote) return '`';
    
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.escape) return 'Esc';
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.backspace) return 'Backspace';
    if (key == LogicalKeyboardKey.delete) return 'Delete';
    if (key == LogicalKeyboardKey.insert) return 'Insert';
    if (key == LogicalKeyboardKey.home) return 'Home';
    if (key == LogicalKeyboardKey.end) return 'End';
    if (key == LogicalKeyboardKey.pageUp) return 'Page Up';
    if (key == LogicalKeyboardKey.pageDown) return 'Page Down';
    
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    
    return key.keyLabel;
  }
}

/// 快捷键包装器组件
class ShortcutsWrapper extends StatefulWidget {
  final Widget child;
  final Map<LogicalKeySet, VoidCallback>? shortcuts;

  const ShortcutsWrapper({
    super.key,
    required this.child,
    this.shortcuts,
  });

  @override
  State<ShortcutsWrapper> createState() => _ShortcutsWrapperState();
}

class _ShortcutsWrapperState extends State<ShortcutsWrapper> {
  late final KeyboardShortcutsService _shortcutsService;

  @override
  void initState() {
    super.initState();
    _shortcutsService = KeyboardShortcutsService();
    
    // 注册快捷键
    if (widget.shortcuts != null) {
      for (final entry in widget.shortcuts!.entries) {
        _shortcutsService.registerShortcut(entry.key, entry.value);
      }
    }
  }

  @override
  void dispose() {
    _shortcutsService.clearShortcuts();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (_shortcutsService.handleKeyEvent(event)) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}