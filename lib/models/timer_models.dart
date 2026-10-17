enum TimerRunMode { countdown, stopwatch }

enum TimerCollectionScope { home, batch }

class TimerPreset {
  const TimerPreset({
    required this.id,
    required this.name,
    required this.seconds,
  });

  final String id;
  final String name;
  final int seconds;
}

class TimerDefaults {
  const TimerDefaults._();

  static const List<TimerPreset> countdownTimers = <TimerPreset>[
    TimerPreset(
        id: 'default-countdown-brush-teeth', name: '刷牙', seconds: 3 * 60),
    TimerPreset(
        id: 'default-countdown-pomodoro', name: '番茄时钟', seconds: 25 * 60),
    TimerPreset(id: 'default-countdown-writing', name: '练字', seconds: 15 * 60),
  ];

  static const List<TimerPreset> batchCountdownTimers = <TimerPreset>[
    TimerPreset(id: 'default-batch-countdown', name: '新倒计时', seconds: 15 * 60),
  ];

  static const List<String> stopwatchLabels = <String>['口算', '阅读', '运动', '学习'];
  static const List<String> batchStopwatchLabels = <String>['新正计时'];

  static List<TimerPreset> countdownTimersFor(TimerCollectionScope scope) =>
      scope == TimerCollectionScope.home
          ? countdownTimers
          : batchCountdownTimers;

  static List<String> stopwatchLabelsFor(TimerCollectionScope scope) =>
      scope == TimerCollectionScope.home
          ? stopwatchLabels
          : batchStopwatchLabels;
}

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

/// Presets, labels and default-item visibility owned by one timer page.
/// Changes return a new collection and never mutate another page's lists.
class TimerCollection {
  const TimerCollection({
    required this.scope,
    this.timers = const <CreatedTimer>[],
    this.labels = const <String>[],
    this.hiddenDefaultTimerIds = const <String>[],
    this.hiddenDefaultLabels = const <String>[],
  });

  final TimerCollectionScope scope;
  final List<CreatedTimer> timers;
  final List<String> labels;
  final List<String> hiddenDefaultTimerIds;
  final List<String> hiddenDefaultLabels;

  Set<String> get visibleLabels => <String>{
        for (final String label in TimerDefaults.stopwatchLabelsFor(scope))
          if (!hiddenDefaultLabels.contains(label)) label,
        ...labels,
      };

  bool _isDefaultLabel(String label) =>
      TimerDefaults.stopwatchLabelsFor(scope).contains(label);

  TimerCollection copyWith({
    List<CreatedTimer>? timers,
    List<String>? labels,
    List<String>? hiddenDefaultTimerIds,
    List<String>? hiddenDefaultLabels,
  }) =>
      TimerCollection(
        scope: scope,
        timers: timers ?? this.timers,
        labels: labels ?? this.labels,
        hiddenDefaultTimerIds:
            hiddenDefaultTimerIds ?? this.hiddenDefaultTimerIds,
        hiddenDefaultLabels: hiddenDefaultLabels ?? this.hiddenDefaultLabels,
      );

  TimerCollection addTimer(CreatedTimer timer) => copyWith(
        timers: <CreatedTimer>[...timers, timer],
      );

  TimerCollection deleteTimer(String id) {
    final bool isDefault = TimerDefaults.countdownTimersFor(scope)
        .any((TimerPreset timer) => timer.id == id);
    return copyWith(
      timers: timers.where((CreatedTimer timer) => timer.id != id).toList(),
      hiddenDefaultTimerIds: isDefault
          ? <String>{...hiddenDefaultTimerIds, id}.toList()
          : hiddenDefaultTimerIds,
    );
  }

  TimerCollection addLabel(String label) {
    final String normalized = label.trim();
    if (normalized.isEmpty || labels.contains(normalized)) {
      return this;
    }
    if (_isDefaultLabel(normalized)) {
      if (!hiddenDefaultLabels.contains(normalized)) {
        return this;
      }
      return copyWith(
        hiddenDefaultLabels: hiddenDefaultLabels
            .where((String label) => label != normalized)
            .toList(),
      );
    }
    return copyWith(labels: <String>[...labels, normalized]);
  }

  TimerCollection renameLabel(String oldLabel, String newLabel) {
    final String normalized = newLabel.trim();
    if (normalized.isEmpty || normalized == oldLabel) {
      return this;
    }
    if (!visibleLabels.contains(oldLabel) ||
        visibleLabels.contains(normalized)) {
      return this;
    }
    return copyWith(
      labels: <String>[
        for (final String label in labels)
          if (label != oldLabel) label,
        if (!_isDefaultLabel(normalized)) normalized,
      ],
      hiddenDefaultLabels: <String>{
        for (final String label in hiddenDefaultLabels)
          if (label != normalized) label,
        if (_isDefaultLabel(oldLabel)) oldLabel,
      }.toList(),
    );
  }

  TimerCollection deleteLabel(String label) => copyWith(
        labels: labels.where((String value) => value != label).toList(),
        hiddenDefaultLabels: _isDefaultLabel(label)
            ? <String>{...hiddenDefaultLabels, label}.toList()
            : hiddenDefaultLabels,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'timers': timers.map((CreatedTimer timer) => timer.toJson()).toList(),
        'labels': labels,
        'hiddenDefaultTimerIds': hiddenDefaultTimerIds,
        'hiddenDefaultLabels': hiddenDefaultLabels,
      };

  factory TimerCollection.fromJson(
    Map<String, Object?> json, {
    required TimerCollectionScope scope,
  }) =>
      TimerCollection(
        scope: scope,
        timers: ((json['timers'] as List<Object?>?) ?? <Object?>[])
            .cast<Map<String, Object?>>()
            .map(CreatedTimer.fromJson)
            .toList(),
        labels: ((json['labels'] as List<Object?>?) ?? <Object?>[])
            .map((Object? label) => label.toString())
            .toList(),
        hiddenDefaultTimerIds:
            ((json['hiddenDefaultTimerIds'] as List<Object?>?) ?? <Object?>[])
                .map((Object? id) => id.toString())
                .toList(),
        hiddenDefaultLabels:
            ((json['hiddenDefaultLabels'] as List<Object?>?) ?? <Object?>[])
                .map((Object? label) => label.toString())
                .toList(),
      );
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
    this.completionReminderName = reminderSoundAndVibration,
    this.alertSoundName = '清脆铃声',
    this.tickSoundEnabled = true,
    this.backgroundRunEnabled = false,
  });

  static const String reminderOff = '关闭';
  static const String reminderSoundOnly = '仅提示音';
  static const String reminderSoundAndVibration = '提示音 + 振动';

  static const List<String> completionReminderOptions = <String>[
    reminderOff,
    reminderSoundOnly,
    reminderSoundAndVibration,
  ];

  static const List<String> alertSoundOptions = <String>[
    '清脆铃声',
    '柔和提示',
    '电子提示',
  ];

  final int defaultCountdownSeconds;
  final int extendSeconds;
  final bool completionSoundEnabled;
  final String completionReminderName;
  final String alertSoundName;
  final bool tickSoundEnabled;
  final bool backgroundRunEnabled;

  TimerSettings copyWith({
    int? defaultCountdownSeconds,
    int? extendSeconds,
    bool? completionSoundEnabled,
    String? completionReminderName,
    String? alertSoundName,
    bool? tickSoundEnabled,
    bool? backgroundRunEnabled,
  }) {
    return TimerSettings(
      defaultCountdownSeconds:
          defaultCountdownSeconds ?? this.defaultCountdownSeconds,
      extendSeconds: extendSeconds ?? this.extendSeconds,
      completionSoundEnabled:
          completionSoundEnabled ?? this.completionSoundEnabled,
      completionReminderName:
          completionReminderName ?? this.completionReminderName,
      alertSoundName: alertSoundName ?? this.alertSoundName,
      tickSoundEnabled: tickSoundEnabled ?? this.tickSoundEnabled,
      backgroundRunEnabled: backgroundRunEnabled ?? this.backgroundRunEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'defaultCountdownSeconds': defaultCountdownSeconds,
      'extendSeconds': extendSeconds,
      'completionSoundEnabled': completionSoundEnabled,
      'completionReminderName': completionReminderName,
      'alertSoundName': alertSoundName,
      'tickSoundEnabled': tickSoundEnabled,
      'backgroundRunEnabled': backgroundRunEnabled,
    };
  }

  factory TimerSettings.fromJson(Map<String, Object?> json) {
    final bool completionSoundEnabled =
        (json['completionSoundEnabled'] as bool?) ?? true;
    final String fallbackReminderName =
        completionSoundEnabled ? reminderSoundAndVibration : reminderOff;
    return TimerSettings(
      defaultCountdownSeconds:
          (json['defaultCountdownSeconds'] as int?) ?? 10 * 60,
      extendSeconds: (json['extendSeconds'] as int?) ?? 3,
      completionSoundEnabled: completionSoundEnabled,
      completionReminderName:
          (json['completionReminderName'] as String?) ?? fallbackReminderName,
      alertSoundName: (json['alertSoundName'] as String?) ?? '清脆铃声',
      tickSoundEnabled: (json['tickSoundEnabled'] as bool?) ?? true,
      backgroundRunEnabled: (json['backgroundRunEnabled'] as bool?) ?? false,
    );
  }
}

class TimerSnapshot {
  const TimerSnapshot({
    required this.timers,
    required this.history,
    required this.labels,
    required this.hiddenDefaultTimerIds,
    required this.hiddenDefaultLabels,
    required this.settings,
    this.batch = const TimerCollection(scope: TimerCollectionScope.batch),
  });

  final List<CreatedTimer> timers;
  final List<TimerHistoryEntry> history;
  final List<String> labels;
  final List<String> hiddenDefaultTimerIds;
  final List<String> hiddenDefaultLabels;
  final TimerSettings settings;
  final TimerCollection batch;

  // The original top-level fields now belong only to the home page. Keeping
  // their storage keys preserves existing presets, history and settings.
  TimerCollection collection(TimerCollectionScope scope) =>
      scope == TimerCollectionScope.batch
          ? batch
          : TimerCollection(
              scope: TimerCollectionScope.home,
              timers: timers,
              labels: labels,
              hiddenDefaultTimerIds: hiddenDefaultTimerIds,
              hiddenDefaultLabels: hiddenDefaultLabels,
            );

  TimerSnapshot withCollection(TimerCollection collection) =>
      collection.scope == TimerCollectionScope.batch
          ? copyWith(batch: collection)
          : copyWith(
              timers: collection.timers,
              labels: collection.labels,
              hiddenDefaultTimerIds: collection.hiddenDefaultTimerIds,
              hiddenDefaultLabels: collection.hiddenDefaultLabels,
            );

  factory TimerSnapshot.initial() {
    return const TimerSnapshot(
      timers: <CreatedTimer>[],
      history: <TimerHistoryEntry>[],
      labels: <String>[],
      hiddenDefaultTimerIds: <String>[],
      hiddenDefaultLabels: <String>[],
      settings: TimerSettings(),
    );
  }

  TimerSnapshot copyWith({
    List<CreatedTimer>? timers,
    List<TimerHistoryEntry>? history,
    List<String>? labels,
    List<String>? hiddenDefaultTimerIds,
    List<String>? hiddenDefaultLabels,
    TimerSettings? settings,
    TimerCollection? batch,
  }) {
    return TimerSnapshot(
      timers: timers ?? this.timers,
      history: history ?? this.history,
      labels: labels ?? this.labels,
      hiddenDefaultTimerIds:
          hiddenDefaultTimerIds ?? this.hiddenDefaultTimerIds,
      hiddenDefaultLabels: hiddenDefaultLabels ?? this.hiddenDefaultLabels,
      settings: settings ?? this.settings,
      batch: batch ?? this.batch,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      ...collection(TimerCollectionScope.home).toJson(),
      'history':
          history.map((TimerHistoryEntry entry) => entry.toJson()).toList(),
      'settings': settings.toJson(),
      'batch': batch.toJson(),
    };
  }

  factory TimerSnapshot.fromJson(Map<String, Object?> json) {
    final TimerCollection home =
        TimerCollection.fromJson(json, scope: TimerCollectionScope.home);
    // Old snapshots had one shared collection and no provenance. Preserve it
    // in both pages once. An explicitly empty batch collection stays empty.
    final Map<String, Object?> batchJson = !json.containsKey('batch')
        ? json
        : (json['batch'] as Map<String, Object?>?) ?? <String, Object?>{};
    return TimerSnapshot(
      timers: home.timers,
      history: ((json['history'] as List<Object?>?) ?? <Object?>[])
          .cast<Map<String, Object?>>()
          .map(TimerHistoryEntry.fromJson)
          .toList(),
      labels: home.labels,
      hiddenDefaultTimerIds: home.hiddenDefaultTimerIds,
      hiddenDefaultLabels: home.hiddenDefaultLabels,
      settings: json['settings'] is Map<String, Object?>
          ? TimerSettings.fromJson(json['settings']! as Map<String, Object?>)
          : const TimerSettings(),
      batch: TimerCollection.fromJson(batchJson,
          scope: TimerCollectionScope.batch),
    );
  }
}
