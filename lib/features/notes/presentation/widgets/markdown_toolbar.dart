import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onImageInsert;
  final VoidCallback? onLinkInsert;
  final bool enabled;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    this.onImageInsert,
    this.onLinkInsert,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolbarButton(
              context,
              icon: Icons.format_bold,
              tooltip: 'Bold (Ctrl+B)',
              onPressed: enabled ? () => _insertMarkdown('**', '**') : null,
            ),
            _buildToolbarButton(
              context,
              icon: Icons.format_italic,
              tooltip: 'Italic (Ctrl+I)',
              onPressed: enabled ? () => _insertMarkdown('*', '*') : null,
            ),
            _buildToolbarButton(
              context,
              icon: Icons.strikethrough_s,
              tooltip: 'Strikethrough',
              onPressed: enabled ? () => _insertMarkdown('~~', '~~') : null,
            ),
            const VerticalDivider(width: 16),
            _buildToolbarButton(
              context,
              icon: Icons.title,
              tooltip: 'Heading 1',
              onPressed: enabled ? () => _insertLinePrefix('# ') : null,
            ),
            _buildToolbarButton(
              context,
              icon: Icons.format_size,
              tooltip: 'Heading 2',
              onPressed: enabled ? () => _insertLinePrefix('## ') : null,
            ),
            const VerticalDivider(width: 16),
            _buildToolbarButton(
              context,
              icon: Icons.format_list_bulleted,
              tooltip: 'Bullet List',
              onPressed: enabled ? () => _insertLinePrefix('- ') : null,
            ),
            _buildToolbarButton(
              context,
              icon: Icons.format_list_numbered,
              tooltip: 'Numbered List',
              onPressed: enabled ? () => _insertLinePrefix('1. ') : null,
            ),
            _buildToolbarButton(
              context,
              icon: Icons.format_quote,
              tooltip: 'Quote',
              onPressed: enabled ? () => _insertLinePrefix('> ') : null,
            ),
            const VerticalDivider(width: 16),
            _buildToolbarButton(
              context,
              icon: Icons.code,
              tooltip: 'Inline Code',
              onPressed: enabled ? () => _insertMarkdown('`', '`') : null,
            ),
            _buildToolbarButton(
              context,
              icon: Icons.code_off,
              tooltip: 'Code Block',
              onPressed: enabled ? _insertCodeBlock : null,
            ),
            const VerticalDivider(width: 16),
            _buildToolbarButton(
              context,
              icon: Icons.link,
              tooltip: 'Insert Link',
              onPressed: enabled ? _insertLink : null,
            ),
            _buildToolbarButton(
              context,
              icon: Icons.image,
              tooltip: 'Insert Image',
              onPressed: enabled ? _insertImage : null,
            ),
            const VerticalDivider(width: 16),
            _buildToolbarButton(
              context,
              icon: Icons.horizontal_rule,
              tooltip: 'Horizontal Rule',
              onPressed: enabled ? () => _insertLinePrefix('---\n') : null,
            ),
            _buildToolbarButton(
              context,
              icon: Icons.table_chart,
              tooltip: 'Insert Table',
              onPressed: enabled ? _insertTable : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        splashRadius: 16,
      ),
    );
  }

  void _insertMarkdown(String prefix, String suffix) {
    final selection = controller.selection;
    final text = controller.text;
    
    if (selection.isValid && selection.start != selection.end) {
      // Text is selected
      final selectedText = selection.textInside(text);
      final newText = '$prefix$selectedText$suffix';
      
      controller.text = text.replaceRange(
        selection.start,
        selection.end,
        newText,
      );
      
      // Update cursor position
      final newCursorPos = selection.start + prefix.length + selectedText.length + suffix.length;
      controller.selection = TextSelection.collapsed(offset: newCursorPos);
    } else {
      // No selection, insert at cursor position
      final cursorPos = selection.isValid ? selection.baseOffset : text.length;
      final newText = '$prefix$suffix';
      
      controller.text = text.replaceRange(cursorPos, cursorPos, newText);
      
      // Position cursor between prefix and suffix
      controller.selection = TextSelection.collapsed(
        offset: cursorPos + prefix.length,
      );
    }
  }

  void _insertLinePrefix(String prefix) {
    final selection = controller.selection;
    final text = controller.text;
    final cursorPos = selection.isValid ? selection.baseOffset : text.length;
    
    // Find the start of the current line
    int lineStart = cursorPos;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    
    // Insert prefix at the beginning of the line
    controller.text = text.replaceRange(lineStart, lineStart, prefix);
    
    // Update cursor position
    controller.selection = TextSelection.collapsed(
      offset: cursorPos + prefix.length,
    );
  }

  void _insertCodeBlock() {
    final selection = controller.selection;
    final text = controller.text;
    final cursorPos = selection.isValid ? selection.baseOffset : text.length;
    
    const codeBlock = '```\n\n```';
    
    controller.text = text.replaceRange(cursorPos, cursorPos, codeBlock);
    
    // Position cursor inside the code block
    controller.selection = TextSelection.collapsed(
      offset: cursorPos + 4, // After "```\n"
    );
  }

  void _insertLink() {
    final selection = controller.selection;
    final text = controller.text;
    
    if (selection.isValid && selection.start != selection.end) {
      final selectedText = selection.textInside(text);
      final linkText = '[${selectedText.isNotEmpty ? selectedText : 'Link Text'}](URL)';
      
      controller.text = text.replaceRange(
        selection.start,
        selection.end,
        linkText,
      );
      
      // Select the URL part for easy editing
      final urlStart = selection.start + linkText.indexOf('(') + 1;
      final urlEnd = urlStart + 3; // Length of "URL"
      controller.selection = TextSelection(
        baseOffset: urlStart,
        extentOffset: urlEnd,
      );
    } else {
      const linkText = '[Link Text](URL)';
      final cursorPos = selection.isValid ? selection.baseOffset : text.length;
      
      controller.text = text.replaceRange(cursorPos, cursorPos, linkText);
      
      // Select "Link Text" for easy editing
      controller.selection = TextSelection(
        baseOffset: cursorPos + 1,
        extentOffset: cursorPos + 10, // Length of "Link Text"
      );
    }
    
    onLinkInsert?.call();
  }

  void _insertImage() {
    final selection = controller.selection;
    final text = controller.text;
    final cursorPos = selection.isValid ? selection.baseOffset : text.length;
    
    const imageText = '![Alt Text](image-url)';
    
    controller.text = text.replaceRange(cursorPos, cursorPos, imageText);
    
    // Select "Alt Text" for easy editing
    controller.selection = TextSelection(
      baseOffset: cursorPos + 2,
      extentOffset: cursorPos + 10, // Length of "Alt Text"
    );
    
    onImageInsert?.call();
  }

  void _insertTable() {
    final selection = controller.selection;
    final text = controller.text;
    final cursorPos = selection.isValid ? selection.baseOffset : text.length;
    
    const tableText = '''
| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |
''';
    
    controller.text = text.replaceRange(cursorPos, cursorPos, tableText);
    
    // Position cursor at the first header
    controller.selection = TextSelection(
      baseOffset: cursorPos + 2,
      extentOffset: cursorPos + 10, // Length of "Header 1"
    );
  }
}