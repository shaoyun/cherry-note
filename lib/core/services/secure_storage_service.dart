import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for securely storing sensitive data
abstract class SecureStorageService {
  Future<void> store(String key, String value);
  Future<String?> retrieve(String key);
  Future<void> delete(String key);
  Future<void> clear();
  Future<bool> containsKey(String key);
}

/// Simple implementation of SecureStorageService using file-based encryption
/// Note: In production, consider using flutter_secure_storage or similar
@LazySingleton(as: SecureStorageService)
class SecureStorageServiceImpl implements SecureStorageService {
  static const String _storageFileName = 'secure_storage.dat';
  static const String _defaultPassword = 'cherry_note_secure_key_2024';
  
  File? _storageFile;
  Map<String, String>? _cache;

  Future<File> get storageFile async {
    if (_storageFile != null) return _storageFile!;
    
    final appDir = await getApplicationSupportDirectory();
    _storageFile = File(path.join(appDir.path, _storageFileName));
    return _storageFile!;
  }

  Future<Map<String, String>> _loadData() async {
    if (_cache != null) return _cache!;
    
    final file = await storageFile;
    if (!await file.exists()) {
      _cache = <String, String>{};
      return _cache!;
    }

    try {
      final encryptedData = await file.readAsString();
      if (encryptedData.isEmpty) {
        _cache = <String, String>{};
        return _cache!;
      }

      final decryptedData = _decrypt(encryptedData);
      final jsonData = json.decode(decryptedData) as Map<String, dynamic>;
      _cache = jsonData.cast<String, String>();
      return _cache!;
    } catch (e) {
      // If decryption fails, start with empty data
      _cache = <String, String>{};
      return _cache!;
    }
  }

  Future<void> _saveData() async {
    if (_cache == null) return;
    
    final file = await storageFile;
    final jsonData = json.encode(_cache);
    final encryptedData = _encrypt(jsonData);
    await file.writeAsString(encryptedData);
  }

  String _encrypt(String data) {
    // Simple XOR encryption with key derivation
    // Note: This is basic encryption. For production use, consider AES or similar
    final key = _deriveKey(_defaultPassword);
    final dataBytes = utf8.encode(data);
    final encryptedBytes = <int>[];
    
    for (int i = 0; i < dataBytes.length; i++) {
      encryptedBytes.add(dataBytes[i] ^ key[i % key.length]);
    }
    
    return base64.encode(encryptedBytes);
  }

  String _decrypt(String encryptedData) {
    final key = _deriveKey(_defaultPassword);
    final encryptedBytes = base64.decode(encryptedData);
    final decryptedBytes = <int>[];
    
    for (int i = 0; i < encryptedBytes.length; i++) {
      decryptedBytes.add(encryptedBytes[i] ^ key[i % key.length]);
    }
    
    return utf8.decode(decryptedBytes);
  }

  List<int> _deriveKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.bytes;
  }

  @override
  Future<void> store(String key, String value) async {
    final data = await _loadData();
    data[key] = value;
    await _saveData();
  }

  @override
  Future<String?> retrieve(String key) async {
    final data = await _loadData();
    return data[key];
  }

  @override
  Future<void> delete(String key) async {
    final data = await _loadData();
    data.remove(key);
    await _saveData();
  }

  @override
  Future<void> clear() async {
    _cache = <String, String>{};
    await _saveData();
  }

  @override
  Future<bool> containsKey(String key) async {
    final data = await _loadData();
    return data.containsKey(key);
  }
}