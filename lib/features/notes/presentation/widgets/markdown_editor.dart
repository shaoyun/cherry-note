import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'markdown_syntax_highlighter.dart';
import 'markdown_toolbar.dart';
import 'auto_save_mixin.dart';
import 'image_insertion_dialog.dart';

class MarkdownEditor extends StatefulWidget {
  final String initialContent;
  final ValueChanged<String>? onContentChanged;
  final VoidCallback? onAutoSave;
  final bool showPreview;
  final bool enableSyntaxHighlighting;
  final bool showToolbar;
  final bool enableAutoSave;
  final Duration autoSaveInterval;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const MarkdownEditor({
    super.key,
    this.initialContent = '',
    this.onContentChanged,
    this.onAutoSave,
    this.showPreview = true,
    this.enableSyntaxHighlighting = true,
    this.showToolbar = true,
    this.enableAutoSave = true,
    this.autoSaveInterval = const Duration(seconds: 30),
    this.textStyle,
    this.padding,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> with AutoSaveMixin {
  MarkdownSyntaxHighlighter? _controller;
  late ScrollController _editorScrollController;
  late ScrollController _previewScrollController;
  bool _isPreviewMode = false;
  bool _isSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    _editorScrollController = ScrollController();
    _previewScrollController = ScrollController();
    
    _editorScrollController.addListener(_onEditorScroll);
    _previewScrollController.addListener(_onPreviewScroll);
    
    // Initialize auto-save
    initAutoSave();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      _controller = MarkdownSyntaxHighlighter(
        text: widget.initialContent,
        theme: Theme.of(context),
      );
      _controller!.addListener(_onContentChanged);
    }
  }

  @override
  void dispose() {
    disposeAutoSave();
    _controller?.dispose();
    _editorScrollController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    setState(() {
      // Trigger rebuild to update character count
    });
    final content = _controller?.text ?? '';
    widget.onContentChanged?.call(content);
    onContentChanged(content);
  }

  // AutoSaveMixin implementation
  @override
  String get currentContent => _controller?.text ?? '';

  @override
  void onAutoSave(String content) {
    widget.onAutoSave?.call();
  }

  @override
  Duration get autoSaveInterval => widget.autoSaveInterval;

  @override
  bool get autoSaveEnabled => widget.enableAutoSave;

  void _onEditorScroll() {
    if (_isSyncingScroll || !widget.showPreview || _isPreviewMode) return;
    
    _isSyncingScroll = true;
    final ratio = _editorScrollController.offset / 
                  _editorScrollController.position.maxScrollExtent;
    
    if (_previewScrollController.hasClients && 
        _previewScrollController.position.maxScrollExtent > 0) {
      _previewScrollController.jumpTo(
        ratio * _previewScrollController.position.maxScrollExtent,
      );
    }
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _isSyncingScroll = false;
    });
  }

  void _onPreviewScroll() {
    if (_isSyncingScroll || !widget.showPreview || !_isPreviewMode) return;
    
    _isSyncingScroll = true;
    final ratio = _previewScrollController.offset / 
                  _previewScrollController.position.maxScrollExtent;
    
    if (_editorScrollController.hasClients && 
        _editorScrollController.position.maxScrollExtent > 0) {
      _editorScrollController.jumpTo(
        ratio * _editorScrollController.position.maxScrollExtent,
      );
    }
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _isSyncingScroll = false;
    });
  }

  void _togglePreviewMode() {
    setState(() {
      _isPreviewMode = !_isPreviewMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Markdown Toolbar
        if (widget.showToolbar && _controller != null)
          MarkdownToolbar(
            controller: _controller!,
            onImageInsert: _handleImageInsert,
            onLinkInsert: _handleLinkInsert,
            enabled: !_isPreviewMode,
          ),
        
        // Status Toolbar
        _buildStatusToolbar(theme),
        
        // Editor/Preview Area
        Expanded(
          child: widget.showPreview && !_isPreviewMode
              ? _buildSplitView(theme)
              : _isPreviewMode
                  ? _buildPreviewOnly(theme)
                  : _buildEditorOnly(theme),
        ),
      ],
    );
  }

  Widget _buildStatusToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          if (widget.showPreview) ...[
            IconButton(
              onPressed: _togglePreviewMode,
              icon: Icon(_isPreviewMode ? Icons.edit : Icons.preview),
              tooltip: _isPreviewMode ? 'Edit Mode' : 'Preview Mode',
              iconSize: 20,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            'Markdown Editor',
            style: theme.textTheme.titleSmall,
          ),
          const Spacer(),
          if (hasUnsavedChanges) ...[
            Icon(
              Icons.circle,
              size: 8,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Unsaved',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Text(
            '${_controller?.text.length ?? 0} characters',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _handleImageInsert() {
    showImageInsertionDialog(context, (imageMarkdown) {
      final controller = _controller;
      if (controller != null) {
        final selection = controller.selection;
        final text = controller.text;
        final cursorPos = selection.baseOffset;
        
        controller.text = text.replaceRange(cursorPos, cursorPos, imageMarkdown);
        controller.selection = TextSelection.collapsed(
          offset: cursorPos + imageMarkdown.length,
        );
      }
    });
  }

  void _handleLinkInsert() {
    // Link insertion is handled by the toolbar itself
    // This callback can be used for analytics or other purposes
  }

  Widget _buildSplitView(ThemeData theme) {
    return Row(
      children: [
        // Editor
        Expanded(
          child: _buildEditor(theme),
        ),
        
        // Divider
        Container(
          width: 1,
          color: theme.dividerColor,
        ),
        
        // Preview
        Expanded(
          child: _buildPreview(theme),
        ),
      ],
    );
  }

  Widget _buildEditorOnly(ThemeData theme) {
    return _buildEditor(theme);
  }

  Widget _buildPreviewOnly(ThemeData theme) {
    return _buildPreview(theme);
  }

  Widget _buildEditor(ThemeData theme) {
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16.0),
      child: TextField(
        controller: _controller,
        scrollController: _editorScrollController,
        maxLines: null,
        expands: true,
        style: widget.textStyle ?? theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Start writing your markdown...',
          contentPadding: EdgeInsets.zero,
        ),
        textAlignVertical: TextAlignVertical.top,
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final content = _controller?.text ?? '';
    
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16.0),
      child: Markdown(
        controller: _previewScrollController,
        data: content.isEmpty ? '_No content to preview_' : content,
        selectable: true,
        extensionSet: md.ExtensionSet(
          md.ExtensionSet.gitHubFlavored.blockSyntaxes,
          [
            md.EmojiSyntax(),
            ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          ],
        ),
        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
          p: theme.textTheme.bodyMedium,
          h1: theme.textTheme.headlineMedium,
          h2: theme.textTheme.headlineSmall,
          h3: theme.textTheme.titleLarge,
          h4: theme.textTheme.titleMedium,
          h5: theme.textTheme.titleSmall,
          h6: theme.textTheme.labelLarge,
          code: theme.textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
            backgroundColor: theme.colorScheme.surfaceVariant,
          ),
          codeblockDecoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}