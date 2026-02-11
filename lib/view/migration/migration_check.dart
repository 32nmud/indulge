import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/database/database_engine.dart';
import 'migration_screen.dart';

/// Widget that checks if migration is needed and shows migration screen if so
class MigrationCheck extends StatefulWidget {
  final Widget child;

  const MigrationCheck({super.key, required this.child});

  @override
  State<MigrationCheck> createState() => _MigrationCheckState();
}

class _MigrationCheckState extends State<MigrationCheck> {
  late Future<bool> _migrationCheckFuture;

  @override
  void initState() {
    super.initState();
    _migrationCheckFuture = _checkMigration();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _migrationCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking database...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error checking database',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final needsMigration = snapshot.data ?? false;

        if (needsMigration) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _getDatabaseInfo(),
            builder: (context, dbSnapshot) {
              if (dbSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (dbSnapshot.hasError || !dbSnapshot.hasData) {
                return Scaffold(
                  body: Center(child: Text('Error: ${dbSnapshot.error}')),
                );
              }

              final dbInfo = dbSnapshot.data!;
              return MigrationScreen(
                database: dbInfo['database'] as Database,
                databasePath: dbInfo['path'] as String,
              );
            },
          );
        }

        // No migration needed, show the child
        return widget.child;
      },
    );
  }

  Future<bool> _checkMigration() async {
    try {
      final dbPath = join(await getDatabasesPath(), 'indulge.db');
      final db = await openDatabase(dbPath);
      final needsMigration = await DatabaseEngine.needsMigration(db, dbPath);
      return needsMigration;
    } catch (e) {
      print('Error checking migration: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getDatabaseInfo() async {
    final dbPath = join(await getDatabasesPath(), 'indulge.db');
    final db = await openDatabase(dbPath);
    return {'database': db, 'path': dbPath};
  }
}
