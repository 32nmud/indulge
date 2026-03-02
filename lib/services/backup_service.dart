import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/data/repositories/sexual_event_repository.dart';
import 'package:indulge/data/repositories/clinical_event_repository.dart';
import 'package:indulge/domain/database/migration/migration_service.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class BackupService {
  final Logger _logger = Logger('BackupService');
  final SexualEventRepository sexualRepo;
  final ClinicalEventRepository clinicalRepo;

  BackupService(this.sexualRepo, this.clinicalRepo);

  /// Unwrap common JSON envelope shapes used by backups/exports.
  /// Some backup/export files wrap the model under keys like `data`, `document`,
  /// `payload`, `item`, or `body`. This helper returns the inner model map when
  /// such an envelope is detected, otherwise it returns the original map.
  Map<String, dynamic> _unwrapJsonEnvelope(Map<String, dynamic> json) {
    final candidate = Map<String, dynamic>.from(json);

    // Common wrapper keys that may contain the real model
    const wrapperKeys = ['data', 'document', 'payload', 'item', 'body'];

    for (final key in wrapperKeys) {
      if (candidate.containsKey(key) &&
          candidate[key] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(
          candidate[key] as Map<String, dynamic>,
        );
      }
    }

    // Handle nested envelope patterns like { data: { resource: { ... } } }
    if (candidate.containsKey('data') && candidate['data'] is Map) {
      final inner = candidate['data'] as Map;
      if (inner.containsKey('resource') && inner['resource'] is Map) {
        return Map<String, dynamic>.from(
          inner['resource'] as Map<String, dynamic>,
        );
      }
    }

    // No envelope detected; return original
    return candidate;
  }

  /// Exports all data to a zip file and allows the user to save it.
  Future<void> exportData() async {
    try {
      _logger.info('Starting data export');

      // 1. Fetch all data
      final events = await sexualRepo.getAllEvents();
      final clinicalEvents = await clinicalRepo.getAllEvents();
      final persons = await sexualRepo.getAllPersons();
      final categories = await sexualRepo.getAllSexualActivityCategories();
      final activities = await sexualRepo.getAllSexualActivities();

      // 2. Create temporary directory for staging files
      final tempDir = await getTemporaryDirectory();
      final backupDir = Directory(p.join(tempDir.path, 'backup_staging'));
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
      await backupDir.create();

      // 3. Write JSON files to respective directories
      await _writeFiles<SexualEvent>(
        backupDir,
        'sexual_events',
        events,
        (e) => e.id,
        (e) => e.toJson(),
      );

      await _writeFiles<ClinicalEvent>(
        backupDir,
        'clinical_events',
        clinicalEvents,
        (c) => c.id,
        (c) => c.toJson(),
      );

      await _writeFiles<Person>(
        backupDir,
        'persons',
        persons,
        (p) => p.id,
        (p) => p.toJson(),
      );

      await _writeFiles<SexualActivityCategory>(
        backupDir,
        'categories',
        categories,
        (c) => c.id,
        (c) => c.toJson(),
      );

      await _writeFiles<SexualActivity>(
        backupDir,
        'activities',
        activities,
        (a) => a.id,
        (a) => a.toJson(),
      );

      // Add metadata file
      final metadata = {
        'version': '1.1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '0.3.0-beta', // TODO: Get from package info
        'modelVersion': 3,
      };
      final metadataFile = File(p.join(backupDir.path, 'metadata.json'));
      await metadataFile.writeAsString(jsonEncode(metadata));

      // 4. Create ZIP archive
      final timestamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final zipFileName = 'indulge_backup_$timestamp.zip';
      final zipFile = File(p.join(tempDir.path, zipFileName));

      final encoder = ZipFileEncoder();
      encoder.create(zipFile.path);

      // Add all subdirectories to the zip
      // We use filename parameter to ensure relative paths in the zip
      await encoder.addDirectory(
        Directory(p.join(backupDir.path, 'sexual_events')),
        includeDirName: true,
      );
      await encoder.addDirectory(
        Directory(p.join(backupDir.path, 'clinical_events')),
        includeDirName: true,
      );
      await encoder.addDirectory(
        Directory(p.join(backupDir.path, 'persons')),
        includeDirName: true,
      );
      await encoder.addDirectory(
        Directory(p.join(backupDir.path, 'categories')),
        includeDirName: true,
      );
      await encoder.addDirectory(
        Directory(p.join(backupDir.path, 'activities')),
        includeDirName: true,
      );
      await encoder.addFile(metadataFile, 'metadata.json');

      encoder.close();

      // 5. Prompt user to save the file
      if (!kIsWeb) {
        if (Platform.isAndroid || Platform.isIOS) {
          final params = SaveFileDialogParams(
            sourceFilePath: zipFile.path,
            fileName: zipFileName,
          );
          final filePath = await FlutterFileDialog.saveFile(params: params);

          if (filePath != null) {
            _logger.info('Backup saved to: $filePath');
          } else {
            _logger.info('User dismissed save dialog');
          }
        } else {
          // Desktop behavior
          String? outputFile = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Backup',
            fileName: zipFileName,
            bytes: await zipFile.readAsBytes(),
          );

          if (outputFile != null) {
            final savedFile = File(outputFile);
            if (!await savedFile.exists()) {
              await zipFile.copy(outputFile);
            }
            _logger.info('Backup saved to: $outputFile');
          } else {
            _logger.info('User cancelled save dialog');
          }
        }
      }

      // Cleanup
      await backupDir.delete(recursive: true);
      // Note: We keep the zip file in temp because share_plus might need it asynchronously
      // For a robust solution, we might want to clean it up later or rely on OS temp cleanup
    } catch (e, stackTrace) {
      _logger.severe('Export failed', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _writeFiles<T>(
    Directory baseDir,
    String subDirName,
    List<T> items,
    String Function(T) getId,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final dir = Directory(p.join(baseDir.path, subDirName));
    await dir.create();

    // Map directory name to a resourceType used during import/migration
    String _resourceTypeFromDir(String name) {
      switch (name) {
        case 'sexual_events':
          return 'SexualEvent';
        case 'clinical_events':
          return 'ClinicalEvent';
        case 'persons':
          return 'Person';
        case 'categories':
          return 'SexualActivityCategory';
        case 'activities':
          return 'SexualActivity';
        default:
          return name;
      }
    }

    final resourceType = _resourceTypeFromDir(subDirName);

    for (final item in items) {
      final file = File(p.join(dir.path, '${getId(item)}.json'));
      // Pretty print JSON and include resourceType/version so imports can migrate reliably
      final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(
        toJson(item),
      );
      jsonMap['resourceType'] = resourceType;
      jsonMap['version'] = 3;
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonMap);
      await file.writeAsString(jsonString);
    }
  }

  /// Imports data from a zip file selected by the user or specified by path (for tests).
  /// Returns a stream of progress messages.
  ///
  /// If `zipFilePath` is provided the FilePicker dialog is skipped and the
  /// provided file path is used directly (this is useful for unit tests).
  Stream<String> importData({String? zipFilePath}) async* {
    File? zipFile;
    Directory? tempDir;

    // simple counters and error aggregation
    var importedCount = 0;
    var skippedCount = 0;

    try {
      // 1. Use provided path (test helper) or pick file via FilePicker
      if (zipFilePath == null) {
        // Pick file
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['zip'],
          allowMultiple: false,
        );

        if (result == null || result.files.isEmpty) {
          yield 'Import cancelled';
          return;
        }

        final path = result.files.single.path;
        if (path == null) {
          throw Exception('Could not determine file path');
        }

        zipFile = File(path);
      } else {
        zipFile = File(zipFilePath);
        if (!await zipFile.exists()) {
          throw Exception('Provided backup file does not exist: $zipFilePath');
        }
      }

      // zipFile is already set above (either from FilePicker result or the provided zipFilePath)
      yield 'Reading backup file...';

      // 2. Extract ZIP
      // Use the system temp directory when a zipFilePath is provided (tests), to avoid using
      // path_provider which requires platform binding initialization.
      if (zipFilePath != null) {
        tempDir = Directory.systemTemp;
      } else {
        tempDir = await getTemporaryDirectory();
      }
      final extractionDir = Directory(
        p.join(
          tempDir.path,
          'import_staging_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await extractionDir.create();

      _logger.info('Extracting zip to ${extractionDir.path}');

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(p.join(extractionDir.path, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(
            p.join(extractionDir.path, filename),
          ).create(recursive: true);
        }
      }

      // 3. Process each category
      final List<String> importErrors = [];
      int failedCount = 0;

      // -- Categories --
      yield 'Importing categories...';
      final categoriesDir = Directory(p.join(extractionDir.path, 'categories'));
      if (await categoriesDir.exists()) {
        await for (final file in categoriesDir.list()) {
          if (file is File && file.path.endsWith('.json')) {
            try {
              final content = await file.readAsString();
              var json = jsonDecode(content) as Map<String, dynamic>;
              // Unwrap envelope if the JSON uses an outer envelope shape.
              json = _unwrapJsonEnvelope(json);
              final resourceType =
                  (json['resourceType'] as String?) ?? 'SexualActivityCategory';
              // Use MigrationService to ensure model is at current version
              try {
                final migrated =
                    await MigrationService.migrateIfNeeded<dynamic>(
                      json,
                      resourceType,
                    );
                if (migrated is SexualActivityCategory) {
                  await sexualRepo.saveActivityCategory(migrated);
                } else if (migrated is Map<String, dynamic>) {
                  final item = SexualActivityCategory.fromJson(migrated);
                  await sexualRepo.saveActivityCategory(item);
                } else {
                  // Best-effort cast for types exported from other modules
                  await sexualRepo.saveActivityCategory(
                    migrated as SexualActivityCategory,
                  );
                }
                importedCount++;
              } catch (e, st) {
                // Defensive fallback: when migration fails (missing migrator or other),
                // attempt to salvage by deserializing the JSON directly and saving it.
                _logger.warning(
                  'Migration failed for category ${file.path}, attempting fallback: $e',
                  e,
                  st,
                );
                try {
                  // Attempt direct deserialization. Ensure version metadata to avoid
                  // repeated migration attempts downstream.
                  json['version'] = ModelVersionMigration.currentVersion;
                  final fallback = SexualActivityCategory.fromJson(json);
                  await sexualRepo.saveActivityCategory(fallback);
                  importedCount++;
                } catch (e2, st2) {
                  final msg =
                      'Failed to import category file ${file.path} even after fallback: $e2';
                  _logger.warning(msg, e2, st2);
                  importErrors.add(msg);
                  failedCount++;
                }
              }
            } catch (e, st) {
              final msg = 'Failed to import category file ${file.path}: $e';
              _logger.warning(msg, e, st);
              importErrors.add(msg);
              failedCount++;
            }
          }
        }
      }

      // -- Activities (legacy) --
      // Standalone SexualActivity records are no longer supported. Activities
      // are now embedded directly inside their SexualActivityCategory JSON blob
      // and are imported as part of the categories step below. Any legacy
      // /activities directory in an older backup is intentionally skipped.
      final activitiesDir = Directory(p.join(extractionDir.path, 'activities'));
      if (await activitiesDir.exists()) {
        _logger.info(
          'Skipping legacy activities directory — activities are now embedded '
          'in categories and will be imported with them.',
        );
      }

      // -- Persons --
      yield 'Importing contacts...';
      final personsDir = Directory(p.join(extractionDir.path, 'persons'));
      if (await personsDir.exists()) {
        await for (final file in personsDir.list()) {
          if (file is File && file.path.endsWith('.json')) {
            try {
              final content = await file.readAsString();
              var json = jsonDecode(content) as Map<String, dynamic>;
              // Unwrap envelope if the JSON uses an outer envelope shape.
              json = _unwrapJsonEnvelope(json);
              final resourceType =
                  (json['resourceType'] as String?) ?? 'Person';
              try {
                // Detailed diagnostic logging to help understand why a Person may be
                // mis-detected as v1 instead of v2. Log the file path, declared
                // version (if present), the MigrationService-detected version, and
                // the top-level keys present in the JSON payload.
                try {
                  final declaredVersion = json['version'] ?? 'missing';
                  final detectedVersion = MigrationService.getVersion(json);
                  _logger.fine(
                    'Importing person file: ${file.path} — declaredVersion=$declaredVersion, '
                    'detectedVersion=$detectedVersion, keys=${json.keys.toList()}',
                  );
                } catch (diagErr, diagSt) {
                  // Non-fatal: log diagnostics failure but continue
                  _logger.warning(
                    'Failed to produce person diagnostics for ${file.path}: $diagErr',
                    diagErr,
                    diagSt,
                  );
                }

                final migrated =
                    await MigrationService.migrateIfNeeded<dynamic>(
                      json,
                      resourceType,
                    );

                Person item;
                if (migrated is Person) {
                  item = migrated;
                  _logger.fine(
                    'MigrationService returned Person instance for ${file.path} (id=${item.id})',
                  );
                } else if (migrated is Map<String, dynamic>) {
                  item = Person.fromJson(migrated);
                  _logger.fine(
                    'MigrationService returned Map for ${file.path}; deserialized to Person id=${item.id}',
                  );
                } else {
                  item = migrated as Person;
                  _logger.fine(
                    'MigrationService returned object for ${file.path}; cast to Person id=${item.id}',
                  );
                }

                // Skip anonymous if it exists in backup (it should exist in DB)
                if (item.id != 'anonymous') {
                  await sexualRepo.savePerson(item);
                  importedCount++;
                } else {
                  skippedCount++;
                }
              } catch (e, st) {
                // Log the migration failure with extra context (file keys and a small preview)
                try {
                  final previewKeys = json.keys.take(8).toList();
                  _logger.warning(
                    'Migration failed for person ${file.path}: $e — keys (first 8): $previewKeys',
                    e,
                    st,
                  );
                } catch (_) {
                  _logger.warning(
                    'Migration failed for person ${file.path}: $e',
                    e,
                    st,
                  );
                }

                // Attempt fallback: coerce to current version metadata and deserialize directly.
                try {
                  _logger.fine(
                    'Attempting direct Person.fromJson fallback for ${file.path}',
                  );
                  json['version'] = ModelVersionMigration.currentVersion;
                  final fallback = Person.fromJson(json);
                  if (fallback.id != 'anonymous') {
                    await sexualRepo.savePerson(fallback);
                    importedCount++;
                    _logger.info(
                      'Fallback succeeded for person ${file.path} -> id=${fallback.id}',
                    );
                  } else {
                    skippedCount++;
                    _logger.fine(
                      'Fallback produced anonymous person for ${file.path}; skipped',
                    );
                  }
                } catch (e2, st2) {
                  final msg =
                      'Failed to import person file ${file.path} even after fallback: $e2';
                  _logger.warning(msg, e2, st2);
                  importErrors.add(msg);
                  failedCount++;
                }
              }
            } catch (e, st) {
              final msg = 'Failed to import person file ${file.path}: $e';
              _logger.warning(msg, e, st);
              importErrors.add(msg);
              failedCount++;
            }
          }
        }
      }

      // -- Clinical Events --
      yield 'Importing clinical events...';
      final clinicalDir = Directory(
        p.join(extractionDir.path, 'clinical_events'),
      );
      if (await clinicalDir.exists()) {
        await for (final file in clinicalDir.list()) {
          if (file is File && file.path.endsWith('.json')) {
            try {
              final content = await file.readAsString();
              var json = jsonDecode(content) as Map<String, dynamic>;
              // Unwrap envelope if the JSON uses an outer envelope shape.
              json = _unwrapJsonEnvelope(json);
              final resourceType =
                  (json['resourceType'] as String?) ?? 'ClinicalEvent';
              try {
                final migrated =
                    await MigrationService.migrateIfNeeded<dynamic>(
                      json,
                      resourceType,
                    );
                if (migrated is ClinicalEvent) {
                  await clinicalRepo.save(migrated);
                } else if (migrated is Map<String, dynamic>) {
                  final item = ClinicalEvent.fromJson(migrated);
                  await clinicalRepo.save(item);
                } else {
                  await clinicalRepo.save(migrated as ClinicalEvent);
                }
                importedCount++;
              } catch (e, st) {
                _logger.warning(
                  'Migration failed for clinical event ${file.path}, attempting fallback: $e',
                  e,
                  st,
                );
                try {
                  json['version'] = ModelVersionMigration.currentVersion;
                  final fallback = ClinicalEvent.fromJson(json);
                  await clinicalRepo.save(fallback);
                  importedCount++;
                } catch (e2, st2) {
                  final msg =
                      'Failed to import clinical event file ${file.path} even after fallback: $e2';
                  _logger.warning(msg, e2, st2);
                  importErrors.add(msg);
                  failedCount++;
                }
              }
            } catch (e, st) {
              final msg =
                  'Failed to import clinical event file ${file.path}: $e';
              _logger.warning(msg, e, st);
              importErrors.add(msg);
              failedCount++;
            }
          }
        }
      }

      // -- Events --
      yield 'Importing events...';
      final eventsDir = Directory(p.join(extractionDir.path, 'sexual_events'));
      if (await eventsDir.exists()) {
        await for (final file in eventsDir.list()) {
          if (file is File && file.path.endsWith('.json')) {
            try {
              final content = await file.readAsString();
              var json = jsonDecode(content) as Map<String, dynamic>;
              // Unwrap envelope if the JSON uses an outer envelope shape.
              json = _unwrapJsonEnvelope(json);
              final resourceType =
                  (json['resourceType'] as String?) ?? 'SexualEvent';
              try {
                final migrated =
                    await MigrationService.migrateIfNeeded<dynamic>(
                      json,
                      resourceType,
                    );
                if (migrated is SexualEvent) {
                  await sexualRepo.save(migrated);
                } else if (migrated is Map<String, dynamic>) {
                  final item = SexualEvent.fromJson(migrated);
                  await sexualRepo.save(item);
                } else {
                  await sexualRepo.save(migrated as SexualEvent);
                }
                importedCount++;
              } catch (e, st) {
                _logger.warning(
                  'Migration failed for event ${file.path}, attempting fallback: $e',
                  e,
                  st,
                );
                try {
                  json['version'] = ModelVersionMigration.currentVersion;
                  final fallback = SexualEvent.fromJson(json);
                  await sexualRepo.save(fallback);
                  importedCount++;
                } catch (e2, st2) {
                  final msg =
                      'Failed to import event file ${file.path} even after fallback: $e2';
                  _logger.warning(msg, e2, st2);
                  importErrors.add(msg);
                  failedCount++;
                }
              }
            } catch (e, st) {
              final msg = 'Failed to import event file ${file.path}: $e';
              _logger.warning(msg, e, st);
              importErrors.add(msg);
              failedCount++;
            }
          }
        }
      }

      yield 'Import complete: $importedCount imported, $skippedCount skipped, $failedCount failed.';
      if (importErrors.isNotEmpty) {
        for (final err in importErrors) {
          yield 'Error: $err';
        }
      }

      // Cleanup
      await extractionDir.delete(recursive: true);
    } catch (e, stackTrace) {
      _logger.severe('Import failed', e, stackTrace);
      yield 'Error: $e';
      rethrow;
    }
  }
}
