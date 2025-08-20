import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _fileNameFormat = DateFormat('yyyy-MM-dd-HHmmss');
  
  /// Format DateTime to string for display
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }
  
  /// Format DateTime to date only string
  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }
  
  /// Format DateTime to time only string
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }
  
  /// Format DateTime for file names (no spaces or colons)
  static String formatForFileName(DateTime dateTime) {
    return _fileNameFormat.format(dateTime);
  }
  
  /// Parse ISO 8601 string to DateTime
  static DateTime? parseIsoString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      return DateTime.parse(isoString);
    } catch (e) {
      return null;
    }
  }
  
  /// Convert DateTime to ISO 8601 string
  static String toIsoString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }
  
  /// Get relative time string (e.g., "2 hours ago", "yesterday")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分钟前';
    } else {
      return '刚刚';
    }
  }
  
  /// Check if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  /// Get start of day
  static DateTime startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
  
  /// Get end of day
  static DateTime endOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 999);
  }
}