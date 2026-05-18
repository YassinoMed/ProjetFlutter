/// Dialogue de saisie de la clé API Gemini.
///
/// Permet à l'utilisateur de configurer la clé depuis l'UI sans relancer
/// `flutter run` avec `--dart-define`. La valeur est persistée dans
/// SharedPreferences via [GeminiKeyStorage].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'gemini_key_storage.dart';

class GeminiKeySettingsDialog extends ConsumerStatefulWidget {
  const GeminiKeySettingsDialog({super.key});

  /// Ouvre le dialogue. Retourne `true` si la clé a été sauvegardée.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const GeminiKeySettingsDialog(),
    );
  }

  @override
  ConsumerState<GeminiKeySettingsDialog> createState() =>
      _GeminiKeySettingsDialogState();
}

class _GeminiKeySettingsDialogState
    extends ConsumerState<GeminiKeySettingsDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final current = await ref.read(geminiKeyStorageProvider).getApiKey();
    if (!mounted) return;
    if (current.isNotEmpty) {
      _controller.text = current;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final value = _controller.text.trim();
    // Validation basique : les clés Google API commencent par "AIza".
    if (value.isNotEmpty && !value.startsWith('AIza')) {
      setState(() {
        _saving = false;
        _error = 'Format invalide. Les clés Gemini commencent par "AIza".';
      });
      return;
    }
    try {
      await ref.read(geminiKeyStorageProvider).setApiKey(value);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Erreur lors de l\'enregistrement : $e';
      });
    }
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    try {
      await ref.read(geminiKeyStorageProvider).setApiKey('');
      if (!mounted) return;
      _controller.clear();
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Clé API Gemini')),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Obtenez votre clé gratuite sur aistudio.google.com/apikey '
              '(connexion avec compte Google). La clé est stockée '
              'uniquement sur cet appareil.',
              style:
                  AppTheme.bodySmall.copyWith(color: AppTheme.neutralGray500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'AIza…',
                hintText: 'Collez votre clé Gemini',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                errorText: _error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warningColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sur Web, la clé reste dans le navigateur (localStorage). '
                      'Pour la prod, restreignez-la dans Google Cloud Console '
                      '(referrer + API restriction).',
                      style: AppTheme.bodySmall
                          .copyWith(color: AppTheme.warningColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_controller.text.isNotEmpty)
          TextButton(
            onPressed: _saving ? null : _clear,
            child: const Text('Supprimer'),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
