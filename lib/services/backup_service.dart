import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:indulge/data/models.dart';
import 'package:indulge/data/repositories/sexual_event_repository.dart';
import 'package:indulge/data/repositories/clinical_event_repository.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class BackupService {
  final Logger _logger = Logger('BackupService');
  final SexualEventRepository sexualRepo;
  final ClinicalEventRepository clinicalRepo;

  BackupService(this.sexualRepo, this.clinicalRepo);

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
        'appVersion': '0.1.2-beta', // TODO: Get from package info
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

    for (final item in items) {
      final file = File(p.join(dir.path, '${getId(item)}.json'));
      // Pretty print JSON
      final jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(toJson(item));
      await file.writeAsString(jsonString);
    }
  }

  /// Imports data from a zip file selected by the user.
  /// Returns a stream of progress messages.
  Stream<String> importData() async* {
    File? zipFile;
    Directory? tempDir;

    try {
      // 1. Pick file
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
      yield 'Reading backup file...';

      // 2. Extract ZIP
      tempDir = await getTemporaryDirectory();
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

      // -- Categories --
      yield 'Importing categories...';
      final categoriesDir = Directory(p.join(extractionDir.path, 'categories'));
      if (await categoriesDir.exists()) {
        await for (final file in categoriesDir.list()) {
          if (file is File && file.path.endsWith('.json')) {
            final content = await file.readAsString();
            final json = jsonDecode(content);
            final item = SexualActivityCategory.fromJson(json);
            await sexualRepo.saveActivityCategory(item);
          }
        }
      }

      // -- Activities --
      yield 'Importing activities...';
      final activitiesDir = Directory(p.join(extractionDir.path, 'activities'));
      if (await activitiesDir.exists()) {
        await for (final file in activitiesDir.list()) {
          if (file is File && file.path.endsWith('.json')) {
            final content = await file.readAsString();
            final json = jsonDecode(content);
            final item = SexualActivity.fromJson(json);
            await sexualRepo.saveSexualActivity(item);
          }
        }
      }

      // -- Persons --
      yield 'Importing contacts...';
      final personsDir = Directory(p.join(extractionDir.path, 'persons'));
      if (await personsDir.exists()) {
        await for (final file in personsDir.list()) {
          if (file is File && file.path.endsWith('.json')) {
            final content = await file.readAsString();
            final json = jsonDecode(content);
            final item = Person.fromJson(json);
            // Skip anonymous if it exists in backup (it should exist in DB)
            if (item.id != 'anonymous') {
              await sexualRepo.savePerson(item);
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
            final content = await file.readAsString();
            final json = jsonDecode(content);
            final item = ClinicalEvent.fromJson(json);
            await clinicalRepo.save(item);
          }
        }
      }

      // -- Events --
      yield 'Importing events...';
      final eventsDir = Directory(p.join(extractionDir.path, 'sexual_events'));
      if (await eventsDir.exists()) {
        await for (final file in eventsDir.list()) {
          if (file is File && file.path.endsWith('.json')) {
            final content = await file.readAsString();
            final json = jsonDecode(content);
            final item = SexualEvent.fromJson(json);
            await sexualRepo.save(item);
          }
        }
      }

      yield 'Import complete!';

      // Cleanup
      await extractionDir.delete(recursive: true);
    } catch (e, stackTrace) {
      _logger.severe('Import failed', e, stackTrace);
      yield 'Error: $e';
      rethrow;
    }
  }
}
