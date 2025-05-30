import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BusDatabase {
  static final BusDatabase instance = BusDatabase._init();
  static Database? _database;

  BusDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bus_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE buses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bus_number TEXT NOT NULL,
        number_plate TEXT NOT NULL,
        route TEXT NOT NULL,
        start_lat REAL NOT NULL,
        start_lng REAL NOT NULL,
        end_lat REAL NOT NULL,
        end_lng REAL NOT NULL
      )
    ''');
  }

  Future<int> addBus({
    required String busNumber,
    required String numberPlate,
    required String route,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    final db = await database;
    return await db.insert('buses', {
      'bus_number': busNumber,
      'number_plate': numberPlate,
      'route': route,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
    });
  }

  Future<List<Map<String, dynamic>>> getAllBuses() async {
    final db = await database;
    return await db.query('buses');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
