import 'dart:io';
import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';

class FileUtils {
  /// Validate file name for cross-platform compatibility
  static bool isValidFileName(String fileName) {
    if (fileName.isEmpty || fileName.length > AppConstants.maxFileNameLength) {
      return false;
    }
    
    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(fileName)) {
      return false;
    }
    
    // Check for reserved names on Windows
    final reservedNames = [
      'CON', 'PRN', 'AUX', 'NUL',
      'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
      'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
    ];
    
    final nameWithoutExtension = path.basenameWithoutExtension(fileName).toUpperCase();
    if (reservedNames.contains(nameWithoutExtension)) {
      return false;
    }
    
    return true;
  }
  
  /// Sanitize file name by removing or replacing invalid characters
  static String sanitizeFileName(String fileName) {
    // Replace invalid characters with underscores
    String sanitized = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    
    // Trim whitespace and dots from the end
    sanitized = sanitized.trim().replaceAll(RegExp(r'[.\s]+$'), '');
    
    // Ensure it's not empty
    if (sanitized.isEmpty) {
      sanitized = 'untitled';
    }
    
    // Truncate if too long
    if (sanitized.length > AppConstants.maxFileNameLength) {
      final extension = path.extension(sanitized);
      final nameWithoutExt = path.basenameWithoutExtension(sanitized);
      final maxNameLength = AppConstants.maxFileNameLength - extension.length;
      sanitized = nameWithoutExt.substring(0, maxNameLength) + extension;
    }
    
    return sanitized;
  }
  
  /// Generate unique file name if file already exists
  static String generateUniqueFileName(String baseName, List<String> existingNames) {
    if (!existingNames.contains(baseName)) {
      return baseName;
    }
    
    final extension = path.extension(baseName);
    final nameWithoutExt = path.basenameWithoutExtension(baseName);
    
    int counter = 1;
    String uniqueName;
    
    do {
      uniqueName = '${nameWithoutExt}_$counter$extension';
      counter++;
    } while (existingNames.contains(uniqueName));
    
    return uniqueName;
  }
  
  /// Convert absolute path to relative path
  static String toRelativePath(String absolutePath, String basePath) {
    return path.relative(absolutePath, from: basePath);
  }
  
  /// Convert relative path to absolute path
  static String toAbsolutePath(String relativePath, String basePath) {
    return path.join(basePath, relativePath);
  }
  
  /// Get file extension
  static String getExtension(String filePath) {
    return path.extension(filePath);
  }
  
  /// Check if file is a markdown file
  static bool isMarkdownFile(String filePath) {
    return getExtension(filePath).toLowerCase() == AppConstants.markdownExtension;
  }
  
  /// Check if file is a metadata file
  static bool isMetadataFile(String filePath) {
    final fileName = path.basename(filePath);
    return fileName.startsWith('.') && getExtension(filePath).toLowerCase() == AppConstants.metadataExtension;
  }
  
  /// Get file size in bytes
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }
  
  /// Check if file size is within limits
  static Future<bool> isFileSizeValid(String filePath) async {
    final size = await getFileSize(filePath);
    return size <= AppConstants.maxFileSizeBytes;
  }
  
  /// Get parent directory path
  static String getParentDirectory(String filePath) {
    return path.dirname(filePath);
  }
  
  /// Join path components
  static String joinPath(List<String> components) {
    return path.joinAll(components);
  }
  
  /// Normalize path separators for current platform
  static String normalizePath(String filePath) {
    return path.normalize(filePath);
  }
}