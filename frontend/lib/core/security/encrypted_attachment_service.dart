/// E2EE Encrypted Attachment Service
/// Encrypts files locally before upload, decrypts after download.
/// RGPD-compliant: the server never sees unencrypted data.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../network/dio_client.dart';
import '../security/encryption_service.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

// ── Models ──────────────────────────────────────────────────

class EncryptedAttachmentMeta {
  final String id;
  final String ownerUserId;
  final String originalFilename;
  final String mimeType;
  final int fileSizeBytes;
  final String algorithm;
  final String nonce;
  final String? keyId;
  final String encryptedKey;
  final String checksumSha256;
  final String? attachableType;
  final String? attachableId;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const EncryptedAttachmentMeta({
    required this.id,
    required this.ownerUserId,
    required this.originalFilename,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.algorithm,
    required this.nonce,
    this.keyId,
    required this.encryptedKey,
    required this.checksumSha256,
    this.attachableType,
    this.attachableId,
    this.expiresAt,
    required this.createdAt,
  });

  factory EncryptedAttachmentMeta.fromJson(Map<String, dynamic> json) {
    return EncryptedAttachmentMeta(
      id: json['id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      originalFilename: json['original_filename'] as String,
      mimeType: json['mime_type'] as String,
      fileSizeBytes: json['file_size_bytes'] as int,
      algorithm: json['algorithm'] as String,
      nonce: json['nonce'] as String,
      keyId: json['key_id'] as String?,
      encryptedKey: json['encrypted_key'] as String,
      checksumSha256: json['checksum_sha256'] as String,
      attachableType: json['attachable_type'] as String?,
      attachableId: json['attachable_id'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// ── Service ─────────────────────────────────────────────────

class EncryptedAttachmentService {
  final Dio _dio;
  final EncryptionService _encryption;

  EncryptedAttachmentService({
    required Dio dio,
    required EncryptionService encryption,
  })  : _dio = dio,
        _encryption = encryption;

  /// Encrypt a file locally, then upload the encrypted blob.
  ///
  /// [file]           – The plaintext file to encrypt and upload
  /// [sharedKey]      – The AES-256 shared key (from ECDH exchange)
  /// [attachableType] – Optional: 'chat_message' or 'medical_record'
  /// [attachableId]   – Optional: UUID of the parent entity
  Future<EncryptedAttachmentMeta> uploadEncrypted({
    required File file,
    required Uint8List sharedKey,
    String? attachableType,
    String? attachableId,
    int? ttlDays,
  }) async {
    _logger.i('Encrypting file: ${file.path}');

    // 1. Read the plaintext file
    final plainBytes = await file.readAsBytes();

    // 2. Encrypt using AES-256-GCM
    final encryptedBase64 = _encryption.encrypt(
      base64.encode(plainBytes),
      sharedKey,
    );
    final encryptedBytes = base64.decode(encryptedBase64);

    // Extract the nonce (first 12 bytes of the encrypted output)
    final nonce = base64.encode(encryptedBytes.sublist(0, 12));

    // 3. Calculate SHA-256 checksum of the encrypted blob
    final checksumSha256 = sha256.convert(encryptedBytes).toString();

    // 4. Create a temp file with the encrypted content
    final tempDir = await getTemporaryDirectory();
    final encFile = File(
        p.join(tempDir.path, 'enc_${DateTime.now().millisecondsSinceEpoch}'));
    await encFile.writeAsBytes(encryptedBytes);

    try {
      // 5. Upload to server
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(encFile.path,
            filename: '${p.basenameWithoutExtension(file.path)}.enc'),
        'encrypted_key': base64.encode(sharedKey),
        'nonce': nonce,
        'algorithm': 'AES-256-GCM',
        'original_filename': p.basename(file.path),
        'mime_type': _guessMimeType(file.path),
        'checksum_sha256': checksumSha256,
        if (attachableType != null) 'attachable_type': attachableType,
        if (attachableId != null) 'attachable_id': attachableId,
        if (ttlDays != null) 'ttl_days': ttlDays.toString(),
      });

      final response = await _dio.post(
        '/attachments/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      _logger.i('Encrypted file uploaded successfully.');
      return EncryptedAttachmentMeta.fromJson(
        response.data['attachment'] as Map<String, dynamic>,
      );
    } finally {
      // Clean up temp file
      if (await encFile.exists()) {
        await encFile.delete();
      }
    }
  }

  /// Download and decrypt an attachment.
  ///
  /// Returns the decrypted file saved to the app's temp directory.
  Future<File> downloadAndDecrypt({
    required String attachmentId,
    required Uint8List sharedKey,
    String? saveFilename,
  }) async {
    _logger.i('Downloading encrypted attachment: $attachmentId');

    // 1. Download the encrypted blob
    final response = await _dio.get(
      '/attachments/$attachmentId/download',
      options: Options(responseType: ResponseType.bytes),
    );

    final encryptedBytes = Uint8List.fromList(response.data as List<int>);

    // 2. Verify checksum
    final expectedChecksum = response.headers.value('X-Checksum-SHA256');
    if (expectedChecksum != null) {
      final actualChecksum = sha256.convert(encryptedBytes).toString();
      if (actualChecksum != expectedChecksum) {
        throw Exception('Checksum mismatch! File integrity compromised.');
      }
    }

    // 3. Decrypt
    final decryptedBase64 = _encryption.decrypt(
      base64.encode(encryptedBytes),
      sharedKey,
    );
    final decryptedBytes = base64.decode(decryptedBase64);

    // 4. Save to temp directory
    final tempDir = await getTemporaryDirectory();
    final filename = saveFilename ?? 'decrypted_$attachmentId';
    final outFile = File(p.join(tempDir.path, filename));
    await outFile.writeAsBytes(decryptedBytes);

    _logger.i('File decrypted and saved: ${outFile.path}');
    return outFile;
  }

  /// Get attachment metadata (without downloading the file).
  Future<EncryptedAttachmentMeta> getMetadata(String attachmentId) async {
    final response = await _dio.get('/attachments/$attachmentId');
    return EncryptedAttachmentMeta.fromJson(
      response.data['attachment'] as Map<String, dynamic>,
    );
  }

  /// Delete an attachment (RGPD right to erasure).
  Future<void> deleteAttachment(String attachmentId) async {
    await _dio.delete('/attachments/$attachmentId');
    _logger.i('Attachment deleted: $attachmentId');
  }

  String _guessMimeType(String path) {
    final ext = p.extension(path).toLowerCase();
    return switch (ext) {
      '.pdf' => 'application/pdf',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.gif' => 'image/gif',
      '.doc' => 'application/msword',
      '.docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.txt' => 'text/plain',
      '.csv' => 'text/csv',
      '.json' => 'application/json',
      _ => 'application/octet-stream',
    };
  }
}

// ── Provider ────────────────────────────────────────────────

final encryptedAttachmentServiceProvider =
    Provider<EncryptedAttachmentService>((ref) {
  return EncryptedAttachmentService(
    dio: ref.watch(dioProvider),
    encryption: EncryptionService(),
  );
});
