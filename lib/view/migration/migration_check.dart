import 'dart:io';
import 'package:flutter/material.dart';
import 'package:indulge/domain/database/database_engine.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Widget that checks if JSON migration is needed and shows progress UI if so.
/// Schema-only migration (creating new tables) happens silently before runApp.
class MigrationCheck extends StatefulWidget {
  final Widget child;

  const MigrationCheck({super.key, required this.child});

  @override
  State<MigrationCheck> createState() => _MigrationCheckState();
}

class _MigrationCheckState extends State<MigrationCheck> {
  late Future<_MigrationState> _checkFuture;

  @override
  void initState() {
    super.initState();
    _checkFuture = _checkJsonMigration();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MigrationState>(
      future: _checkFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing database...'),
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
                      'Error preparing database',
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _checkFuture = _checkJsonMigration();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final state = snapshot.data!;

        // If JSON migration is needed, show progress UI
        if (state.needsJsonMigration) {
          return _JsonMigrationScreen(
            database: state.database!,
            onComplete: () {
              setState(() {
                _checkFuture = Future.value(
                  _MigrationState(needsJsonMigration: false),
                );
              });
            },
          );
        }

        // No JSON migration needed, show the app
        return widget.child;
      },
    );
  }

  Future<_MigrationState> _checkJsonMigration() async {
    final dbPath = join(await getDatabasesPath(), 'indulge.db');
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      return _MigrationState(needsJsonMigration: false);
    }

    // Open database - schema migration happens via onUpgrade in main.dart
    final db = await openDatabase(dbPath);

    // Check if JSON migration is needed
    final needsJsonMigration = await DatabaseEngine.needsJsonMigration(
      db,
      dbPath,
    );

    return _MigrationState(
      needsJsonMigration: needsJsonMigration,
      database: db,
    );
  }
}

class _MigrationState {
  final bool needsJsonMigration;
  final Database? database;

  _MigrationState({required this.needsJsonMigration, this.database});
}

/// Progress screen shown during JSON migration (v1 -> v2)
class _JsonMigrationScreen extends StatefulWidget {
  final Database database;
  final VoidCallback onComplete;

  const _JsonMigrationScreen({
    required this.database,
    required this.onComplete,
  });

  @override
  State<_JsonMigrationScreen> createState() => _JsonMigrationScreenState();
}

class _JsonMigrationScreenState extends State<_JsonMigrationScreen> {
  String _statusMessage = 'Preparing migration...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _runMigration();
  }

  Future<void> _runMigration() async {
    try {
      final dbPath = join(await getDatabasesPath(), 'indulge.db');

      final result = await DatabaseEngine.migrateIfNeeded(
        widget.database,
        dbPath,
        onProgress: (table, current, total, message) {
          if (mounted) {
            setState(() {
              _progress = total > 0 ? current / total : 0.0;
              _statusMessage = message;
            });
          }
        },
      );

      if (mounted) {
        if (result != null && result.success) {
          widget.onComplete();
        } else {
          setState(() {
            _statusMessage = 'Migration failed: ${result?.error}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upgrade, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Upgrading Database',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              if (_progress > 0)
                Column(
                  children: [
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 8),
                    Text('${(_progress * 100).toInt()}%'),
                  ],
                )
              else
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
