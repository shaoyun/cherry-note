class StringUtils {
  /// Check if string is null or empty
  static bool isNullOrEmpty(String? value) {
    return value == null || value.isEmpty;
  }
  
  /// Check if string is null, empty, or only whitespace
  static bool isNullOrWhitespace(String? value) {
    return value == null || value.trim().isEmpty;
  }
  
  /// Truncate string to specified length with ellipsis
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - ellipsis.length) + ellipsis;
  }
  
  /// Capitalize first letter of string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  /// Convert string to title case
  static String toTitleCase(String text) {
    return text.split(' ').map((word) => capitalize(word.toLowerCase())).join(' ');
  }
  
  /// Remove extra whitespace and normalize line endings
  static String normalizeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  
  /// Extract title from markdown content
  static String extractTitleFromMarkdown(String content) {
    final lines = content.split('\n');
    
    // Look for first H1 heading
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        return trimmed.substring(2).trim();
      }
    }
    
    // Look for first non-empty line
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && !trimmed.startsWith('---')) {
        return truncate(trimmed, 50);
      }
    }
    
    return 'Untitled';
  }
  
  /// Generate slug from title
  static String generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with hyphens
        .replaceAll(RegExp(r'-+'), '-') // Replace multiple hyphens with single
        .replaceAll(RegExp(r'^-|-$'), ''); // Remove leading/trailing hyphens
  }
  
  /// Count words in text
  static int countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
  
  /// Count characters in text (excluding whitespace)
  static int countCharacters(String text) {
    return text.replaceAll(RegExp(r'\s'), '').length;
  }
  
  /// Escape special characters for regex
  static String escapeRegex(String text) {
    return text.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (match) => '\\${match.group(0)}');
  }
  
  /// Check if text contains any of the search terms
  static bool containsAny(String text, List<String> searchTerms, {bool caseSensitive = false}) {
    final searchText = caseSensitive ? text : text.toLowerCase();
    
    for (final term in searchTerms) {
      final searchTerm = caseSensitive ? term : term.toLowerCase();
      if (searchText.contains(searchTerm)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Check if text contains all of the search terms
  static bool containsAll(String text, List<String> searchTerms, {bool caseSensitive = false}) {
    final searchText = caseSensitive ? text : text.toLowerCase();
    
    for (final term in searchTerms) {
      final searchTerm = caseSensitive ? term : term.toLowerCase();
      if (!searchText.contains(searchTerm)) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Highlight search terms in text
  static String highlightSearchTerms(String text, List<String> searchTerms, {bool caseSensitive = false}) {
    String result = text;
    
    for (final term in searchTerms) {
      final pattern = caseSensitive ? term : '(?i)${escapeRegex(term)}';
      result = result.replaceAllMapped(RegExp(pattern), (match) => '**${match.group(0)}**');
    }
    
    return result;
  }
}