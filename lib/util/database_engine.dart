import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseEngine {
  static Future<Database> buildLocalConnection() async {
    Database database = await openDatabase(
      join(await getDatabasesPath(), "indulge.db"),
      onCreate: (db, version) {
        return db.execute(
            'CREATE TABLE "sexual_encounter" ("id" TEXT NOT NULL UNIQUE, "location"	TEXT, "overallEnjoyment" INTEGER, "note" TEXT, "personIds" TEXT NOT NULL, "encounterDate" TEXT NOT NULL, PRIMARY KEY("id"))');
      },
      version: 1,
    );

    // await database.execute(
        // 'INSERT INTO sexual_encounter VALUES (\'1\', NULL, 1, NULL, \'["asdf", "sdfg", "fghj"]\', \'2025-05-19\'), (\'2\', NULL, 1, NULL, \'["asdf", "sdfg", "fghj"]\', \'2025-05-22\'), (\'3\', NULL, 1, NULL, \'["asdf", "sdfg", "fghj"]\', \'2025-05-19\')');

    return database;
  }
}
