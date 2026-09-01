import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/timer_models.dart';

abstract class TimerRepository {
  Future<TimerSnapshot> load();

  Future<void> save(TimerSnapshot snapshot);
}

class MemoryTimerRepository implements TimerRepository {
  MemoryTimerRepository([TimerSnapshot? initial])
      : _snapshot = initial ?? TimerSnapshot.initial();

  TimerSnapshot _snapshot;

  @override
  Future<TimerSnapshot> load() async => _snapshot;

  @override
  Future<void> save(TimerSnapshot snapshot) async {
    _snapshot = snapshot;
  }
}

class SqliteTimerRepository implements TimerRepository {
  SqliteTimerRepository({String databaseName = 'timer_app.db'})
      : _databaseName = databaseName;

  final String _databaseName;
  Database? _database;

  Future<Database> get _db async {
    final Database? existing = _database;
    if (existing != null) {
      return existing;
    }

    final String dbPath = path.join(await getDatabasesPath(), _databaseName);
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          'CREATE TABLE app_state (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
      },
    );
    return _database!;
  }

  @override
  Future<TimerSnapshot> load() async {
    final Database database = await _db;
    final List<Map<String, Object?>> rows = await database.query(
      'app_state',
      columns: <String>['value'],
      where: 'key = ?',
      whereArgs: <Object?>['snapshot'],
      limit: 1,
    );

    if (rows.isEmpty) {
      return TimerSnapshot.initial();
    }

    final Object? encoded = rows.first['value'];
    if (encoded is! String || encoded.isEmpty) {
      return TimerSnapshot.initial();
    }

    return TimerSnapshot.fromJson(
      jsonDecode(encoded) as Map<String, Object?>,
    );
  }

  @override
  Future<void> save(TimerSnapshot snapshot) async {
    final Database database = await _db;
    await database.insert(
      'app_state',
      <String, Object?>{
        'key': 'snapshot',
        'value': jsonEncode(snapshot.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
