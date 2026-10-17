import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timer_app/data/timer_repository.dart';
import 'package:timer_app/models/timer_models.dart';

// Record the SQL adapter's actual query/insert surface. These tests do not
// substitute the repository or rely on Android's unavailable test-host plugin.
class _SnapshotDatabase implements Database {
  _SnapshotDatabase({this.encoded});

  String? encoded;
  bool failWrites = false;
  int writes = 0;
  final List<String> executedSql = <String>[];

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedSql.add(sql);
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    expect(table, 'app_state');
    expect(columns, <String>['value']);
    expect(where, 'key = ?');
    expect(whereArgs, <Object?>['snapshot']);
    expect(limit, 1);
    return encoded == null
        ? <Map<String, Object?>>[]
        : <Map<String, Object?>>[
            <String, Object?>{'value': encoded}
          ];
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    expect(table, 'app_state');
    expect(values['key'], 'snapshot');
    expect(conflictAlgorithm, ConflictAlgorithm.replace);
    if (failWrites) {
      throw StateError('Simulated write failure');
    }
    encoded = values['value']! as String;
    writes++;
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'Unexpected database call: ${invocation.memberName}');
}

class _SnapshotDatabaseFactory implements DatabaseFactory {
  _SnapshotDatabaseFactory(this.database) : created = database.encoded != null;

  final _SnapshotDatabase database;
  bool created;
  int opens = 0;

  @override
  Future<String> getDatabasesPath() async => '/virtual-databases';

  @override
  Future<Database> openDatabase(String path,
      {OpenDatabaseOptions? options}) async {
    expect(path, endsWith('timer_app.db'));
    expect(options!.version, 1);
    opens++;
    if (!created) {
      await options.onCreate?.call(database, 1);
      created = true;
    }
    return database;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'Unexpected factory call: ${invocation.memberName}');
}

TimerSnapshot _snapshot() => TimerSnapshot.initial().copyWith(
      timers: <CreatedTimer>[
        CreatedTimer(
            id: 'home',
            name: '首页项目',
            seconds: 600,
            createdAt: DateTime(2026, 10, 12)),
      ],
      labels: <String>['首页标签'],
      batch: const TimerCollection(
        scope: TimerCollectionScope.batch,
        labels: <String>['批量标签'],
        hiddenDefaultTimerIds: <String>['default-batch-countdown'],
      ),
      settings: const TimerSettings(extendSeconds: 7),
      history: <TimerHistoryEntry>[
        TimerHistoryEntry(
          id: 'history',
          name: '阅读记录',
          mode: TimerRunMode.stopwatch,
          durationSeconds: 90,
          completedAt: DateTime(2026, 10, 12),
        ),
      ],
    );

void main() {
  test('SQLite creates the existing table and loads fresh separate collections',
      () async {
    final _SnapshotDatabase database = _SnapshotDatabase();
    final _SnapshotDatabaseFactory factory = _SnapshotDatabaseFactory(database);
    final SqliteTimerRepository repository =
        SqliteTimerRepository(factory: factory);
    final TimerSnapshot snapshot = await repository.load();
    expect(snapshot.timers, isEmpty);
    expect(snapshot.batch.timers, isEmpty);
    expect(database.writes, 0);
    expect(database.executedSql.single, startsWith('CREATE TABLE app_state'));
    await repository.load();
    expect(factory.opens, 1);
  });

  test(
      'SQLite preserves both collections across save and repository recreation',
      () async {
    final _SnapshotDatabase database = _SnapshotDatabase();
    final _SnapshotDatabaseFactory factory = _SnapshotDatabaseFactory(database);
    final SqliteTimerRepository repository =
        SqliteTimerRepository(factory: factory);
    final TimerSnapshot snapshot = _snapshot();
    await repository.save(snapshot);
    final SqliteTimerRepository restarted =
        SqliteTimerRepository(factory: factory);
    expect((await restarted.load()).toJson(), snapshot.toJson());
    expect(database.writes, 1);
    expect(factory.opens, 2);
  });

  test('SQLite migrates legacy data exactly once without removing old fields',
      () async {
    final Map<String, Object?> legacy = _snapshot().toJson()..remove('batch');
    final _SnapshotDatabase database =
        _SnapshotDatabase(encoded: jsonEncode(legacy));
    final _SnapshotDatabaseFactory factory = _SnapshotDatabaseFactory(database);
    final SqliteTimerRepository repository =
        SqliteTimerRepository(factory: factory);
    final TimerSnapshot migrated = await repository.load();
    expect(migrated.batch.toJson(),
        migrated.collection(TimerCollectionScope.home).toJson());
    expect(database.writes, 1);
    final Map<String, Object?> saved =
        jsonDecode(database.encoded!) as Map<String, Object?>;
    expect(saved.containsKey('batch'), isTrue);
    saved.remove('batch');
    expect(saved, legacy);
    expect(database.executedSql, isEmpty);
    await SqliteTimerRepository(factory: factory).load();
    expect(database.writes, 1);
  });

  test(
      'deleting migrated batch copies stays deleted after repository recreation',
      () async {
    final Map<String, Object?> legacy = _snapshot().toJson()..remove('batch');
    final _SnapshotDatabase database =
        _SnapshotDatabase(encoded: jsonEncode(legacy));
    final _SnapshotDatabaseFactory factory = _SnapshotDatabaseFactory(database);
    final SqliteTimerRepository repository =
        SqliteTimerRepository(factory: factory);
    final TimerSnapshot migrated = await repository.load();
    await repository.save(migrated.withCollection(
        migrated.batch.deleteTimer('home').deleteLabel('首页标签')));
    final TimerSnapshot restored =
        await SqliteTimerRepository(factory: factory).load();
    expect(restored.batch.timers, isEmpty);
    expect(restored.batch.labels, isEmpty);
    expect(restored.timers.single.name, '首页项目');
    expect(restored.labels, <String>['首页标签']);
    expect(restored.settings.toJson(), migrated.settings.toJson());
    expect(restored.history.single.toJson(), migrated.history.single.toJson());
    expect(database.writes, 2);
  });

  test('a failed migration leaves the legacy snapshot available for retry',
      () async {
    final String legacy = jsonEncode(_snapshot().toJson()..remove('batch'));
    final _SnapshotDatabase database = _SnapshotDatabase(encoded: legacy)
      ..failWrites = true;
    final _SnapshotDatabaseFactory factory = _SnapshotDatabaseFactory(database);
    await expectLater(SqliteTimerRepository(factory: factory).load(),
        throwsA(isA<StateError>()));
    expect(database.encoded, legacy);
    expect(database.writes, 0);
    database.failWrites = false;
    final TimerSnapshot migrated =
        await SqliteTimerRepository(factory: factory).load();
    expect(migrated.timers.single.name, '首页项目');
    expect(migrated.batch.timers.single.name, '首页项目');
    expect(database.writes, 1);
  });

  test('an existing empty batch collection is never populated from home',
      () async {
    final TimerSnapshot snapshot = _snapshot().copyWith(
        batch: const TimerCollection(scope: TimerCollectionScope.batch));
    final _SnapshotDatabase database =
        _SnapshotDatabase(encoded: jsonEncode(snapshot.toJson()));
    final TimerSnapshot loaded =
        await SqliteTimerRepository(factory: _SnapshotDatabaseFactory(database))
            .load();
    expect(loaded.batch.timers, isEmpty);
    expect(loaded.batch.labels, isEmpty);
    expect(loaded.timers.single.name, '首页项目');
    expect(database.writes, 0);
  });
}
