import 'package:just_audio/just_audio.dart';

/// Service for playing audio files using just_audio
class AudioPlayerService {
  AudioPlayer? _player;
  String? _currentUrl;

  /// Get the audio player instance
  AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Play audio from URL
  Future<void> play(String url) async {
    try {
      // Only create new player or change source if URL is different
      if (_currentUrl != url) {
        await player.setUrl(url);
        _currentUrl = url;
      }

      // Reset to beginning if already played
      if (player.position > Duration.zero) {
        await player.seek(Duration.zero);
      }

      await player.play();
    } catch (e) {
      throw AudioPlayerException('Failed to play audio: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await player.pause();
    } catch (e) {
      throw AudioPlayerException('Failed to pause audio: $e');
    }
  }

  /// Stop playback and reset position
  Future<void> stop() async {
    try {
      await player.stop();
      await player.seek(Duration.zero);
    } catch (e) {
      throw AudioPlayerException('Failed to stop audio: $e');
    }
  }

  /// Replay current audio
  Future<void> replay() async {
    try {
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      throw AudioPlayerException('Failed to replay audio: $e');
    }
  }

  /// Get current playback position
  Duration get position => player.position;

  /// Get total audio duration
  Duration? get duration => player.duration;

  /// Check if audio is currently playing
  bool get isPlaying => player.playing;

  /// Stream of playback positions
  Stream<Duration> get positionStream => player.positionStream;

  /// Stream of playback states
  Stream<PlayerState> get playerStateStream => player.playerStateStream;

  /// Stream of duration changes
  Stream<Duration?> get durationStream => player.durationStream;

  /// Set playback volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      throw AudioPlayerException('Failed to set volume: $e');
    }
  }

  /// Set playback speed (0.5 to 2.0)
  Future<void> setSpeed(double speed) async {
    try {
      await player.setSpeed(speed.clamp(0.5, 2.0));
    } catch (e) {
      throw AudioPlayerException('Failed to set speed: $e');
    }
  }

  /// Dispose the player and release resources
  Future<void> dispose() async {
    try {
      await player.stop();
      await player.dispose();
      _player = null;
      _currentUrl = null;
    } catch (e) {
      // Ignore disposal errors
    }
  }
}

/// Exception thrown when audio player operations fail
class AudioPlayerException implements Exception {
  final String message;

  AudioPlayerException(this.message);

  @override
  String toString() => message;
}
