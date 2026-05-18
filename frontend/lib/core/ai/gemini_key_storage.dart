/// Stockage local de la clé API Gemini.
///
/// Sources de la clé, par ordre de priorité :
///   1. SharedPreferences (saisie utilisateur via Settings)
///   2. `--dart-define=GEMINI_API_KEY=...` (build-time)
///
/// Comme ça l'utilisateur peut configurer la clé une fois depuis l'UI sans
/// devoir relancer `flutter run` avec `--dart-define` à chaque session.
///
/// ⚠️ Sur Flutter Web la valeur est stockée dans `localStorage` qui n'est
/// pas chiffré. Pour un déploiement réel, préférer un relay backend.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiKeyStorage {
  static const String _prefsKey = 'gemini_api_key';
  static const String _buildTimeKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  String? _cached;

  /// Charge la clé depuis SharedPreferences (premier appel) ou retourne
  /// la valeur en cache.
  Future<String> getApiKey() async {
    if (_cached != null && _cached!.isNotEmpty) return _cached!;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey)?.trim();
    if (stored != null && stored.isNotEmpty) {
      _cached = stored;
      return stored;
    }

    if (_buildTimeKey.isNotEmpty) {
      _cached = _buildTimeKey;
      return _buildTimeKey;
    }

    return '';
  }

  /// Persiste la clé saisie par l'utilisateur depuis l'UI.
  Future<void> setApiKey(String key) async {
    final trimmed = key.trim();
    final prefs = await SharedPreferences.getInstance();
    if (trimmed.isEmpty) {
      await prefs.remove(_prefsKey);
      _cached = null;
      return;
    }
    await prefs.setString(_prefsKey, trimmed);
    _cached = trimmed;
  }

  /// Synchronous version: returns the cached key without I/O.
  /// Returns empty string if never loaded.
  String getCachedKey() => _cached ?? '';

  /// True if a key is currently set (either cached or via --dart-define).
  Future<bool> hasKey() async {
    final k = await getApiKey();
    return k.isNotEmpty;
  }
}

final geminiKeyStorageProvider = Provider<GeminiKeyStorage>((ref) {
  return GeminiKeyStorage();
});
