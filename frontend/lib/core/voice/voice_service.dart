/// Voice Input/Output Service – On-device STT & TTS
/// Feature: Speech-to-text transcription + Text-to-speech playback
/// RGPD-friendly: everything runs on-device, no cloud API needed.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

// ── Voice State ─────────────────────────────────────────────
enum VoiceInputState { idle, listening, processing, error }

class VoiceInputResult {
  final String text;
  final double confidence;
  final bool isFinal;

  const VoiceInputResult({
    required this.text,
    this.confidence = 0.0,
    this.isFinal = false,
  });
}

// ── Voice Service ───────────────────────────────────────────
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  bool _sttInitialized = false;
  bool _ttsInitialized = false;
  bool _isListening = false;

  final StreamController<VoiceInputResult> _sttController =
      StreamController<VoiceInputResult>.broadcast();
  final StreamController<VoiceInputState> _stateController =
      StreamController<VoiceInputState>.broadcast();

  Stream<VoiceInputResult> get onResult => _sttController.stream;
  Stream<VoiceInputState> get onStateChange => _stateController.stream;
  bool get isListening => _isListening;

  // ── Initialization ──────────────────────────────────────

  /// Initialize the STT engine (on-device).
  Future<bool> initStt({String locale = 'fr_FR'}) async {
    if (_sttInitialized) return true;
    try {
      // NOTE: In production, integrate with speech_to_text package:
      //   final available = await _speechToText.initialize(
      //     onError: (e) => _stateController.add(VoiceInputState.error),
      //     onStatus: (s) => _logger.d('STT status: $s'),
      //   );
      _sttInitialized = true;
      _logger.i('STT engine initialized (locale: $locale)');
      return true;
    } catch (e) {
      _logger.e('STT initialization failed: $e');
      return false;
    }
  }

  /// Initialize the TTS engine (on-device).
  Future<bool> initTts({String locale = 'fr-FR'}) async {
    if (_ttsInitialized) return true;
    try {
      // NOTE: In production, integrate with flutter_tts package:
      //   await _flutterTts.setLanguage(locale);
      //   await _flutterTts.setSpeechRate(0.5);
      //   await _flutterTts.setVolume(1.0);
      //   await _flutterTts.setPitch(1.0);
      _ttsInitialized = true;
      _logger.i('TTS engine initialized (locale: $locale)');
      return true;
    } catch (e) {
      _logger.e('TTS initialization failed: $e');
      return false;
    }
  }

  // ── Speech-to-Text ──────────────────────────────────────

  /// Start listening for voice input.
  Future<void> startListening({String locale = 'fr_FR'}) async {
    if (_isListening) return;
    if (!_sttInitialized) await initStt(locale: locale);

    _isListening = true;
    _stateController.add(VoiceInputState.listening);

    try {
      // NOTE: Production integration:
      //   await _speechToText.listen(
      //     onResult: (result) {
      //       _sttController.add(VoiceInputResult(
      //         text: result.recognizedWords,
      //         confidence: result.confidence,
      //         isFinal: result.finalResult,
      //       ));
      //       if (result.finalResult) {
      //         _stateController.add(VoiceInputState.idle);
      //         _isListening = false;
      //       }
      //     },
      //     localeId: locale,
      //     listenMode: ListenMode.dictation,
      //     cancelOnError: true,
      //     listenFor: const Duration(minutes: 2),
      //   );

      // Simulated result for development
      await Future.delayed(const Duration(seconds: 2));
      _sttController.add(const VoiceInputResult(
        text: 'Bonjour docteur, j\'ai des douleurs depuis hier.',
        confidence: 0.95,
        isFinal: true,
      ));
      _isListening = false;
      _stateController.add(VoiceInputState.idle);
    } catch (e) {
      _isListening = false;
      _stateController.add(VoiceInputState.error);
      _logger.e('STT error: $e');
    }
  }

  /// Stop listening.
  Future<void> stopListening() async {
    if (!_isListening) return;
    // await _speechToText.stop();
    _isListening = false;
    _stateController.add(VoiceInputState.idle);
  }

  // ── Text-to-Speech ──────────────────────────────────────

  /// Read a message aloud.
  Future<void> speak(String text, {String locale = 'fr-FR'}) async {
    if (!_ttsInitialized) await initTts(locale: locale);
    try {
      // NOTE: Production integration:
      //   await _flutterTts.speak(text);
      _logger.d(
          'TTS speaking: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}');
    } catch (e) {
      _logger.e('TTS error: $e');
    }
  }

  /// Stop speaking.
  Future<void> stopSpeaking() async {
    // await _flutterTts.stop();
  }

  // ── Cleanup ─────────────────────────────────────────────

  void dispose() {
    _sttController.close();
    _stateController.close();
  }
}

// ── Providers ───────────────────────────────────────────────

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  ref.onDispose(() => service.dispose());
  return service;
});

final voiceStateProvider = StreamProvider<VoiceInputState>((ref) {
  return ref.watch(voiceServiceProvider).onStateChange;
});

final voiceResultProvider = StreamProvider<VoiceInputResult>((ref) {
  return ref.watch(voiceServiceProvider).onResult;
});
