import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'database_seed.dart';

class DatabaseEngine {
  static Future<Database> buildLocalConnection() async {
    final dbPath = join(await getDatabasesPath(), 'indulge.db');

    final database = await openDatabase(
      dbPath,
      onCreate: (db, version) async {
        // Load the full SQL schema from the bundled asset
        final schemaFile = await rootBundle.loadString('assets/sql/schema.sql');
        final DatabaseSeed seeder = DatabaseSeed(db: db);

        // SQLite in sqflite only supports a single statement per execute call.
        // Split the file into individual statements and execute them one by one.
        final statements = schemaFile
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        final batch = db.batch();
        for (var stmt in statements) {
          batch.execute(stmt);
        }
        await batch.commit(noResult: true);

        await seeder.loadSeeds();
      },
      version: 1,
    );

    return database;
  }
}
