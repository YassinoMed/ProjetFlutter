/// E2EE Biometric Gate
///
/// Verrouillage applicatif de la clé privée E2EE locale derrière une
/// authentification biométrique (empreinte / Face ID).
///
/// Modèle:
///   - La clé privée vit déjà dans le Keystore Android / Keychain iOS via
///     flutter_secure_storage (encryptedSharedPreferences sur Android).
///   - Cette gate ajoute une vérification biométrique APPLICATIVE: la première
///     opération crypto de la session déclenche une invite biométrique. Si
///     l'utilisateur valide, la gate reste « unlocked » pendant le TTL.
///
/// Compromis: pour une protection au niveau hardware (Keystore avec
/// setUserAuthenticationRequired), il faudrait du code natif Android/iOS.
/// La gate applicative est suffisante tant que l'attaquant n'a pas root.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:mediconnect_pro/core/security/biometric_service.dart';
import 'package:mediconnect_pro/features/auth/presentation/providers/auth_provider.dart';

class E2eeBiometricGate {
  E2eeBiometricGate({
    required this.biometricService,
    this.sessionTtl = const Duration(minutes: 15),
  });

  final BiometricService biometricService;
  final Duration sessionTtl;
  final Logger _logger = Logger();

  DateTime? _unlockedAt;
  Future<bool>? _inFlight;
  bool _enabled = false;

  /// Active la gate. Tant que `enabled == false`, [unlock] est un no-op qui
  /// retourne `true`. Permet de basculer en/hors mode biométrique selon les
  /// préférences utilisateur sans modifier les appels crypto.
  void setEnabled(bool value) {
    _enabled = value;
    if (!value) {
      _unlockedAt = null;
    }
  }

  bool get isEnabled => _enabled;

  bool get _isUnlocked {
    if (_unlockedAt == null) return false;
    return DateTime.now().difference(_unlockedAt!) < sessionTtl;
  }

  /// Verrouille immédiatement (à appeler sur logout / passage en arrière-plan
  /// prolongé / changement d'utilisateur).
  void lock() {
    _unlockedAt = null;
  }

  /// Déverrouille via biométrie si nécessaire. Retourne `true` si l'opération
  /// crypto peut se poursuivre, `false` sinon. Plusieurs appels concurrents
  /// déclenchent une seule invite système (déduplication).
  Future<bool> unlock({
    String reason = 'Confirmez votre empreinte pour déchiffrer vos messages',
  }) async {
    if (!_enabled || _isUnlocked) {
      return true;
    }

    if (_inFlight != null) {
      return _inFlight!;
    }

    final future = _runAuthenticate(reason);
    _inFlight = future;
    try {
      return await future;
    } finally {
      _inFlight = null;
    }
  }

  Future<bool> _runAuthenticate(String reason) async {
    try {
      final available = await biometricService.isAvailable();
      if (!available) {
        // Pas de biométrie sur l'appareil → fallback transparent
        _logger.i('E2EE biometric gate: hardware unavailable, bypassing');
        return true;
      }

      final ok = await biometricService.authenticate(reason: reason);
      if (ok) {
        _unlockedAt = DateTime.now();
      }
      return ok;
    } on BiometricException catch (e) {
      _logger.w('E2EE biometric gate: ${e.message}');
      // On laisse l'utilisateur lire/écrire si la biométrie échoue côté
      // hardware (lock-out, capteur HS), sinon l'app deviendrait inutilisable.
      return true;
    } catch (e, st) {
      _logger.e('E2EE biometric gate failed', error: e, stackTrace: st);
      return true;
    }
  }
}

final e2eeBiometricGateProvider = Provider<E2eeBiometricGate>((ref) {
  final biometric = ref.watch(biometricServiceProvider);
  final gate = E2eeBiometricGate(biometricService: biometric);

  // Synchronise la gate sur la préférence biométrique de l'utilisateur:
  // si l'utilisateur a activé la connexion par empreinte, on protège aussi
  // l'accès à la clé privée E2EE.
  ref.listen<bool>(
    isBiometricEnabledProvider,
    (_, enabled) {
      gate.setEnabled(enabled);
      if (!enabled) {
        gate.lock();
      }
    },
    fireImmediately: true,
  );

  return gate;
});
