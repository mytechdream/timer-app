enum TimerRunMode { countdown, stopwatch }

class CreatedTimer {
  const CreatedTimer({
    required this.id,
    required this.name,
    required this.seconds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int seconds;
  final DateTime createdAt;

  CreatedTimer copyWith({
    String? id,
    String? name,
    int? seconds,
    DateTime? createdAt,
  }) {
    return CreatedTimer(
      id: id ?? this.id,
      name: name ?? this.name,
      seconds: seconds ?? this.seconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'seconds': seconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CreatedTimer.fromJson(Map<String, Object?> json) {
    return CreatedTimer(
      id: json['id'] as String,
      name: json['name'] as String,
      seconds: json['seconds'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class TimerHistoryEntry {
  const TimerHistoryEntry({
    required this.id,
    required this.name,
    required this.mode,
    required this.durationSeconds,
    required this.completedAt,
  });

  final String id;
  final String name;
  final TimerRunMode mode;
  final int durationSeconds;
  final DateTime completedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'mode': mode.name,
      'durationSeconds': durationSeconds,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory TimerHistoryEntry.fromJson(Map<String, Object?> json) {
    return TimerHistoryEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      mode: TimerRunMode.values.firstWhere(
        (TimerRunMode value) => value.name == json['mode'],
        orElse: () => TimerRunMode.countdown,
      ),
      durationSeconds: json['durationSeconds'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}

class TimerSettings {
  const TimerSettings({
    this.defaultCountdownSeconds = 10 * 60,
    this.extendSeconds = 3,
    this.completionSoundEnabled = true,
    this.backgroundRunEnabled = false,
  });

  final int defaultCountdownSeconds;
  final int extendSeconds;
  final bool completionSoundEnabled;
  final bool backgroundRunEnabled;

  TimerSettings copyWith({
    int? defaultCountdownSeconds,
    int? extendSeconds,
    bool? completionSoundEnabled,
    bool? backgroundRunEnabled,
  }) {
    return TimerSettings(
      defaultCountdownSeconds:
          defaultCountdownSeconds ?? this.defaultCountdownSeconds,
      extendSeconds: extendSeconds ?? this.extendSeconds,
      completionSoundEnabled:
          completionSoundEnabled ?? this.completionSoundEnabled,
      backgroundRunEnabled: backgroundRunEnabled ?? this.backgroundRunEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'defaultCountdownSeconds': defaultCountdownSeconds,
      'extendSeconds': extendSeconds,
      'completionSoundEnabled': completionSoundEnabled,
      'backgroundRunEnabled': backgroundRunEnabled,
    };
  }

  factory TimerSettings.fromJson(Map<String, Object?> json) {
    return TimerSettings(
      defaultCountdownSeconds:
          (json['defaultCountdownSeconds'] as int?) ?? 10 * 60,
      extendSeconds: (json['extendSeconds'] as int?) ?? 3,
      completionSoundEnabled: (json['completionSoundEnabled'] as bool?) ?? true,
      backgroundRunEnabled: (json['backgroundRunEnabled'] as bool?) ?? false,
    );
  }
}

class TimerSnapshot {
  const TimerSnapshot({
    required this.timers,
    required this.history,
    required this.labels,
    required this.settings,
  });

  final List<CreatedTimer> timers;
  final List<TimerHistoryEntry> history;
  final List<String> labels;
  final TimerSettings settings;

  factory TimerSnapshot.initial() {
    return const TimerSnapshot(
      timers: <CreatedTimer>[],
      history: <TimerHistoryEntry>[],
      labels: <String>[],
      settings: TimerSettings(),
    );
  }

  TimerSnapshot copyWith({
    List<CreatedTimer>? timers,
    List<TimerHistoryEntry>? history,
    List<String>? labels,
    TimerSettings? settings,
  }) {
    return TimerSnapshot(
      timers: timers ?? this.timers,
      history: history ?? this.history,
      labels: labels ?? this.labels,
      settings: settings ?? this.settings,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'timers': timers.map((CreatedTimer timer) => timer.toJson()).toList(),
      'history':
          history.map((TimerHistoryEntry entry) => entry.toJson()).toList(),
      'labels': labels,
      'settings': settings.toJson(),
    };
  }

  factory TimerSnapshot.fromJson(Map<String, Object?> json) {
    return TimerSnapshot(
      timers: ((json['timers'] as List<Object?>?) ?? <Object?>[])
          .cast<Map<String, Object?>>()
          .map(CreatedTimer.fromJson)
          .toList(),
      history: ((json['history'] as List<Object?>?) ?? <Object?>[])
          .cast<Map<String, Object?>>()
          .map(TimerHistoryEntry.fromJson)
          .toList(),
      labels: ((json['labels'] as List<Object?>?) ?? <Object?>[])
          .map((Object? label) => label.toString())
          .toList(),
      settings: json['settings'] is Map<String, Object?>
          ? TimerSettings.fromJson(json['settings']! as Map<String, Object?>)
          : const TimerSettings(),
    );
  }
}
