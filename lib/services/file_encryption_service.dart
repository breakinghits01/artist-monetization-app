import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for encrypting and decrypting files
/// Uses AES-256 encryption for maximum security
class FileEncryptionService {
  final FlutterSecureStorage _secureStorage;
  static const String _keyStorageKey = 'file_encryption_key';
  static const String _ivStorageKey = 'file_encryption_iv';

  FileEncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Get or generate encryption key
  Future<encrypt_lib.Key> _getEncryptionKey() async {
    try {
      // Try to get existing key
      final storedKey = await _secureStorage.read(key: _keyStorageKey);
      
      if (storedKey != null) {
        return encrypt_lib.Key.fromBase64(storedKey);
      }

      // Generate new key if not exists
      final key = encrypt_lib.Key.fromSecureRandom(32); // 256-bit key
      await _secureStorage.write(key: _keyStorageKey, value: key.base64);
      
      debugPrint('🔐 Generated new encryption key');
      return key;
    } catch (e) {
      // Log detailed error for Android Keystore issues (Error -30 = KEY_PERMANENTLY_INVALIDATED)
      if (e.toString().contains('ErrorCode(-30)') || e.toString().contains('KEY_PERMANENTLY_INVALIDATED')) {
        debugPrint('❌ CRITICAL: Android Keystore access denied (app backgrounded?)');
        debugPrint('💡 Encryption keys should be accessed only while app is in foreground');
      }
      debugPrint('❌ Error getting encryption key: $e');
      rethrow;
    }
  }

  /// Get or generate IV (Initialization Vector)
  Future<encrypt_lib.IV> _getIV() async {
    try {
      // Try to get existing IV
      final storedIV = await _secureStorage.read(key: _ivStorageKey);
      
      if (storedIV != null) {
        return encrypt_lib.IV.fromBase64(storedIV);
      }

      // Generate new IV if not exists
      final iv = encrypt_lib.IV.fromSecureRandom(16); // 128-bit IV
      await _secureStorage.write(key: _ivStorageKey, value: iv.base64);
      
      debugPrint('🔐 Generated new IV');
      return iv;
    } catch (e) {
      // Log detailed error for Android Keystore issues
      if (e.toString().contains('ErrorCode(-30)') || e.toString().contains('KEY_PERMANENTLY_INVALIDATED')) {
        debugPrint('❌ CRITICAL: Android Keystore access denied (app backgrounded?)');
        debugPrint('💡 IV should be accessed only while app is in foreground');
      }
      debugPrint('❌ Error getting IV: $e');
      rethrow;
    }
  }

  /// Encrypt a file
  /// @param inputFile The file to encrypt
  /// @param outputFile Where to save the encrypted file
  Future<bool> encryptFile(File inputFile, File outputFile) async {
    try {
      debugPrint('🔒 Encrypting file: ${inputFile.path}');
      
      // Read file bytes
      final fileBytes = await inputFile.readAsBytes();
      debugPrint('📦 File size: ${fileBytes.length} bytes');

      // Get encryption key and IV
      final key = await _getEncryptionKey();
      final iv = await _getIV();

      // Create encrypter
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc),
      );

      // Encrypt data
      final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);
      
      // Write encrypted data to output file
      await outputFile.writeAsBytes(encrypted.bytes);
      
      debugPrint('✅ File encrypted successfully: ${outputFile.path}');
      debugPrint('🔐 Encrypted size: ${encrypted.bytes.length} bytes');
      
      return true;
    } catch (e) {
      debugPrint('❌ Error encrypting file: $e');
      return false;
    }
  }

  /// Decrypt a file
  /// @param inputFile The encrypted file
  /// @param outputFile Where to save the decrypted file
  Future<bool> decryptFile(File inputFile, File outputFile) async {
    try {
      debugPrint('🔓 Decrypting file: ${inputFile.path}');
      
      // Read encrypted bytes
      final encryptedBytes = await inputFile.readAsBytes();
      debugPrint('📦 Encrypted size: ${encryptedBytes.length} bytes');

      // Get encryption key and IV
      final key = await _getEncryptionKey();
      final iv = await _getIV();

      // Create encrypter
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc),
      );

      // Decrypt data
      final encrypted = encrypt_lib.Encrypted(encryptedBytes);
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
      
      // Write decrypted data to output file
      await outputFile.writeAsBytes(decrypted);
      
      debugPrint('✅ File decrypted successfully: ${outputFile.path}');
      debugPrint('📦 Decrypted size: ${decrypted.length} bytes');
      
      return true;
    } catch (e) {
      debugPrint('❌ Error decrypting file: $e');
      return false;
    }
  }

  // ─── Per-song IV API ────────────────────────────────────────────────────────
  // Each song gets its own randomly-generated IV at download time.
  // This means:
  //   • A Keystore invalidation for one song does NOT affect others.
  //   • Identical audio files produce different ciphertext (no pattern leakage).
  //   • Legacy songs (no 'iv' in metadata) fall back to the global IV via the
  //     original decryptFile() above.

  /// Generate a cryptographically-secure random IV for one song.
  /// Call once at download time and persist the result in song metadata.
  static String generateSongIV() => encrypt_lib.IV.fromSecureRandom(16).base64;

  /// Encrypt [inputFile] using the caller-supplied [ivBase64] (per-song IV).
  /// [ivBase64] must be the value previously returned by [generateSongIV].
  Future<bool> encryptFileWithIV(
    File inputFile,
    File outputFile,
    String ivBase64,
  ) async {
    try {
      final fileBytes = await inputFile.readAsBytes();
      final key = await _getEncryptionKey();
      final iv = encrypt_lib.IV.fromBase64(ivBase64);
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc),
      );
      final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);
      await outputFile.writeAsBytes(encrypted.bytes);
      debugPrint('✅ File encrypted with per-song IV: ${outputFile.path}');
      return true;
    } catch (e) {
      debugPrint('❌ Error encrypting file with per-song IV: $e');
      return false;
    }
  }

  /// Decrypt [inputFile] using the per-song [ivBase64] that was stored in
  /// metadata at download time.  For files downloaded before per-song IVs
  /// were introduced, call [decryptFile] instead (uses the global IV).
  Future<bool> decryptFileWithIV(
    File inputFile,
    File outputFile,
    String ivBase64,
  ) async {
    try {
      final encryptedBytes = await inputFile.readAsBytes();
      final key = await _getEncryptionKey();
      final iv = encrypt_lib.IV.fromBase64(ivBase64);
      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc),
      );
      final encrypted = encrypt_lib.Encrypted(encryptedBytes);
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
      await outputFile.writeAsBytes(decrypted);
      debugPrint('✅ File decrypted with per-song IV: ${outputFile.path}');
      return true;
    } catch (e) {
      debugPrint('❌ Error decrypting file with per-song IV: $e');
      return false;
    }
  }

  /// Encrypt bytes in memory (for smaller files)
  Future<Uint8List?> encryptBytes(Uint8List data) async {
    try {
      final key = await _getEncryptionKey();
      final iv = await _getIV();

      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc),
      );

      final encrypted = encrypter.encryptBytes(data, iv: iv);
      return encrypted.bytes;
    } catch (e) {
      debugPrint('❌ Error encrypting bytes: $e');
      return null;
    }
  }

  /// Decrypt bytes in memory (for smaller files)
  Future<Uint8List?> decryptBytes(Uint8List encryptedData) async {
    try {
      final key = await _getEncryptionKey();
      final iv = await _getIV();

      final encrypter = encrypt_lib.Encrypter(
        encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc),
      );

      final encrypted = encrypt_lib.Encrypted(encryptedData);
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
      
      return Uint8List.fromList(decrypted);
    } catch (e) {
      debugPrint('❌ Error decrypting bytes: $e');
      return null;
    }
  }

  /// Clear encryption keys (use when user logs out)
  Future<void> clearKeys() async {
    try {
      await _secureStorage.delete(key: _keyStorageKey);
      await _secureStorage.delete(key: _ivStorageKey);
      debugPrint('🗑️ Encryption keys cleared');
    } catch (e) {
      debugPrint('❌ Error clearing keys: $e');
    }
  }

  /// Check if encryption keys exist
  Future<bool> hasKeys() async {
    final key = await _secureStorage.read(key: _keyStorageKey);
    final iv = await _secureStorage.read(key: _ivStorageKey);
    return key != null && iv != null;
  }
}
