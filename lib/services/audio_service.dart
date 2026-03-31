// lib/services/audio_service.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AudioServiceException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() =>
      'AudioServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}

class AudioService {
  static const int maxRecordingDurationMinutes = 10;
  static const int maxFileSizeMB = 50;
  static const int minFileSizeBytes = 1000;
  static const Duration uploadTimeout = Duration(minutes: 5);
  static const Duration _periodicDurationInterval = Duration(seconds: 1);

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  final _recordingStateController = StreamController<bool>.broadcast();
  final _playingStateController = StreamController<bool>.broadcast();
  final _recordingDurationController = StreamController<Duration>.broadcast();

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  Stream<bool> get recordingStateStream => _recordingStateController.stream;
  Stream<bool> get playingStateStream => _playingStateController.stream;
  Stream<Duration> get recordingDurationStream =>
      _recordingDurationController.stream;

  Future<bool> hasAudioPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      _logError('hasAudioPermission', e);
      return false;
    }
  }

  Future<bool> requestAudioPermission() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw AudioServiceException(
          'Permission audio refusée. Veuillez activer les permissions dans les paramètres.',
          code: 'PERMISSION_DENIED',
        );
      }
      return true;
    } catch (e) {
      _logError('requestAudioPermission', e);
      if (e is AudioServiceException) rethrow;
      return false;
    }
  }

  Future<void> startRecording() async {
    if (_isRecording) {
      throw AudioServiceException(
        'Un enregistrement est déjà en cours',
        code: 'ALREADY_RECORDING',
      );
    }

    try {
      final hasPermission = await hasAudioPermission();
      if (!hasPermission) {
        throw AudioServiceException(
          'Permission microphone requise. Veuillez activer dans les paramètres.',
          code: 'PERMISSION_DENIED',
        );
      }

      await _checkStorageSpace();

      final recordingPath = await _generateRecordingPath();
      _currentRecordingPath = recordingPath;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: recordingPath,
      );

      _setRecordingState(true);
      _startRecordingDurationTimer();
      _logInfo('Enregistrement démarré: $recordingPath');
    } catch (e) {
      _setRecordingState(false);
      _currentRecordingPath = null;
      _logError('startRecording', e);
      if (e is AudioServiceException) rethrow;
      throw AudioServiceException(
        'Erreur lors du démarrage de l\'enregistrement',
        code: 'START_RECORDING_FAILED',
        originalError: e,
      );
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) {
      _logWarning('stopRecording appelé mais aucun enregistrement en cours');
      return null;
    }

    try {
      final path = await _recorder.stop();
      _setRecordingState(false);
      _durationSubscription?.cancel();

      if (path != null) {
        await _validateRecordingFile(path);
        _logInfo('Enregistrement arrêté: $path (${await _getFileSize(path)})');
        return path;
      }

      return null;
    } catch (e) {
      _setRecordingState(false);
      _durationSubscription?.cancel();
      _logError('stopRecording', e);
      if (e is AudioServiceException) rethrow;
      throw AudioServiceException(
        'Erreur lors de l\'arrêt de l\'enregistrement',
        code: 'STOP_RECORDING_FAILED',
        originalError: e,
      );
    } finally {
      _currentRecordingPath = null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _setRecordingState(false);
        _durationSubscription?.cancel();
      }

      if (_currentRecordingPath != null) {
        await _deleteRecordingFile(_currentRecordingPath!);
        _currentRecordingPath = null;
      }
    } catch (e) {
      _logError('cancelRecording', e);
    }
  }

  Future<void> playAudio(String url, {VoidCallback? onComplete}) async {
    if (url.trim().isEmpty) {
      throw AudioServiceException('URL audio vide', code: 'INVALID_URL');
    }

    try {
      if (_isPlaying) {
        await stopAudio();
      }

      final source = await _createAudioSource(url);
      await _player.play(source);
      _setPlayingState(true);
      _setupPlayerStateListener(onComplete);

      _logInfo('Lecture audio démarrée: $url');
    } catch (e) {
      _setPlayingState(false);
      _logError('playAudio', e);
      if (e is AudioServiceException) rethrow;
      throw AudioServiceException(
        'Erreur lors de la lecture audio',
        code: 'PLAY_AUDIO_FAILED',
        originalError: e,
      );
    }
  }

  Future<void> stopAudio() async {
    try {
      await _player.stop();
      _setPlayingState(false);
      _logInfo('Lecture audio arrêtée');
    } catch (e) {
      _setPlayingState(false);
      _logError('stopAudio', e);
    }
  }

  Future<void> pauseAudio() async {
    if (!_isPlaying) return;

    try {
      await _player.pause();
      _setPlayingState(false);
      _logInfo('Lecture audio en pause');
    } catch (e) {
      _logError('pauseAudio', e);
    }
  }

  Future<void> resumeAudio() async {
    if (_isPlaying) return;

    try {
      await _player.resume();
      _setPlayingState(true);
      _logInfo('Lecture audio reprise');
    } catch (e) {
      _logError('resumeAudio', e);
    }
  }

  Future<Duration?> getCurrentPosition() async {
    try {
      return await _player.getCurrentPosition();
    } catch (e) {
      _logError('getCurrentPosition', e);
      return null;
    }
  }

  Future<Duration?> getDuration() async {
    try {
      return await _player.getDuration();
    } catch (e) {
      _logError('getDuration', e);
      return null;
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
      _logInfo('Seek to: ${position.inSeconds}s');
    } catch (e) {
      _logError('seek', e);
    }
  }

  void _setRecordingState(bool isRecording) {
    _isRecording = isRecording;
    _recordingStateController.add(isRecording);
  }

  void _setPlayingState(bool isPlaying) {
    _isPlaying = isPlaying;
    _playingStateController.add(isPlaying);
  }

  Future<String> _generateRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/audio_$timestamp.m4a';
  }

  Future<void> _validateRecordingFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw AudioServiceException(
        'Fichier d\'enregistrement introuvable',
        code: 'FILE_NOT_FOUND',
      );
    }

    final fileSize = await file.length();
    if (fileSize < minFileSizeBytes) {
      await file.delete();
      throw AudioServiceException(
        'Enregistrement trop court ou invalide',
        code: 'INVALID_RECORDING',
      );
    }

    final maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;
    if (fileSize > maxFileSizeBytes) {
      await file.delete();
      throw AudioServiceException(
        'Enregistrement trop volumineux (max: ${maxFileSizeMB}MB)',
        code: 'FILE_TOO_LARGE',
      );
    }
  }

  Future<void> _deleteRecordingFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      _logInfo('Enregistrement annulé et fichier supprimé');
    }
  }

  Future<Source> _createAudioSource(String url) async {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return UrlSource(url);
    }

    final file = File(url);
    if (await file.exists()) {
      return DeviceFileSource(url);
    }

    throw AudioServiceException(
      'Fichier audio introuvable',
      code: 'FILE_NOT_FOUND',
    );
  }

  void _setupPlayerStateListener(VoidCallback? onComplete) {
    _playerStateSubscription?.cancel();
    _playerStateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        _setPlayingState(false);
        onComplete?.call();
      }
    });
  }

  void _startRecordingDurationTimer() {
    _durationSubscription?.cancel();

    _durationSubscription = Stream.periodic(
      _periodicDurationInterval,
      (tick) => Duration(seconds: tick + 1),
    ).listen((duration) {
      _recordingDurationController.add(duration);

      if (duration.inMinutes >= maxRecordingDurationMinutes) {
        _logWarning('Durée maximale atteinte, arrêt automatique');
        // FIX (QA P1): stopRecording() is async. Calling it without await or
        // catchError in a sync Stream.periodic callback means any exception it
        // throws is silently swallowed, and _isRecording stays true forever —
        // blocking any future recording attempt.
        // Fix: attach catchError so failures are logged and state is corrected.
        stopRecording().catchError((Object e) {
          _logError('auto-stop-timer', e);
        });
      }
    });
  }

  Future<void> _checkStorageSpace() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      if (!await directory.exists()) {
        throw AudioServiceException(
          'Répertoire de stockage inaccessible',
          code: 'STORAGE_UNAVAILABLE',
        );
      }
    } catch (e) {
      _logWarning('Could not verify storage space: $e');
    }
  }

  Future<String> _getFileSize(String path) async {
    try {
      final file = File(path);
      final bytes = await file.length();
      return _formatBytes(bytes);
    } catch (e) {
      return 'unknown';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _logInfo(String message) {
    if (kDebugMode) debugPrint('[AudioService] INFO: $message');
  }

  void _logWarning(String message) {
    if (kDebugMode) debugPrint('[AudioService] WARNING: $message');
  }

  void _logError(String method, dynamic error) {
    if (kDebugMode) debugPrint('[AudioService] ERROR in $method: $error');
  }

  Future<void> dispose() async {
    await _durationSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _player.dispose();
    await _recorder.dispose();
    await _recordingStateController.close();
    await _playingStateController.close();
    await _recordingDurationController.close();
  }
}