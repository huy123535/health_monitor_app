import 'package:connect_ble/models/data.dart';
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

  Future<Database> get database async{
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
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE $_tableName (
            $_idColumn INTEGER PRIMARY KEY AUTOINCREMENT,
            $_timestampColumn TEXT NOT NULL,
            $_heartRateColumn INTEGER NOT NULL,
            $_spo2Column INTEGER NOT NULL,
            $_temperatureColumn REAL NOT NULL
          )
        ''');
      },
    );
    return database;
  }

  Future<void> insertData(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      _tableName,
      {
        _timestampColumn: data['timestamp'],
        _heartRateColumn: data['heart_rate'],
        _spo2Column: data['spo2'],
        _temperatureColumn: data['temperature'],
      },
    );
  }

  Future<List<Data>?> getAllData() async {
    final db = await database;
    final data = await db.query(_tableName);
    print(data);
    List<Data> dataList = data.map((d) => Data(
      id: d[_idColumn] as int,
      timestamp: d[_timestampColumn] as String,
      heartRate: d[_heartRateColumn] as int,
      spo2: d[_spo2Column] as int,
      temperature: d[_temperatureColumn] as double,
    )).toList();
    return dataList;
  }

  // Method to insert test data
  Future<void> insertTestData() async {
    await insertData({
      'timestamp': DateTime.now().toString(),
      'heart_rate': 72,
      'spo2': 98,
      'temperature': 36.5,
    });
    print('Test data inserted successfully!');
  }

  void deleteData(int id) async {
    final db = await database;
    await db.delete(
      _tableName, 
      where: '$_idColumn = ?', 
      whereArgs: [
        id,
      ],
    );
  }
}