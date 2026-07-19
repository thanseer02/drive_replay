import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:drive_tracker/core/constants.dart';
import 'package:drive_tracker/models/drive.dart';

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE drives (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        distance REAL NOT NULL,
        start_location TEXT NOT NULL,
        end_location TEXT NOT NULL,
        notes TEXT NOT NULL
      )
    ''');
  }

  // CRUD operation: Insert
  Future<int> insertDrive(Drive drive) async {
    final db = await database;
    return await db.insert('drives', drive.toMap());
  }

  // CRUD operation: Read all
  Future<List<Drive>> getAllDrives() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'drives',
      orderBy: 'start_time DESC',
    );
    return List.generate(maps.length, (i) => Drive.fromMap(maps[i]));
  }

  // CRUD operation: Delete
  Future<int> deleteDrive(int id) async {
    final db = await database;
    return await db.delete(
      'drives',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operation: Clear all (for debugging/resetting)
  Future<int> clearAllDrives() async {
    final db = await database;
    return await db.delete('drives');
  }
}
