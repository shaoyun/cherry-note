import 'package:flutter/material.dart';

class MarkdownSyntaxHighlighter extends TextEditingController {
  final Map<String, TextStyle> _syntaxStyles;
  final RegExp _markdownPatterns = RegExp(
    r'(#{1,6}\s.*$)|'  // Headers
    r'(\*\*.*?\*\*)|'  // Bold
    r'(\*.*?\*)|'      // Italic
    r'(`.*?`)|'        // Inline code
    r'(```[\s\S]*?```)|' // Code blocks
    r'(\[.*?\]\(.*?\))|' // Links
    r'(!\[.*?\]\(.*?\))|' // Images
    r'(^\s*[-*+]\s)|'  // Unordered lists
    r'(^\s*\d+\.\s)|'  // Ordered lists
    r'(^\s*>\s)|'      // Blockquotes
    r'(^\s*---\s*$)|'  // Horizontal rules
    r'(~~.*?~~)',      // Strikethrough
    multiLine: true,
  );

  MarkdownSyntaxHighlighter({
    String? text,
    required ThemeData theme,
  }) : _syntaxStyles = _createSyntaxStyles(theme),
       super(text: text);

  static Map<String, TextStyle> _createSyntaxStyles(ThemeData theme) {
    final baseStyle = theme.textTheme.bodyMedium ?? const TextStyle();
    
    return {
      'header': baseStyle.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      'bold': baseStyle.copyWith(
        fontWeight: FontWeight.bold,
      ),
      'italic': baseStyle.copyWith(
        fontStyle: FontStyle.italic,
      ),
      'code': baseStyle.copyWith(
        fontFamily: 'monospace',
        backgroundColor: theme.colorScheme.surfaceVariant,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      'codeBlock': baseStyle.copyWith(
        fontFamily: 'monospace',
        backgroundColor: theme.colorScheme.surfaceVariant,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      'link': baseStyle.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      'image': baseStyle.copyWith(
        color: theme.colorScheme.secondary,
      ),
      'list': baseStyle.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
      'blockquote': baseStyle.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
        fontStyle: FontStyle.italic,
      ),
      'rule': baseStyle.copyWith(
        color: theme.colorScheme.outline,
      ),
      'strikethrough': baseStyle.copyWith(
        decoration: TextDecoration.lineThrough,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
    };
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final theme = Theme.of(context);
    final baseStyle = style ?? theme.textTheme.bodyMedium ?? const TextStyle();
    
    if (text.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    final spans = <TextSpan>[];
    final matches = _markdownPatterns.allMatches(text);
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      // Add styled match
      final matchText = match.group(0)!;
      final matchStyle = _getStyleForMatch(match, baseStyle);
      
      spans.add(TextSpan(
        text: matchText,
        style: matchStyle,
      ));

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    // If no matches found, return a single span with the entire text
    if (spans.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }

    return TextSpan(children: spans);
  }

  TextStyle _getStyleForMatch(RegExpMatch match, TextStyle baseStyle) {
    final matchText = match.group(0)!;
    
    // Headers
    if (match.group(1) != null) {
      return _syntaxStyles['header']!;
    }
    // Bold
    else if (match.group(2) != null) {
      return _syntaxStyles['bold']!;
    }
    // Italic
    else if (match.group(3) != null) {
      return _syntaxStyles['italic']!;
    }
    // Inline code
    else if (match.group(4) != null) {
      return _syntaxStyles['code']!;
    }
    // Code blocks
    else if (match.group(5) != null) {
      return _syntaxStyles['codeBlock']!;
    }
    // Links
    else if (match.group(6) != null) {
      return _syntaxStyles['link']!;
    }
    // Images
    else if (match.group(7) != null) {
      return _syntaxStyles['image']!;
    }
    // Unordered lists
    else if (match.group(8) != null) {
      return _syntaxStyles['list']!;
    }
    // Ordered lists
    else if (match.group(9) != null) {
      return _syntaxStyles['list']!;
    }
    // Blockquotes
    else if (match.group(10) != null) {
      return _syntaxStyles['blockquote']!;
    }
    // Horizontal rules
    else if (match.group(11) != null) {
      return _syntaxStyles['rule']!;
    }
    // Strikethrough
    else if (match.group(12) != null) {
      return _syntaxStyles['strikethrough']!;
    }
    
    return baseStyle;
  }

  void updateTheme(ThemeData theme) {
    _syntaxStyles.clear();
    _syntaxStyles.addAll(_createSyntaxStyles(theme));
  }
}