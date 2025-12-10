import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';

/// Service for recording audio to memory buffer (no file writes)
/// 
/// Note: Due to record package limitations, this implementation:
/// 1. Records to temporary file
/// 2. Immediately reads bytes into memory
/// 3. Deletes temporary file
/// 4. Returns only bytes (never exposes file paths)
/// 
/// This provides "memory-only" behavior with immediate cleanup.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  Uint8List? _audioBuffer;
  String? _tempFilePath;
  
  /// Maximum buffer size: 10MB
  static const int maxBufferSize = 10 * 1024 * 1024; // 10MB

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    return await hasPermission();
  }

  /// Start recording to memory buffer
  Future<void> startRecording() async {
    try {
      // Check permission first
      final hasPermission = await this.hasPermission();
      if (!hasPermission) {
        throw AudioRecorderException(
          'Microphone permission not granted. Please enable microphone access in settings.',
        );
      }

      // Clear previous buffer
      _audioBuffer = null;
      _tempFilePath = null;

      // Start recording to stream (record package will use temp file internally)
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000, // 64kbps for good quality with small size
          sampleRate: 16000, // 16kHz for speech recognition
        ),
      );
    } catch (e) {
      throw AudioRecorderException('Failed to start recording: $e');
    }
  }

  /// Stop recording and return audio bytes
  Future<Uint8List> stopRecording() async {
    try {
      // Stop recording and get the audio path
      final path = await _recorder.stop();

      if (path == null) {
        throw AudioRecorderException('No audio data recorded');
      }

      _tempFilePath = path;

      // Read file into memory
      final file = File(path);
      if (!await file.exists()) {
        throw AudioRecorderException('Recording file not found');
      }

      final bytes = await file.readAsBytes();

      // Validate buffer size
      if (bytes.length > maxBufferSize) {
        // Delete oversized file
        await file.delete();
        throw AudioRecorderException(
          'Recording exceeds maximum size of ${maxBufferSize ~/ 1024 ~/ 1024}MB. '
          'Please keep recordings under 2 minutes.',
        );
      }

      _audioBuffer = Uint8List.fromList(bytes);

      // Delete the temp file immediately (memory-only behavior)
      await file.delete();
      _tempFilePath = null;

      return _audioBuffer!;
    } catch (e) {
      // Clean up temp file on error
      if (_tempFilePath != null) {
        try {
          await File(_tempFilePath!).delete();
        } catch (_) {}
      }
      
      if (e is AudioRecorderException) rethrow;
      throw AudioRecorderException('Failed to stop recording: $e');
    }
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    try {
      final path = await _recorder.stop();
      _audioBuffer = null;
      
      // Delete temp file if it exists
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
    } catch (e) {
      throw AudioRecorderException('Failed to cancel recording: $e');
    }
  }

  /// Check if currently recording
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  /// Get the current audio buffer (last recording)
  Uint8List? getAudioBuffer() {
    return _audioBuffer;
  }

  /// Get buffer size in bytes
  int? getBufferSize() {
    return _audioBuffer?.length;
  }

  /// Get buffer size in MB
  double? getBufferSizeMB() {
    final size = getBufferSize();
    if (size == null) return null;
    return size / (1024 * 1024);
  }

  /// Check if buffer exceeds maximum size
  bool isBufferOverLimit() {
    final size = getBufferSize();
    if (size == null) return false;
    return size > maxBufferSize;
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    try {
      await _recorder.pause();
    } catch (e) {
      throw AudioRecorderException('Failed to pause recording: $e');
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    try {
      await _recorder.resume();
    } catch (e) {
      throw AudioRecorderException('Failed to resume recording: $e');
    }
  }

  /// Dispose the recorder and release resources
  Future<void> dispose() async {
    try {
      // Stop if still recording
      if (await isRecording()) {
        await cancelRecording();
      }
      
      await _recorder.dispose();
      _audioBuffer = null;
      _tempFilePath = null;
    } catch (e) {
      // Ignore disposal errors
    }
  }
}

/// Exception thrown when audio recorder operations fail
class AudioRecorderException implements Exception {
  final String message;

  AudioRecorderException(this.message);

  @override
  String toString() => message;
}
