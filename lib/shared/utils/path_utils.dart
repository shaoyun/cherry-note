import 'package:path/path.dart' as path;
import '../constants/app_constants.dart';

class PathUtils {
  /// Convert absolute path to relative path
  static String toRelativePath(String absolutePath, String basePath) {
    return path.relative(absolutePath, from: basePath);
  }

  /// Convert relative path to absolute path
  static String toAbsolutePath(String relativePath, String basePath) {
    return path.join(basePath, relativePath);
  }

  /// Normalize path separators for current platform
  static String normalizePath(String filePath) {
    return path.normalize(filePath);
  }

  /// Join path components
  static String joinPath(List<String> components) {
    return path.joinAll(components);
  }

  /// Get parent directory path
  static String getParentDirectory(String filePath) {
    return path.dirname(filePath);
  }

  /// Get file name with extension
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// Get file name without extension
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// Get file extension
  static String getExtension(String filePath) {
    return path.extension(filePath);
  }

  /// Check if path is absolute
  static bool isAbsolute(String filePath) {
    return path.isAbsolute(filePath);
  }

  /// Check if path is relative
  static bool isRelative(String filePath) {
    return path.isRelative(filePath);
  }

  /// Split path into components
  static List<String> splitPath(String filePath) {
    return path.split(filePath);
  }

  /// Get path depth (number of directory levels)
  static int getPathDepth(String filePath) {
    if (filePath.isEmpty || filePath == '/' || filePath == '.') return 0;
    return path.split(path.normalize(filePath))
        .where((component) => component.isNotEmpty && component != '.')
        .length;
  }

  /// Check if one path is ancestor of another
  static bool isAncestorOf(String ancestorPath, String descendantPath) {
    final normalizedAncestor = path.normalize(ancestorPath);
    final normalizedDescendant = path.normalize(descendantPath);
    
    if (normalizedAncestor == normalizedDescendant) return false;
    
    return path.isWithin(normalizedAncestor, normalizedDescendant);
  }

  /// Check if one path is descendant of another
  static bool isDescendantOf(String descendantPath, String ancestorPath) {
    return isAncestorOf(ancestorPath, descendantPath);
  }

  /// Get common ancestor path of multiple paths
  static String? getCommonAncestor(List<String> paths) {
    if (paths.isEmpty) return null;
    if (paths.length == 1) return getParentDirectory(paths.first);

    final normalizedPaths = paths.map((p) => path.normalize(p)).toList();
    final splitPaths = normalizedPaths.map((p) => path.split(p)).toList();
    
    final minLength = splitPaths.map((p) => p.length).reduce((a, b) => a < b ? a : b);
    final commonComponents = <String>[];
    
    for (int i = 0; i < minLength; i++) {
      final component = splitPaths.first[i];
      if (splitPaths.every((p) => p[i] == component)) {
        commonComponents.add(component);
      } else {
        break;
      }
    }
    
    return commonComponents.isEmpty ? null : path.joinAll(commonComponents);
  }

  /// Convert path to URL-safe format
  static String toUrlSafe(String filePath) {
    return filePath.replaceAll('\\', '/');
  }

  /// Convert URL-safe path to platform path
  static String fromUrlSafe(String urlPath) {
    return path.normalize(urlPath);
  }

  /// Generate unique path if path already exists
  static String generateUniquePath(String basePath, List<String> existingPaths) {
    if (!existingPaths.contains(basePath)) {
      return basePath;
    }

    final directory = getParentDirectory(basePath);
    final nameWithoutExt = getFileNameWithoutExtension(basePath);
    final extension = getExtension(basePath);
    
    int counter = 1;
    String uniquePath;
    
    do {
      final uniqueName = '${nameWithoutExt}_$counter$extension';
      uniquePath = directory == '.' ? uniqueName : path.join(directory, uniqueName);
      counter++;
    } while (existingPaths.contains(uniquePath));
    
    return uniquePath;
  }

  /// Check if path represents a markdown file
  static bool isMarkdownFile(String filePath) {
    return getExtension(filePath).toLowerCase() == AppConstants.markdownExtension;
  }

  /// Check if path represents a metadata file
  static bool isMetadataFile(String filePath) {
    final fileName = getFileName(filePath);
    return fileName.startsWith('.') && 
           getExtension(filePath).toLowerCase() == AppConstants.metadataExtension;
  }

  /// Check if path represents a hidden file
  static bool isHiddenFile(String filePath) {
    return getFileName(filePath).startsWith('.');
  }

  /// Get relative path from one path to another
  static String getRelativePathBetween(String fromPath, String toPath) {
    return path.relative(toPath, from: fromPath);
  }

  /// Resolve path with potential '..' and '.' components
  static String resolvePath(String filePath) {
    return path.canonicalize(filePath);
  }

  /// Check if path contains invalid characters
  static bool hasInvalidCharacters(String filePath) {
    // Common invalid characters across platforms
    final invalidChars = RegExp(r'[<>:"|?*\x00-\x1f]');
    return invalidChars.hasMatch(filePath);
  }

  /// Sanitize path by removing invalid characters
  static String sanitizePath(String filePath) {
    // Replace invalid characters with underscores
    return filePath.replaceAll(RegExp(r'[<>:"|?*\x00-\x1f]'), '_');
  }

  /// Get all parent paths of a given path
  static List<String> getAllParentPaths(String filePath) {
    final parents = <String>[];
    String currentPath = getParentDirectory(filePath);
    
    while (currentPath != '.' && currentPath != '/' && currentPath.isNotEmpty) {
      parents.add(currentPath);
      final nextParent = getParentDirectory(currentPath);
      if (nextParent == currentPath) break; // Prevent infinite loop
      currentPath = nextParent;
    }
    
    return parents;
  }

  /// Build path from components, handling empty components
  static String buildPath(List<String> components) {
    final filteredComponents = components
        .where((component) => component.isNotEmpty)
        .toList();
    return path.joinAll(filteredComponents);
  }

  /// Check if path is within a given directory
  static bool isWithinDirectory(String filePath, String directoryPath) {
    final normalizedFile = path.normalize(filePath);
    final normalizedDir = path.normalize(directoryPath);
    return path.isWithin(normalizedDir, normalizedFile);
  }

  /// Get the root component of a path
  static String getRootComponent(String filePath) {
    final components = path.split(path.normalize(filePath));
    return components.isNotEmpty ? components.first : '';
  }

  /// Convert Windows path to Unix path
  static String toUnixPath(String windowsPath) {
    return windowsPath.replaceAll('\\', '/');
  }

  /// Convert Unix path to Windows path
  static String toWindowsPath(String unixPath) {
    return unixPath.replaceAll('/', '\\');
  }
}