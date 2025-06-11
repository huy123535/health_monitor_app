import 'package:connect_ble/models/sensor_data.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseServices {
  static Database? _db;
  static final DatabaseServices instance = DatabaseServices._constructor();

  final String _tableName = "vitals_measurements";
  final String _idColumn = "id";
  final String _timestampColumn = "timestamp";
  final String _heartRateColumn = "heart_rate";
  final String _spo2Column = "spo2";
  final String _temperatureColumn = "temperature";

  DatabaseServices._constructor();

  Future<Database> get database async {
    if(_db != null) return _db!;
    _db = await getDatabase();
    return _db!;
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, 'app_database.db');
    
    final database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) => _createDb(db),
    );
    return database;
  }

  Future<void> _createDb(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $_idColumn INTEGER PRIMARY KEY AUTOINCREMENT,
        $_timestampColumn TEXT NOT NULL,
        $_heartRateColumn INTEGER NULL,
        $_spo2Column INTEGER NULL,
        $_temperatureColumn REAL NULL
      )
    ''');
  }

  Future<void> insertSensorData(SensorData data) async {
    if (!data.hasValidData()) return; // Don't insert if no valid data
    
    final db = await database;
    try {
      await db.insert(
        _tableName,
        data.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Inserted data: ${data.toMap()}'); // Debug print
    } catch (e) {
      print('Error inserting data: $e'); // Debug print
      rethrow; // Re-throw to handle in UI
    }
  }

  // Get all measurements ordered by timestamp
  Future<List<SensorData>> getAllMeasurements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: '$_timestampColumn DESC',
    );

    return maps.map((map) => SensorData(
      heartRate: map[_heartRateColumn]?.toDouble(),
      spo2: map[_spo2Column]?.toDouble(),
      temperature: map[_temperatureColumn],
      timestamp: DateTime.parse(map[_timestampColumn]),
    )).toList();
  }

  // Delete all measurements
  Future<void> deleteAllMeasurements() async {
    final db = await database;
    await db.delete(_tableName);
  }

  // Delete a single measurement by timestamp
  Future<void> deleteMeasurement(DateTime timestamp) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: '$_timestampColumn = ?',
      whereArgs: [timestamp.toIso8601String()],
    );
  }

  // Get measurements within a date range
  Future<List<SensorData>> getMeasurementsInRange(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$_timestampColumn BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: '$_timestampColumn DESC',
    );

    return maps.map((map) => SensorData(
      heartRate: map[_heartRateColumn]?.toDouble(),
      spo2: map[_spo2Column]?.toDouble(),
      temperature: map[_temperatureColumn],
      timestamp: DateTime.parse(map[_timestampColumn]),
    )).toList();
  }
}