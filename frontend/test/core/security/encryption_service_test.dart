import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect_pro/core/security/encryption_service.dart';
import 'package:pointycastle/export.dart';

void main() {
  group('EncryptionService', () {
    test('derives the same AES key on both ECDH peers', () {
      final encryption = EncryptionService();
      final alice = encryption.generateKeyPair();
      final bob = encryption.generateKeyPair();

      final aliceKey = encryption.deriveAes256Key(
        alice.privateKey,
        bob.publicKey,
      );
      final bobKey = encryption.deriveAes256Key(
        bob.privateKey,
        alice.publicKey,
      );

      expect(base64Encode(aliceKey), base64Encode(bobKey));
      expect(aliceKey.length, 32);
    });

    test('encrypts and decrypts detached AES-GCM payloads', () {
      final encryption = EncryptionService();
      final alice = encryption.generateKeyPair();
      final bob = encryption.generateKeyPair();
      final key = encryption.deriveAes256Key(alice.privateKey, bob.publicKey);
      const plaintext = 'Message médical chiffré côté mobile';

      final encrypted = encryption.encryptDetached(plaintext, key);
      final decrypted = encryption.decryptDetached(
        ciphertextBase64: encrypted.ciphertext,
        nonceBase64: encrypted.nonce,
        key: key,
      );

      expect(decrypted, plaintext);
      expect(encrypted.ciphertext, isNot(contains(plaintext)));
      expect(base64Decode(encrypted.nonce).length, 12);
    });

    test('rejects tampered AES-GCM payloads', () {
      final encryption = EncryptionService();
      final alice = encryption.generateKeyPair();
      final bob = encryption.generateKeyPair();
      final key = encryption.deriveAes256Key(alice.privateKey, bob.publicKey);
      final encrypted = encryption.encryptDetached('secret', key);
      final bytes = base64Decode(encrypted.ciphertext);
      bytes[0] = bytes[0] ^ 1;

      expect(
        () => encryption.decryptDetached(
          ciphertextBase64: base64Encode(bytes),
          nonceBase64: encrypted.nonce,
          key: key,
        ),
        throwsA(isA<InvalidCipherTextException>()),
      );
    });
  });
}
