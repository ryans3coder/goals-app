class FeedbackPreferences {
  const FeedbackPreferences({
    required this.soundEnabled,
    required this.animationsEnabled,
    required this.hapticEnabled,
  });

  factory FeedbackPreferences.defaults() {
    return const FeedbackPreferences(
      soundEnabled: true,
      animationsEnabled: true,
      hapticEnabled: true,
    );
  }

  factory FeedbackPreferences.fromMap(Map<String, dynamic> map) {
    return FeedbackPreferences(
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      animationsEnabled: map['animationsEnabled'] as bool? ?? true,
      hapticEnabled: map['hapticEnabled'] as bool? ?? true,
    );
  }

  final bool soundEnabled;
  final bool animationsEnabled;
  final bool hapticEnabled;

  Map<String, dynamic> toMap() {
    return {
      'soundEnabled': soundEnabled,
      'animationsEnabled': animationsEnabled,
      'hapticEnabled': hapticEnabled,
    };
  }

  FeedbackPreferences copyWith({
    bool? soundEnabled,
    bool? animationsEnabled,
    bool? hapticEnabled,
  }) {
    return FeedbackPreferences(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }
}
