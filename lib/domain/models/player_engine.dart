/// The video engines the player can use.
enum PlayerEngine {
  /// libVLC through `flutter_vlc_player`. Falls back to ExoPlayer per source.
  vlc('vlc', 'VLC (libVLC)'),

  /// Android ExoPlayer through `video_player`.
  exo('exo', 'ExoPlayer');

  /// The engine when the user chose none. ExoPlayer since TASK-027: on the
  /// owner's SM-A546E, VLC at times drew grey or smeared frames, which are no
  /// error and so never reach the ExoPlayer fallback. VLC stays in Settings.
  static const PlayerEngine defaultEngine = PlayerEngine.exo;

  const PlayerEngine(this.code, this.label);

  /// Stored in the settings box.
  final String code;

  /// Shown in Settings, the same in every language.
  final String label;

  /// Unknown or missing codes give [defaultEngine].
  static PlayerEngine fromCode(String? code) {
    for (final engine in PlayerEngine.values) {
      if (engine.code == code) return engine;
    }
    return defaultEngine;
  }

  /// The engines a source is tried on, in order, for Settings About. For
  /// example "VLC (libVLC) → ExoPlayer".
  String get chain {
    final names = <String>[];
    for (PlayerEngine? e = this; e != null; e = e.fallbackEngine()) {
      names.add(e.label);
    }
    return names.join(' → ');
  }

  /// The engine that tries the same source again after this one failed on
  /// it, or `null` when the player must move on to the next source.
  PlayerEngine? fallbackEngine() {
    switch (this) {
      case PlayerEngine.vlc:
        return PlayerEngine.exo;
      case PlayerEngine.exo:
        return null;
    }
  }
}
