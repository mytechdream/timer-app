import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/timer_models.dart';

class TimerSnapshot {
  const TimerSnapshot({
    required this.timers,
    required this.history,
    required this.selectedPalette,
  });

  final List<SavedTimer> timers;
  final List<HistoryRecord> history;
  final int selectedPalette;
}

abstract class TimerRepository {
  Future<TimerSnapshot> load();

  Future<SavedTimer> insertTimer(SavedTimer timer);

  Future<HistoryRecord> insertHistory(HistoryRecord record);

  Future<void> saveSelectedPalette(int index);
}

class SqliteTimerRepository implements TimerRepository {
  static const _databaseName = 'timer_app.db';
  static const _databaseVersion = 1;
  static const _paletteSettingKey = 'selected_palette';

  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) return existing;

    final databasePath = await getDatabasesPath();
    final db = await openDatabase(
      path.join(databasePath, _databaseName),
      version: _databaseVersion,
      onCreate: (database, version) async {
        await database.execute('''
CREATE TABLE timers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  seconds INTEGER NOT NULL,
  created_at INTEGER NOT NULL
)
''');
        await database.execute('''
CREATE TABLE history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  label TEXT NOT NULL,
  seconds INTEGER NOT NULL,
  occurred_at INTEGER NOT NULL
)
''');
        await database.execute('''
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
      },
    );
    _database = db;
    return db;
  }

  @override
  Future<TimerSnapshot> load() async {
    final database = await _db;
    final timerRows = await database.query('timers', orderBy: 'id ASC');
    final historyRows =
        await database.query('history', orderBy: 'occurred_at DESC, id DESC');
    final selectedPalette = await _loadSelectedPalette(database);

    return TimerSnapshot(
      timers: timerRows.map(_timerFromRow).toList(),
      history: historyRows.map(_historyFromRow).toList(),
      selectedPalette: selectedPalette,
    );
  }

  @override
  Future<SavedTimer> insertTimer(SavedTimer timer) async {
    final database = await _db;
    final id = await database.insert('timers', {
      'name': timer.name,
      'seconds': timer.seconds,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return timer.copyWith(id: id);
  }

  @override
  Future<HistoryRecord> insertHistory(HistoryRecord record) async {
    final database = await _db;
    final id = await database.insert('history', {
      'type': record.type,
      'label': record.label,
      'seconds': record.seconds,
      'occurred_at': record.date.millisecondsSinceEpoch,
    });
    return record.copyWith(id: id);
  }

  @override
  Future<void> saveSelectedPalette(int index) async {
    final database = await _db;
    await database.insert(
      'settings',
      {'key': _paletteSettingKey, 'value': '$index'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> _loadSelectedPalette(Database database) async {
    final rows = await database.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_paletteSettingKey],
      limit: 1,
    );
    if (rows.isEmpty) return 1;
    return int.tryParse(rows.first['value'] as String) ?? 1;
  }

  SavedTimer _timerFromRow(Map<String, Object?> row) {
    return SavedTimer(
      id: row['id'] as int,
      name: row['name'] as String,
      seconds: row['seconds'] as int,
    );
  }

  HistoryRecord _historyFromRow(Map<String, Object?> row) {
    return HistoryRecord(
      id: row['id'] as int,
      type: row['type'] as String,
      label: row['label'] as String,
      seconds: row['seconds'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(row['occurred_at'] as int),
    );
  }
}

class MemoryTimerRepository implements TimerRepository {
  MemoryTimerRepository({
    List<SavedTimer> timers = const [],
    List<HistoryRecord> history = const [],
    int selectedPalette = 1,
  })  : _timers = List.of(timers),
        _history = List.of(history),
        _selectedPalette = selectedPalette;

  final List<SavedTimer> _timers;
  final List<HistoryRecord> _history;
  int _selectedPalette;
  int _nextTimerId = 1;
  int _nextHistoryId = 1;

  @override
  Future<TimerSnapshot> load() async {
    return TimerSnapshot(
      timers: List.of(_timers),
      history: List.of(_history),
      selectedPalette: _selectedPalette,
    );
  }

  @override
  Future<SavedTimer> insertTimer(SavedTimer timer) async {
    final saved = timer.copyWith(id: _nextTimerId++);
    _timers.add(saved);
    return saved;
  }

  @override
  Future<HistoryRecord> insertHistory(HistoryRecord record) async {
    final saved = record.copyWith(id: _nextHistoryId++);
    _history.insert(0, saved);
    return saved;
  }

  @override
  Future<void> saveSelectedPalette(int index) async {
    _selectedPalette = index;
  }
}
