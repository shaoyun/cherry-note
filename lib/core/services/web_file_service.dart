import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/web_platform_service.dart';

/// Web-specific file operations service
class WebFileService {
  
  /// Pick and read a file from the user's device
  static Future<WebFileResult?> pickFile({
    List<String>? allowedExtensions,
    String? mimeType,
  }) async {
    if (!kIsWeb) return null;
    
    try {
      final input = html.FileUploadInputElement();
      
      // Set accepted file types
      if (allowedExtensions != null) {
        input.accept = allowedExtensions.map((ext) => '.$ext').join(',');
      } else if (mimeType != null) {
        input.accept = mimeType;
      }
      
      input.click();
      
      await input.onChange.first;
      
      if (input.files?.isNotEmpty == true) {
        final file = input.files!.first;
        final reader = html.FileReader();
        
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        
        final bytes = reader.result as List<int>;
        
        return WebFileResult(
          name: file.name,
          bytes: Uint8List.fromList(bytes),
          size: file.size,
          mimeType: file.type,
        );
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
    
    return null;
  }

  /// Pick multiple files from the user's device
  static Future<List<WebFileResult>> pickMultipleFiles({
    List<String>? allowedExtensions,
    String? mimeType,
  }) async {
    if (!kIsWeb) return [];
    
    try {
      final input = html.FileUploadInputElement();
      input.multiple = true;
      
      // Set accepted file types
      if (allowedExtensions != null) {
        input.accept = allowedExtensions.map((ext) => '.$ext').join(',');
      } else if (mimeType != null) {
        input.accept = mimeType;
      }
      
      input.click();
      
      await input.onChange.first;
      
      final results = <WebFileResult>[];
      
      if (input.files?.isNotEmpty == true) {
        for (final file in input.files!) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoad.first;
          
          final bytes = reader.result as List<int>;
          
          results.add(WebFileResult(
            name: file.name,
            bytes: Uint8List.fromList(bytes),
            size: file.size,
            mimeType: file.type,
          ));
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Error picking multiple files: $e');
      return [];
    }
  }

  /// Download a file to the user's device
  static void downloadFile({
    required String filename,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
  }) {
    if (!kIsWeb) return;
    
    WebPlatformService.downloadFile(filename, bytes, mimeType);
  }

  /// Download text content as a file
  static void downloadTextFile({
    required String filename,
    required String content,
    String mimeType = 'text/plain',
  }) {
    if (!kIsWeb) return;
    
    final bytes = Uint8List.fromList(content.codeUnits);
    downloadFile(
      filename: filename,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  /// Download JSON content as a file
  static void downloadJsonFile({
    required String filename,
    required String jsonContent,
  }) {
    downloadTextFile(
      filename: filename,
      content: jsonContent,
      mimeType: 'application/json',
    );
  }

  /// Download Markdown content as a file
  static void downloadMarkdownFile({
    required String filename,
    required String markdownContent,
  }) {
    downloadTextFile(
      filename: filename,
      content: markdownContent,
      mimeType: 'text/markdown',
    );
  }

  /// Read text content from a file
  static Future<String?> readTextFile() async {
    final result = await pickFile(
      allowedExtensions: ['txt', 'md', 'json'],
      mimeType: 'text/*',
    );
    
    if (result != null) {
      return String.fromCharCodes(result.bytes);
    }
    
    return null;
  }

  /// Check if file operations are supported
  static bool get isSupported => kIsWeb && html.FileReader.supported;

  /// Get maximum file size supported (in bytes)
  static int get maxFileSize => 100 * 1024 * 1024; // 100MB

  /// Validate file size
  static bool isFileSizeValid(int size) {
    return size <= maxFileSize;
  }

  /// Get file extension from filename
  static String getFileExtension(String filename) {
    final lastDot = filename.lastIndexOf('.');
    if (lastDot == -1) return '';
    return filename.substring(lastDot + 1).toLowerCase();
  }

  /// Check if file type is supported for import
  static bool isSupportedImportType(String filename) {
    final extension = getFileExtension(filename);
    return ['md', 'txt', 'json', 'zip'].contains(extension);
  }

  /// Check if file type is image
  static bool isImageFile(String filename) {
    final extension = getFileExtension(filename);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(extension);
  }
}

/// Result of a web file operation
class WebFileResult {
  final String name;
  final Uint8List bytes;
  final int size;
  final String mimeType;

  const WebFileResult({
    required this.name,
    required this.bytes,
    required this.size,
    required this.mimeType,
  });

  /// Get file extension
  String get extension => WebFileService.getFileExtension(name);

  /// Check if file is an image
  bool get isImage => WebFileService.isImageFile(name);

  /// Get file content as string (for text files)
  String get textContent => String.fromCharCodes(bytes);

  /// Check if file size is valid
  bool get isValidSize => WebFileService.isFileSizeValid(size);

  @override
  String toString() {
    return 'WebFileResult(name: $name, size: $size, mimeType: $mimeType)';
  }
}