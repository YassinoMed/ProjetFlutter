import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class AesGcmEncryptedPayload {
  final String ciphertext;
  final String nonce;

  const AesGcmEncryptedPayload({
    required this.ciphertext,
    required this.nonce,
  });
}

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

  /// Derive a fixed AES-256 key from an ECDH shared secret.
  Uint8List deriveAes256Key(PrivateKey privateKey, PublicKey publicKey) {
    final sharedSecret = generateSharedSecret(privateKey, publicKey);
    return Uint8List.fromList(sha256.convert(sharedSecret).bytes);
  }

  String encodePublicKey(PublicKey publicKey) {
    final ecPublicKey = publicKey as ECPublicKey;
    return base64.encode(ecPublicKey.Q!.getEncoded(false));
  }

  String encodePrivateKey(PrivateKey privateKey) {
    final ecPrivateKey = privateKey as ECPrivateKey;
    return base64.encode(_bigIntToFixedLength(ecPrivateKey.d!, 32));
  }

  ECPrivateKey decodePrivateKey(String privateKeyBase64) {
    return ECPrivateKey(
      _bytesToBigInt(base64.decode(privateKeyBase64)),
      ECCurve_secp256r1(),
    );
  }

  ECPublicKey decodePublicKey(String publicKeyBase64) {
    final domain = ECCurve_secp256r1();
    final point = domain.curve.decodePoint(
      Uint8List.fromList(base64.decode(publicKeyBase64)),
    );

    if (point == null) {
      throw ArgumentError('Invalid E2EE public key');
    }

    return ECPublicKey(point, domain);
  }

  /// Encrypt message using AES-GCM
  String encrypt(String plaintext, Uint8List key) {
    final iv = _generateRandomBytes(12);
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    final input = utf8.encode(plaintext);
    final output = Uint8List(cipher.getOutputSize(input.length));
    var len = cipher.processBytes(input, 0, input.length, output, 0);
    len += cipher.doFinal(output, len);

    // Combine IV + Ciphertext and encode to Base64
    final encrypted = output.sublist(0, len);
    final result = Uint8List(iv.length + encrypted.length);
    result.setAll(0, iv);
    result.setAll(iv.length, encrypted);
    return base64.encode(result);
  }

  /// Encrypt message using AES-GCM with detached nonce.
  AesGcmEncryptedPayload encryptDetached(String plaintext, Uint8List key) {
    final nonce = _generateRandomBytes(12);
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      true,
      AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)),
    );

    final input = Uint8List.fromList(utf8.encode(plaintext));
    final output = Uint8List(cipher.getOutputSize(input.length));
    var len = cipher.processBytes(input, 0, input.length, output, 0);
    len += cipher.doFinal(output, len);

    return AesGcmEncryptedPayload(
      ciphertext: base64.encode(output.sublist(0, len)),
      nonce: base64.encode(nonce),
    );
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
    var len = cipher.processBytes(ciphertext, 0, ciphertext.length, output, 0);
    len += cipher.doFinal(output, len);

    return utf8.decode(output.sublist(0, len));
  }

  /// Decrypt message using AES-GCM with detached nonce.
  String decryptDetached({
    required String ciphertextBase64,
    required String nonceBase64,
    required Uint8List key,
  }) {
    final nonce = Uint8List.fromList(base64.decode(nonceBase64));
    final ciphertext = Uint8List.fromList(base64.decode(ciphertextBase64));
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      false,
      AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)),
    );

    final output = Uint8List(cipher.getOutputSize(ciphertext.length));
    var len = cipher.processBytes(ciphertext, 0, ciphertext.length, output, 0);
    len += cipher.doFinal(output, len);

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

  Uint8List _bigIntToFixedLength(BigInt bigInt, int length) {
    final raw = _bigIntToUint8List(bigInt);
    if (raw.length == length) {
      return raw;
    }

    if (raw.length > length) {
      return raw.sublist(raw.length - length);
    }

    final padded = Uint8List(length);
    padded.setAll(length - raw.length, raw);
    return padded;
  }

  BigInt _bytesToBigInt(List<int> bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }
}
