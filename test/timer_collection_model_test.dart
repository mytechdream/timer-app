import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:timer_app/models/timer_models.dart';

CreatedTimer _timer(String name, {String id = 'same-id'}) => CreatedTimer(
      id: id,
      name: name,
      seconds: 600,
      createdAt: DateTime(2026, 10, 12, 10),
    );

TimerSnapshot _snapshot() => TimerSnapshot.initial().copyWith(
      timers: <CreatedTimer>[_timer('首页计时')],
      labels: <String>['同名标签'],
      batch: TimerCollection(
        scope: TimerCollectionScope.batch,
        timers: <CreatedTimer>[_timer('批量计时')],
        labels: <String>['同名标签'],
      ),
      settings: const TimerSettings(extendSeconds: 7),
      history: <TimerHistoryEntry>[
        TimerHistoryEntry(
          id: 'history',
          name: '既有记录',
          mode: TimerRunMode.stopwatch,
          durationSeconds: 90,
          completedAt: DateTime(2026, 10, 12),
        ),
      ],
    );

TimerSnapshot _roundTrip(TimerSnapshot snapshot) => TimerSnapshot.fromJson(
    jsonDecode(jsonEncode(snapshot.toJson())) as Map<String, Object?>);

void main() {
  test('new snapshots start with two empty, separate collections', () {
    final TimerSnapshot snapshot = _roundTrip(TimerSnapshot.initial());
    expect(snapshot.timers, isEmpty);
    expect(snapshot.batch.timers, isEmpty);
    expect(snapshot.labels, isEmpty);
    expect(snapshot.batch.labels, isEmpty);
    expect(snapshot.collection(TimerCollectionScope.home).scope,
        TimerCollectionScope.home);
    expect(snapshot.batch.scope, TimerCollectionScope.batch);
  });

  for (final TimerCollectionScope scope in TimerCollectionScope.values) {
    final TimerCollectionScope other = scope == TimerCollectionScope.home
        ? TimerCollectionScope.batch
        : TimerCollectionScope.home;

    void expectOnlyTargetChanged(TimerSnapshot before, TimerSnapshot after) {
      expect(
          after.collection(other).toJson(), before.collection(other).toJson());
      expect(after.history, same(before.history));
      expect(after.settings, same(before.settings));
    }

    test('$scope countdown creation changes only its own collection', () {
      final TimerSnapshot before = _snapshot();
      final TimerSnapshot after = before.withCollection(
          before.collection(scope).addTimer(_timer('新计时', id: 'new-id')));
      expect(after.collection(scope).timers, hasLength(2));
      expect(before.collection(scope).timers, hasLength(1));
      expectOnlyTargetChanged(before, after);
      expect(_roundTrip(after).toJson(), after.toJson());
    });

    test('$scope countdown deletion keeps the other copy of the same ID', () {
      final TimerSnapshot before = _snapshot();
      final TimerSnapshot after = before
          .withCollection(before.collection(scope).deleteTimer('same-id'));
      expect(after.collection(scope).timers, isEmpty);
      expectOnlyTargetChanged(before, after);
      expect(_roundTrip(after).toJson(), after.toJson());
    });

    test('$scope label creation ignores names stored in the other collection',
        () {
      final TimerSnapshot before = _snapshot().withCollection(
          _snapshot().collection(scope).copyWith(labels: <String>[]));
      final TimerSnapshot after =
          before.withCollection(before.collection(scope).addLabel(' 同名标签 '));
      expect(after.collection(scope).labels, <String>['同名标签']);
      expectOnlyTargetChanged(before, after);
    });

    test('$scope renaming a label keeps the other label unchanged', () {
      final TimerSnapshot before = _snapshot();
      final TimerSnapshot after = before
          .withCollection(before.collection(scope).renameLabel('同名标签', '新标签'));
      expect(after.collection(scope).labels, <String>['新标签']);
      expectOnlyTargetChanged(before, after);
      expect(_roundTrip(after).toJson(), after.toJson());
    });

    test('$scope deleting a label keeps the other label unchanged', () {
      final TimerSnapshot before = _snapshot();
      final TimerSnapshot after =
          before.withCollection(before.collection(scope).deleteLabel('同名标签'));
      expect(after.collection(scope).labels, isEmpty);
      expectOnlyTargetChanged(before, after);
      expect(_roundTrip(after).toJson(), after.toJson());
    });

    test('$scope default countdown deletion is scoped', () {
      final TimerSnapshot before = _snapshot();
      final String id = TimerDefaults.countdownTimersFor(scope).first.id;
      final TimerSnapshot after =
          before.withCollection(before.collection(scope).deleteTimer(id));
      expect(after.collection(scope).hiddenDefaultTimerIds, <String>[id]);
      expectOnlyTargetChanged(before, after);
      expect(_roundTrip(after).toJson(), after.toJson());
    });

    test('$scope default labels can be hidden, restored and renamed locally',
        () {
      final TimerSnapshot before = _snapshot();
      final String label = TimerDefaults.stopwatchLabelsFor(scope).first;
      final TimerSnapshot hidden =
          before.withCollection(before.collection(scope).deleteLabel(label));
      expect(hidden.collection(scope).visibleLabels, isNot(contains(label)));
      expectOnlyTargetChanged(before, hidden);
      final TimerSnapshot restored =
          hidden.withCollection(hidden.collection(scope).addLabel(label));
      expect(restored.collection(scope).visibleLabels, contains(label));
      expect(restored.collection(scope).labels, isNot(contains(label)));
      expectOnlyTargetChanged(before, restored);
      final TimerSnapshot renamed = restored.withCollection(
          restored.collection(scope).renameLabel(label, '默认项新名称'));
      expect(renamed.collection(scope).hiddenDefaultLabels, contains(label));
      expect(renamed.collection(scope).labels, contains('默认项新名称'));
      expectOnlyTargetChanged(before, renamed);
    });

    test('$scope label validation is local and leaves invalid edits unchanged',
        () {
      final TimerCollection collection = _snapshot().collection(scope);
      expect(collection.addLabel('同名标签'), same(collection));
      expect(collection.addLabel('  '), same(collection));
      expect(collection.renameLabel('不存在', '新标签'), same(collection));
      expect(collection.renameLabel('同名标签', '  '), same(collection));
      expect(
          collection.renameLabel(
              '同名标签', TimerDefaults.stopwatchLabelsFor(scope).first),
          same(collection));
    });
  }

  test('a name reserved by one page can be a custom label on the other page',
      () {
    final TimerCollection home =
        const TimerCollection(scope: TimerCollectionScope.home)
            .addLabel('新正计时');
    final TimerCollection batch =
        const TimerCollection(scope: TimerCollectionScope.batch).addLabel('阅读');
    expect(home.labels, <String>['新正计时']);
    expect(batch.labels, <String>['阅读']);
    expect(home.renameLabel('新正计时', '独立名称').labels, <String>['独立名称']);
    expect(batch.renameLabel('阅读', '独立名称').labels, <String>['独立名称']);
  });

  test('legacy shared data is copied without losing history or settings', () {
    final TimerSnapshot before = _snapshot().copyWith(
      hiddenDefaultTimerIds: <String>['default-batch-countdown'],
      hiddenDefaultLabels: <String>['阅读', '新正计时'],
    );
    final Map<String, Object?> legacy = before.toJson()..remove('batch');
    final TimerSnapshot migrated = TimerSnapshot.fromJson(legacy);
    expect(migrated.timers.single.toJson(), before.timers.single.toJson());
    expect(migrated.collection(TimerCollectionScope.home).toJson(),
        migrated.batch.toJson());
    expect(migrated.batch.timers, isNot(same(migrated.timers)));
    expect(migrated.batch.labels, isNot(same(migrated.labels)));
    expect(migrated.batch.hiddenDefaultTimerIds,
        isNot(same(migrated.hiddenDefaultTimerIds)));
    expect(migrated.batch.hiddenDefaultLabels,
        isNot(same(migrated.hiddenDefaultLabels)));
    expect(migrated.history.single.toJson(), before.history.single.toJson());
    expect(migrated.settings.toJson(), before.settings.toJson());
  });

  test('empty batch lists stay empty after repeated restarts', () {
    final Map<String, Object?> legacy = _snapshot().toJson()..remove('batch');
    TimerSnapshot snapshot = TimerSnapshot.fromJson(legacy);
    snapshot = snapshot.withCollection(
        snapshot.batch.deleteTimer('same-id').deleteLabel('同名标签'));
    for (int i = 0; i < 3; i++) {
      snapshot = _roundTrip(snapshot);
      expect(snapshot.batch.timers, isEmpty);
      expect(snapshot.batch.labels, isEmpty);
      expect(snapshot.timers, hasLength(1));
      expect(snapshot.labels, <String>['同名标签']);
    }
  });

  test('an explicit null batch field does not rerun legacy migration', () {
    final Map<String, Object?> json = _snapshot().toJson()..['batch'] = null;
    final TimerSnapshot snapshot = TimerSnapshot.fromJson(json);
    expect(snapshot.batch.timers, isEmpty);
    expect(snapshot.batch.labels, isEmpty);
    expect(snapshot.timers, hasLength(1));
  });
}
