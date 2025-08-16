import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sensores.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE acelerometro (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x REAL, y REAL, z REAL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE giroscopio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        x REAL, y REAL, z REAL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE localizacao (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL, longitude REAL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> inserirAcelerometro(double x, double y, [double z = 0.0]) async {
    final db = await database;
    await db.insert('acelerometro', {'x': x, 'y': y, 'z': z});
  }

  Future<void> inserirGiroscopio(double x, double y, [double z = 0.0]) async {
    final db = await database;
    await db.insert('giroscopio', {'x': x, 'y': y, 'z': z});
  }

  Future<void> inserirLocalizacao(double lat, double lon) async {
    final db = await database;
    await db.insert('localizacao', {'latitude': lat, 'longitude': lon});
  }

  // Novo método para inserir múltiplos registros de uma vez em uma transação
  Future<void> inserirDadosSensores(
    List<Map<String, dynamic>> acelerometro,
    List<Map<String, dynamic>> giroscopio,
    List<Map<String, dynamic>> localizacao,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var data in acelerometro) {
        await txn.insert('acelerometro', data);
      }
      for (var data in giroscopio) {
        await txn.insert('giroscopio', data);
      }
      for (var data in localizacao) {
        await txn.insert('localizacao', data);
      }
    });
  }

  Future<Map<String, dynamic>> getLatestData() async {
    final db = await database;

    final accelList = await db.query(
      'acelerometro',
      orderBy: 'id DESC',
      limit: 1,
    );
    final gyroList = await db.query('giroscopio', orderBy: 'id DESC', limit: 1);
    final locList = await db.query('localizacao', orderBy: 'id DESC', limit: 1);

    final accelCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM acelerometro'),
        ) ??
        0;
    final gyroCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM giroscopio'),
        ) ??
        0;
    final locCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM localizacao'),
        ) ??
        0;

    return {
      'ultimo_acelerometro': accelList.isNotEmpty ? accelList.first : null,
      'ultimo_giroscopio': gyroList.isNotEmpty ? gyroList.first : null,
      'ultima_localizacao': locList.isNotEmpty ? locList.first : null,
      'total_acelerometro': accelCount,
      'total_giroscopio': gyroCount,
      'total_localizacao': locCount,
    };
  }

  Future<List<Map<String, dynamic>>> getDadosAcelerometro({
    int limite = 100,
  }) async {
    final db = await database;
    return await db.query(
      'acelerometro',
      orderBy: 'timestamp ASC',
      limit: limite,
    );
  }
}
