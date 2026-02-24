import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  /// Generate a new ECDH Key Pair
  AsymmetricKeyPair<PublicKey, PrivateKey> generateKeyPair() {
    final keyParams = ECKeyGeneratorParameters(ECCurve_secp256r1());
    final generator = ECKeyGenerator();
    generator.init(ParametersWithRandom(keyParams, _getSecureRandom()));
    return generator.generateKeyPair();
  }

  /// Generate Shared Secret using ECDH
  Uint8List generateSharedSecret(PrivateKey privateKey, PublicKey publicKey) {
    final agreement = ECDHBasicAgreement();
    agreement.init(privateKey as ECPrivateKey);
    final secret = agreement.calculateAgreement(publicKey as ECPublicKey);
    return _bigIntToUint8List(secret);
  }

  /// Encrypt message using AES-GCM
  String encrypt(String plaintext, Uint8List key) {
    final iv = _generateRandomBytes(12);
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    final input = utf8.encode(plaintext);
    final output = Uint8List(cipher.getOutputSize(input.length));
    final len = cipher.processBytes(input, 0, input.length, output, 0);
    cipher.doFinal(output, len);

    // Combine IV + Ciphertext and encode to Base64
    final result = Uint8List(iv.length + output.length);
    result.setAll(0, iv);
    result.setAll(iv.length, output);
    return base64.encode(result);
  }

  /// Decrypt message using AES-GCM
  String decrypt(String ciphertextBase64, Uint8List key) {
    final data = base64.decode(ciphertextBase64);
    final iv = data.sublist(0, 12);
    final ciphertext = data.sublist(12);

    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
        false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    final output = Uint8List(cipher.getOutputSize(ciphertext.length));
    final len =
        cipher.processBytes(ciphertext, 0, ciphertext.length, output, 0);
    cipher.doFinal(output, len);

    return utf8.decode(output.sublist(0, len));
  }

  SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  Uint8List _generateRandomBytes(int length) {
    final rnd = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rnd.nextInt(256);
    }
    return bytes;
  }

  Uint8List _bigIntToUint8List(BigInt bigInt) {
    var hex = bigInt.toRadixString(16);
    if (hex.length % 2 != 0) hex = '0$hex';
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }
}
