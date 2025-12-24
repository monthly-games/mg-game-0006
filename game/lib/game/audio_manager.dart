import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  // Cache for rapid SFX
  // final Map<String, AudioPlayer> _sfxPool = {};

  bool _isMuted = false;

  Future<void> init() async {
    // Preload common sounds if needed
    // await _bgmPlayer.setSourceAsset('audio/bgm_battle.mp3');
  }

  void playBgm(String assetPath) async {
    if (_isMuted) return;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint("Error playing BGM: $e");
    }
  }

  void stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint("Error stopping BGM: $e");
    }
  }

  void playSfx(String assetPath) async {
    if (_isMuted) return;
    // Simple fire and forget for SFX using static method for simplicity or pool
    // AudioPlayer().play(AssetSource(assetPath));
    try {
      final player = AudioPlayer();
      await player.play(AssetSource(assetPath));
      // Dispose player after completion? AudioPlayers handles this mostly but excessive instances can be bad.
      // ideally use a pool.
      player.onPlayerComplete.listen((event) {
        player.dispose();
      });
    } catch (e) {
      debugPrint("Error playing SFX: $e");
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _bgmPlayer.setVolume(0);
    } else {
      _bgmPlayer.setVolume(1);
    }
  }
}
