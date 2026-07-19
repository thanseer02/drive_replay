import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:drive_tracker/core/constants.dart';
import 'package:drive_tracker/models/ride.dart';
import 'package:drive_tracker/models/ride_location.dart';
import 'package:drive_tracker/models/settings_model.dart';

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
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable Foreign Keys cascade delete
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Create rides table
    await db.execute('''
      CREATE TABLE rides (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startTime TEXT NOT NULL,
        endTime TEXT,
        maxSpeed REAL NOT NULL,
        averageSpeed REAL NOT NULL,
        distance REAL NOT NULL,
        drivingTime INTEGER NOT NULL,
        stopTime INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // 2. Create ride_locations table
    await db.execute('''
      CREATE TABLE ride_locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rideId INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        speed REAL NOT NULL,
        accuracy REAL NOT NULL,
        heading REAL NOT NULL DEFAULT 0.0,
        altitude REAL NOT NULL DEFAULT 0.0,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (rideId) REFERENCES rides (id) ON DELETE CASCADE
      )
    ''');

    // 3. Create settings table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        is_dark_mode INTEGER NOT NULL DEFAULT 0,
        use_metric INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Seed default settings row
    await db.insert('settings', {
      'id': 1,
      'is_dark_mode': 0,
      'use_metric': 1,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ride_locations ADD COLUMN heading REAL NOT NULL DEFAULT 0.0');
      await db.execute('ALTER TABLE ride_locations ADD COLUMN altitude REAL NOT NULL DEFAULT 0.0');
    }
  }

  // ==========================================
  // RIDE OPERATIONS
  // ==========================================

  Future<int> insertRide(Ride ride) async {
    final db = await database;
    return await db.insert('rides', ride.toMap());
  }

  Future<int> updateRide(Ride ride) async {
    if (ride.id == null) return 0;
    final db = await database;
    return await db.update(
      'rides',
      ride.toMap(),
      where: 'id = ?',
      whereArgs: [ride.id],
    );
  }

  Future<int> deleteRide(int id) async {
    final db = await database;
    return await db.delete(
      'rides',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Ride>> getAllRides() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rides',
      orderBy: 'startTime DESC',
    );
    return List.generate(maps.length, (i) => Ride.fromMap(maps[i]));
  }

  Future<Ride?> getRide(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rides',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    
    // Fetch locations for this ride
    final locations = await getLocationsForRide(id);
    return Ride.fromMap(maps.first, locations: locations);
  }

  Future<int> clearAllRides() async {
    final db = await database;
    return await db.delete('rides');
  }

  // ==========================================
  // RIDE LOCATION OPERATIONS
  // ==========================================

  Future<int> insertRideLocation(RideLocation location) async {
    final db = await database;
    return await db.insert('ride_locations', location.toMap());
  }

  Future<List<RideLocation>> getLocationsForRide(int rideId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ride_locations',
      where: 'rideId = ?',
      whereArgs: [rideId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => RideLocation.fromMap(maps[i]));
  }

  // ==========================================
  // SETTINGS OPERATIONS
  // ==========================================

  Future<SettingsModel> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (maps.isEmpty) {
      return SettingsModel(isDarkMode: false, useMetric: true);
    }
    return SettingsModel.fromMap(maps.first);
  }

  Future<int> updateSettings(SettingsModel settings) async {
    final db = await database;
    return await db.update(
      'settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
