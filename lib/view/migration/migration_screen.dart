import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:logging/logging.dart';
import '../../domain/database/database_engine.dart';

/// Simple migration UI that shows progress without technical details
class MigrationScreen extends StatefulWidget {
  final Database database;
  final String databasePath;
  final VoidCallback onComplete;

  const MigrationScreen({
    super.key,
    required this.database,
    required this.databasePath,
    required this.onComplete,
  });

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  static final Logger _logger = Logger('MigrationScreen');

  // Migration state
  bool _isRunning = false;
  bool _isComplete = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Progress tracking (0.0 to 1.0)
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Start migration automatically when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMigration();
    });
  }

  Future<void> _startMigration() async {
    setState(() {
      _isRunning = true;
      _hasError = false;
      _errorMessage = '';
      _progress = 0.0;
    });

    _logger.info('Starting database migration');

    try {
      final result = await DatabaseEngine.migrateIfNeeded(
        widget.database,
        widget.databasePath,
        onProgress: _onProgress,
      );

      if (result == null) {
        // No migration needed
        _logger.info('No migration needed - database is up to date');
        setState(() {
          _isComplete = true;
          _isRunning = false;
          _progress = 1.0;
        });
      } else if (result.success) {
        // Migration succeeded
        _logger.info(
          'Migration completed successfully: '
          '${result.totalMigrated} migrated, '
          '${result.totalSkipped} skipped, '
          '${result.totalErrors} errors, '
          'duration: ${result.duration.inSeconds}s',
        );

        setState(() {
          _isComplete = true;
          _isRunning = false;
          _progress = 1.0;
        });
      } else {
        // Migration failed
        final error = result.error ?? 'Unknown error occurred';
        _logger.severe('Migration failed: $error');

        setState(() {
          _isRunning = false;
          _hasError = true;
          _errorMessage = error;
        });
      }
    } catch (e, stackTrace) {
      _logger.severe('Migration failed with exception', e, stackTrace);

      setState(() {
        _isRunning = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _onProgress(String tableName, int current, int total, String status) {
    // Calculate overall progress (4 tables total)
    final tableProgress = current / 4.0;

    _logger.fine('Migration progress: $tableName ($current/$total) - $status');

    setState(() {
      _progress = tableProgress;
    });
  }

  void _retry() {
    _logger.info('Retrying migration');
    setState(() {
      _progress = 0.0;
    });
    _startMigration();
  }

  void _continue() {
    _logger.info('Migration complete, continuing to app');
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Icon(
                _hasError
                    ? Icons.error_outline
                    : _isComplete
                    ? Icons.check_circle_outline
                    : Icons.sync,
                size: 80,
                color: _hasError
                    ? Theme.of(context).colorScheme.error
                    : _isComplete
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                _hasError
                    ? 'Update Failed'
                    : _isComplete
                    ? 'Update Complete'
                    : 'Updating App',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                _hasError
                    ? 'An error occurred while updating the app. Please try again.'
                    : _isComplete
                    ? 'Your app has been successfully updated!'
                    : 'Please wait while we update your app...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Progress bar or actions
              if (_isRunning) ...[
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Text(
                  '${(_progress * 100).toInt()}%',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please do not close the app',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_hasError) ...[
                // Error details (collapsible)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Error Details',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _continue,
                        icon: const Icon(Icons.close),
                        label: const Text('Exit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (_isComplete) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _continue,
                    icon: const Icon(Icons.check),
                    label: const Text('Continue'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
