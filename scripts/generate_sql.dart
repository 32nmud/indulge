import 'dart:io';

/// Generates SQL from the DBML schema during the build process.
///
/// To run:
///   dart scripts/generate_sql.dart
///
/// The script will:
/// 1. Ensure the output directory exists.
/// 2. Run the DBML CLI to convert `schema.dbml` into `schema.sql`.
/// 3. Log success or errors.
void main() {
  // Paths relative to the location of this script.
  final dbmlPath = '../lib/domain/database/schema.dbml';
  final sqlDir = '../lib/database/sql';
  final sqlPath = '$sqlDir/schema.sql';

  // Create output directory if it doesn't exist.
  final dir = Directory(sqlDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
    print('📁 Created directory $sqlDir');
  }

  // Run the dbml-to-sql command.
  final result = Process.runSync(
    'dbml2sql',
    [dbmlPath, '-o', sqlPath, '-t', 'sqlite'],
    runInShell: true,
  );

  if (result.exitCode != 0) {
    stderr.writeln('❌ DBML to SQL conversion failed: ${result.stderr}');
    exit(result.exitCode);
  }

  print('✅ Generated SQL at $sqlPath');
}
