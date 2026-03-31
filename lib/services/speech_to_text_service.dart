// lib/services/speech_to_text_service.dart

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef SttResultCallback = void Function(String text, bool isFinal);

class SpeechToTextService {
  final SpeechToText _stt = SpeechToText();
  bool _isInitialized = false;

  bool get isListening    => _stt.isListening;
  bool get isAvailable    => _stt.isAvailable;
  bool get isInitialized  => _isInitialized;

  // --------------------------------------------------------------------------
  // Init
  // --------------------------------------------------------------------------

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _stt.initialize(
        onError:  (e) => debugPrint('[STT] Error: ${e.errorMsg}'),
        onStatus: (s) => debugPrint('[STT] Status: $s'),
        debugLogging: kDebugMode,
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('[STT] Initialize failed: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // Listen / Stop
  // --------------------------------------------------------------------------

  Future<void> startListening({
    required SttResultCallback onResult,
    String localeId = 'fr_FR',
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }
    if (_stt.isListening) await stopListening();

    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        // FIX: guard against premature final results — require at least
        // 2 words before treating a result as final. STT sometimes fires
        // isFinal=true on a single misrecognized word (e.g. "plan B")
        // before the user has finished speaking. The 2-word minimum gives
        // Gemini enough context for accurate intent extraction.
        final words     = result.recognizedWords.trim().split(' ')
            .where((w) => w.isNotEmpty)
            .toList();
        final hasEnough = words.length >= 2;
        onResult(result.recognizedWords, result.finalResult && hasEnough);
      },
      localeId:       localeId,
      listenFor:      const Duration(seconds: 30),
      pauseFor:       const Duration(seconds: 5),
      partialResults: true,
      cancelOnError:  true,
    );
  }

  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
  }

  Future<void> cancelListening() async {
    if (_stt.isListening) await _stt.cancel();
  }

  void dispose() {
    _stt.cancel();
  }
}