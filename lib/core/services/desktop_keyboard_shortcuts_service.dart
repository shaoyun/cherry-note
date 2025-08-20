import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service for handling desktop keyboard shortcuts
class DesktopKeyboardShortcutsService {
  static final Map<LogicalKeySet, VoidCallback> _shortcuts = {};
  static final Map<String, LogicalKeySet> _shortcutKeys = {};
  
  /// Initialize desktop keyboard shortcuts
  static void initialize() {
    if (!_isDesktop()) return;
    
    _registerDefaultShortcuts();
  }
  
  /// Register a keyboard shortcut
  static void registerShortcut({
    required String id,
    required LogicalKeySet keySet,
    required VoidCallback callback,
  }) {
    _shortcuts[keySet] = callback;
    _shortcutKeys[id] = keySet;
  }
  
  /// Unregister a keyboard shortcut
  static void unregisterShortcut(String id) {
    final keySet = _shortcutKeys[id];
    if (keySet != null) {
      _shortcuts.remove(keySet);
      _shortcutKeys.remove(id);
    }
  }
  
  /// Get all registered shortcuts
  static Map<LogicalKeySet, VoidCallback> getShortcuts() {
    return Map.unmodifiable(_shortcuts);
  }
  
  /// Create shortcuts widget wrapper
  static Widget createShortcutsWrapper({
    required Widget child,
    Map<LogicalKeySet, VoidCallback>? additionalShortcuts,
  }) {
    if (!_isDesktop()) return child;
    
    final allShortcuts = <LogicalKeySet, VoidCallback>{
      ..._shortcuts,
      ...?additionalShortcuts,
    };
    
    return Shortcuts(
      shortcuts: allShortcuts.map((key, value) => MapEntry(
        key,
        CallbackAction<Intent>(onInvoke: (_) => value()),
      )),
      child: child,
    );
  }
  
  /// Register default application shortcuts
  static void _registerDefaultShortcuts() {
    // File operations
    registerShortcut(
      id: 'new_note',
      keySet: _getKeySet(['ctrl', 'n']),
      callback: () => _handleShortcut('new_note'),
    );
    
    registerShortcut(
      id: 'open_file',
      keySet: _getKeySet(['ctrl', 'o']),
      callback: () => _handleShortcut('open_file'),
    );
    
    registerShortcut(
      id: 'save_file',
      keySet: _getKeySet(['ctrl', 's']),
      callback: () => _handleShortcut('save_file'),
    );
    
    registerShortcut(
      id: 'save_as',
      keySet: _getKeySet(['ctrl', 'shift', 's']),
      callback: () => _handleShortcut('save_as'),
    );
    
    // Edit operations
    registerShortcut(
      id: 'undo',
      keySet: _getKeySet(['ctrl', 'z']),
      callback: () => _handleShortcut('undo'),
    );
    
    registerShortcut(
      id: 'redo',
      keySet: _getKeySet(['ctrl', 'y']),
      callback: () => _handleShortcut('redo'),
    );
    
    registerShortcut(
      id: 'find',
      keySet: _getKeySet(['ctrl', 'f']),
      callback: () => _handleShortcut('find'),
    );
    
    registerShortcut(
      id: 'find_replace',
      keySet: _getKeySet(['ctrl', 'h']),
      callback: () => _handleShortcut('find_replace'),
    );
    
    // View operations
    registerShortcut(
      id: 'toggle_preview',
      keySet: _getKeySet(['ctrl', 'p']),
      callback: () => _handleShortcut('toggle_preview'),
    );
    
    registerShortcut(
      id: 'toggle_sidebar',
      keySet: _getKeySet(['ctrl', 'b']),
      callback: () => _handleShortcut('toggle_sidebar'),
    );
    
    registerShortcut(
      id: 'zoom_in',
      keySet: _getKeySet(['ctrl', 'plus']),
      callback: () => _handleShortcut('zoom_in'),
    );
    
    registerShortcut(
      id: 'zoom_out',
      keySet: _getKeySet(['ctrl', 'minus']),
      callback: () => _handleShortcut('zoom_out'),
    );
    
    registerShortcut(
      id: 'zoom_reset',
      keySet: _getKeySet(['ctrl', '0']),
      callback: () => _handleShortcut('zoom_reset'),
    );
    
    // Application operations
    registerShortcut(
      id: 'settings',
      keySet: _getKeySet(['ctrl', 'comma']),
      callback: () => _handleShortcut('settings'),
    );
    
    registerShortcut(
      id: 'quit',
      keySet: _getKeySet(['ctrl', 'q']),
      callback: () => _handleShortcut('quit'),
    );
    
    // Markdown formatting shortcuts
    registerShortcut(
      id: 'bold',
      keySet: _getKeySet(['ctrl', 'b']),
      callback: () => _handleShortcut('bold'),
    );
    
    registerShortcut(
      id: 'italic',
      keySet: _getKeySet(['ctrl', 'i']),
      callback: () => _handleShortcut('italic'),
    );
    
    registerShortcut(
      id: 'code',
      keySet: _getKeySet(['ctrl', 'grave']),
      callback: () => _handleShortcut('code'),
    );
    
    registerShortcut(
      id: 'link',
      keySet: _getKeySet(['ctrl', 'k']),
      callback: () => _handleShortcut('link'),
    );
    
    // Navigation shortcuts
    registerShortcut(
      id: 'go_to_line',
      keySet: _getKeySet(['ctrl', 'g']),
      callback: () => _handleShortcut('go_to_line'),
    );
    
    registerShortcut(
      id: 'command_palette',
      keySet: _getKeySet(['ctrl', 'shift', 'p']),
      callback: () => _handleShortcut('command_palette'),
    );
  }
  
  /// Get platform-specific key set
  static LogicalKeySet _getKeySet(List<String> keys) {
    final logicalKeys = <LogicalKeyboardKey>[];
    
    for (final key in keys) {
      switch (key.toLowerCase()) {
        case 'ctrl':
          logicalKeys.add(Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control);
          break;
        case 'alt':
          logicalKeys.add(LogicalKeyboardKey.alt);
          break;
        case 'shift':
          logicalKeys.add(LogicalKeyboardKey.shift);
          break;
        case 'meta':
        case 'cmd':
          logicalKeys.add(LogicalKeyboardKey.meta);
          break;
        case 'n':
          logicalKeys.add(LogicalKeyboardKey.keyN);
          break;
        case 'o':
          logicalKeys.add(LogicalKeyboardKey.keyO);
          break;
        case 's':
          logicalKeys.add(LogicalKeyboardKey.keyS);
          break;
        case 'z':
          logicalKeys.add(LogicalKeyboardKey.keyZ);
          break;
        case 'y':
          logicalKeys.add(LogicalKeyboardKey.keyY);
          break;
        case 'f':
          logicalKeys.add(LogicalKeyboardKey.keyF);
          break;
        case 'h':
          logicalKeys.add(LogicalKeyboardKey.keyH);
          break;
        case 'p':
          logicalKeys.add(LogicalKeyboardKey.keyP);
          break;
        case 'b':
          logicalKeys.add(LogicalKeyboardKey.keyB);
          break;
        case 'i':
          logicalKeys.add(LogicalKeyboardKey.keyI);
          break;
        case 'k':
          logicalKeys.add(LogicalKeyboardKey.keyK);
          break;
        case 'g':
          logicalKeys.add(LogicalKeyboardKey.keyG);
          break;
        case 'q':
          logicalKeys.add(LogicalKeyboardKey.keyQ);
          break;
        case 'plus':
          logicalKeys.add(LogicalKeyboardKey.equal);
          break;
        case 'minus':
          logicalKeys.add(LogicalKeyboardKey.minus);
          break;
        case '0':
          logicalKeys.add(LogicalKeyboardKey.digit0);
          break;
        case 'comma':
          logicalKeys.add(LogicalKeyboardKey.comma);
          break;
        case 'grave':
          logicalKeys.add(LogicalKeyboardKey.backquote);
          break;
        default:
          print('Unknown key: $key');
      }
    }
    
    return LogicalKeySet.fromSet(logicalKeys.toSet());
  }
  
  /// Handle shortcut execution
  static void _handleShortcut(String shortcutId) {
    // This would be implemented to dispatch events to the appropriate handlers
    print('Executing shortcut: $shortcutId');
    
    // In a real implementation, this would use a service locator or event bus
    // to notify the appropriate components about the shortcut execution
  }
  
  /// Get platform-specific modifier key name
  static String getModifierKeyName() {
    return Platform.isMacOS ? 'Cmd' : 'Ctrl';
  }
  
  /// Get shortcut display text
  static String getShortcutDisplayText(String shortcutId) {
    final keySet = _shortcutKeys[shortcutId];
    if (keySet == null) return '';
    
    final keys = keySet.keys.toList();
    final displayKeys = <String>[];
    
    for (final key in keys) {
      if (key == LogicalKeyboardKey.control) {
        displayKeys.add('Ctrl');
      } else if (key == LogicalKeyboardKey.meta) {
        displayKeys.add(Platform.isMacOS ? 'Cmd' : 'Win');
      } else if (key == LogicalKeyboardKey.alt) {
        displayKeys.add('Alt');
      } else if (key == LogicalKeyboardKey.shift) {
        displayKeys.add('Shift');
      } else {
        displayKeys.add(key.keyLabel.toUpperCase());
      }
    }
    
    return displayKeys.join('+');
  }
  
  static bool _isDesktop() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}