import 'date_utils.dart';
import 'string_utils.dart';
import '../constants/app_constants.dart';

class FilenameGenerator {
  /// Generate filename from title
  static String fromTitle(String title, {String extension = '.md'}) {
    if (title.isEmpty) {
      return 'untitled$extension';
    }
    
    // Sanitize title for filename
    String sanitized = title
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with hyphens
        .replaceAll(RegExp(r'-+'), '-') // Replace multiple hyphens with single
        .replaceAll(RegExp(r'^-|-$'), ''); // Remove leading/trailing hyphens
    
    if (sanitized.isEmpty) {
      sanitized = 'untitled';
    }
    
    // Limit length
    if (sanitized.length > 50) {
      sanitized = sanitized.substring(0, 50);
    }
    
    return '$sanitized$extension';
  }

  /// Generate filename with timestamp
  static String withTimestamp(String title, DateTime dateTime, {String extension = '.md'}) {
    final timestamp = AppDateUtils.formatForFileName(dateTime);
    final sanitizedTitle = _sanitizeForFilename(title);
    
    if (sanitizedTitle.isEmpty) {
      return '$timestamp$extension';
    }
    
    return '$timestamp-$sanitizedTitle$extension';
  }

  /// Generate filename for sticky note
  static String forStickyNote(String title, DateTime dateTime) {
    return withTimestamp(title, dateTime, extension: AppConstants.markdownExtension);
  }

  /// Generate filename for regular note
  static String forRegularNote(String title) {
    return fromTitle(title, extension: AppConstants.markdownExtension);
  }

  /// Generate unique filename if file already exists
  static String makeUnique(String baseFilename, List<String> existingFilenames) {
    if (!existingFilenames.contains(baseFilename)) {
      return baseFilename;
    }

    final lastDotIndex = baseFilename.lastIndexOf('.');
    final nameWithoutExt = lastDotIndex == -1 
        ? baseFilename 
        : baseFilename.substring(0, lastDotIndex);
    final extension = lastDotIndex == -1 
        ? '' 
        : baseFilename.substring(lastDotIndex);
    
    int counter = 1;
    String uniqueFilename;
    
    do {
      uniqueFilename = '${nameWithoutExt}_$counter$extension';
      counter++;
    } while (existingFilenames.contains(uniqueFilename));
    
    return uniqueFilename;
  }

  /// Generate filename from content (extract title from markdown)
  static String fromContent(String content, {String extension = '.md'}) {
    final title = StringUtils.extractTitleFromMarkdown(content);
    return fromTitle(title, extension: extension);
  }

  /// Generate filename for imported file
  static String forImportedFile(String originalFilename, DateTime importDate) {
    final nameWithoutExt = originalFilename.contains('.') 
        ? originalFilename.substring(0, originalFilename.lastIndexOf('.'))
        : originalFilename;
    final extension = originalFilename.contains('.') 
        ? originalFilename.substring(originalFilename.lastIndexOf('.'))
        : AppConstants.markdownExtension;
    
    final sanitizedName = _sanitizeForFilename(nameWithoutExt);
    final timestamp = AppDateUtils.formatForFileName(importDate);
    
    return 'imported-$timestamp-$sanitizedName$extension';
  }

  /// Generate filename for backup
  static String forBackup(String originalFilename, DateTime backupDate) {
    final nameWithoutExt = originalFilename.contains('.') 
        ? originalFilename.substring(0, originalFilename.lastIndexOf('.'))
        : originalFilename;
    final extension = originalFilename.contains('.') 
        ? originalFilename.substring(originalFilename.lastIndexOf('.'))
        : AppConstants.markdownExtension;
    
    final timestamp = AppDateUtils.formatForFileName(backupDate);
    
    return '${nameWithoutExt}_backup_$timestamp$extension';
  }

  /// Generate filename for template
  static String forTemplate(String templateName) {
    final sanitized = _sanitizeForFilename(templateName);
    return 'template_$sanitized${AppConstants.markdownExtension}';
  }

  /// Generate filename for daily note
  static String forDailyNote(DateTime date) {
    final dateStr = AppDateUtils.formatDate(date);
    return 'daily_$dateStr${AppConstants.markdownExtension}';
  }

  /// Generate filename for weekly note
  static String forWeeklyNote(DateTime date) {
    final year = date.year;
    final weekOfYear = _getWeekOfYear(date);
    return 'weekly_${year}_week_$weekOfYear${AppConstants.markdownExtension}';
  }

  /// Generate filename for monthly note
  static String forMonthlyNote(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    return 'monthly_${year}_$month${AppConstants.markdownExtension}';
  }

  /// Validate filename
  static bool isValidFilename(String filename) {
    if (filename.isEmpty || filename.length > AppConstants.maxFileNameLength) {
      return false;
    }
    
    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"/\\|?*\x00-\x1f]');
    if (invalidChars.hasMatch(filename)) {
      return false;
    }
    
    // Check for reserved names on Windows
    final reservedNames = [
      'CON', 'PRN', 'AUX', 'NUL',
      'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
      'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
    ];
    
    final nameWithoutExtension = filename.contains('.') 
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;
    
    if (reservedNames.contains(nameWithoutExtension.toUpperCase())) {
      return false;
    }
    
    return true;
  }

  /// Suggest alternative filename if current is invalid
  static String suggestValidFilename(String filename) {
    if (isValidFilename(filename)) {
      return filename;
    }
    
    // Sanitize the filename
    String sanitized = filename
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_')
        .trim();
    
    // Handle reserved names
    final reservedNames = [
      'CON', 'PRN', 'AUX', 'NUL',
      'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
      'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
    ];
    
    final nameWithoutExtension = sanitized.contains('.') 
        ? sanitized.substring(0, sanitized.lastIndexOf('.'))
        : sanitized;
    final extension = sanitized.contains('.') 
        ? sanitized.substring(sanitized.lastIndexOf('.'))
        : '';
    
    if (reservedNames.contains(nameWithoutExtension.toUpperCase())) {
      sanitized = '${nameWithoutExtension}_file$extension';
    }
    
    // Truncate if too long
    if (sanitized.length > AppConstants.maxFileNameLength) {
      final maxNameLength = AppConstants.maxFileNameLength - extension.length;
      final truncatedName = nameWithoutExtension.substring(0, maxNameLength);
      sanitized = '$truncatedName$extension';
    }
    
    // Ensure it's not empty
    if (sanitized.isEmpty || sanitized == extension) {
      sanitized = 'untitled${extension.isEmpty ? AppConstants.markdownExtension : extension}';
    }
    
    return sanitized;
  }

  /// Private helper to sanitize string for filename
  static String _sanitizeForFilename(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Private helper to get week of year
  static int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).floor() + 1;
  }
}