import 'dart:async';
import 'package:flutter/material.dart';

mixin AutoSaveMixin<T extends StatefulWidget> on State<T> {
  Timer? _autoSaveTimer;
  String _lastSavedContent = '';
  bool _hasUnsavedChanges = false;
  
  // Override these in your widget
  String get currentContent;
  void onAutoSave(String content);
  Duration get autoSaveInterval => const Duration(seconds: 30);
  bool get autoSaveEnabled => true;

  void initAutoSave() {
    if (autoSaveEnabled) {
      _startAutoSaveTimer();
    }
  }

  void disposeAutoSave() {
    _autoSaveTimer?.cancel();
  }

  void onContentChanged(String newContent) {
    if (newContent != _lastSavedContent) {
      _hasUnsavedChanges = true;
      _resetAutoSaveTimer();
    }
  }

  void markAsSaved() {
    setState(() {
      _lastSavedContent = currentContent;
      _hasUnsavedChanges = false;
    });
  }

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(autoSaveInterval, (timer) {
      if (_hasUnsavedChanges && currentContent.isNotEmpty) {
        onAutoSave(currentContent);
        setState(() {
          _lastSavedContent = currentContent;
          _hasUnsavedChanges = false;
        });
      }
    });
  }

  void _resetAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    if (autoSaveEnabled) {
      _startAutoSaveTimer();
    }
  }

  void forceAutoSave() {
    if (_hasUnsavedChanges && currentContent.isNotEmpty) {
      onAutoSave(currentContent);
      setState(() {
        _lastSavedContent = currentContent;
        _hasUnsavedChanges = false;
      });
    }
  }
}