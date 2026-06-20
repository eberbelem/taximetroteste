import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../core/models/trip.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'trips';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'taximetro.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            fareTable TEXT NOT NULL,
            inicio TEXT NOT NULL,
            fim TEXT,
            distanciaTotalMetros REAL NOT NULL DEFAULT 0.0,
            tempoParadoSegundos REAL NOT NULL DEFAULT 0.0,
            tempoMovimentoSegundos REAL NOT NULL DEFAULT 0.0,
            status INTEGER NOT NULL DEFAULT 0,
            pontos TEXT NOT NULL DEFAULT '[]',
            sincronizado INTEGER NOT NULL DEFAULT 0,
            nf INTEGER NOT NULL DEFAULT 1,
            acumuladorDistancia REAL NOT NULL DEFAULT 0.0,
            acumuladorTempo REAL NOT NULL DEFAULT 0.0,
            tarifaAtiva INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_tableName ADD COLUMN nf INTEGER NOT NULL DEFAULT 1');
          await db.execute('ALTER TABLE $_tableName ADD COLUMN acumuladorDistancia REAL NOT NULL DEFAULT 0.0');
          await db.execute('ALTER TABLE $_tableName ADD COLUMN acumuladorTempo REAL NOT NULL DEFAULT 0.0');
          await db.execute('ALTER TABLE $_tableName ADD COLUMN tarifaAtiva INTEGER NOT NULL DEFAULT 1');
        }
      },
    );
  }

  Future<void> salvarTrip(Trip trip) async {
    final db = await database;
    final map = trip.toMap();
    map['sincronizado'] = 0;
    await db.insert(
      _tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> atualizarTrip(Trip trip) async {
    final db = await database;
    final map = trip.toMap();
    map['sincronizado'] = 0;
    await db.update(
      _tableName,
      map,
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<Trip?> recuperarTrip(String id) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Trip.fromMap(result.first);
  }

  Future<List<Trip>> listarTripsNaoSincronizados() async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: 'sincronizado = 0',
    );
    return result.map((map) => Trip.fromMap(map)).toList();
  }

  Future<List<Trip>> listarTodasTrips({int? limit}) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      orderBy: 'inicio DESC',
      limit: limit,
    );
    return result.map((map) => Trip.fromMap(map)).toList();
  }

  Future<void> marcarSincronizado(String id) async {
    final db = await database;
    await db.update(
      _tableName,
      {'sincronizado': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletarTrip(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> fechar() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
