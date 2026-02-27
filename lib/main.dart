import 'package:flutter/material.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/clinical_event_provider.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:indulge/view/migration/migration_check.dart';
// import 'package:indulge/view/common/navigation_helper.dart'; // Phase 1: disabled
import 'package:indulge/view/security/pin_entry_screen.dart';
import 'dart:io';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:indulge/domain/database/database_engine.dart';
import 'package:logging/logging.dart';

// Preferences service (SharedPreferences wrapper) - initialize at startup
import 'package:indulge/services/preferences_service.dart';
import 'package:indulge/services/security/encryption_key_service.dart';
import 'package:indulge/services/security/database_encryption_service.dart';
import 'package:indulge/services/database_connection_service.dart';

Future<void> main() async {
  // Ensure bindings are initialized before we await async services.
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.message}');
  });

  // Initialize preferences service before running the app so UI can read persisted prefs.
  final prefsService = await PreferencesService.build();

  // Run encryption migration if needed (unencrypted -> encrypted)
  await _runEncryptionMigration();

  // Run schema migration (creating new tables) before launching the app
  // This is fast - JSON migration will be handled later if needed
  await _runSchemaMigration();

  // Check if PIN is enabled
  final keyService = EncryptionKeyService();
  final isPinEnabled = await keyService.isPinEnabled();

  // Initialize database encryption key if PIN is not enabled
  if (!isPinEnabled) {
    final encryptionService = DatabaseEncryptionService();
    final encryptionKey = await encryptionService.getEncryptionKey();
    await DatabaseConnectionService.instance.initialize(
      encryptionKey: encryptionKey,
    );
  }

  // Provide the PreferencesService to the widget tree so screens can access persisted UI preferences.
  runApp(
    Provider<PreferencesService>.value(
      value: prefsService,
      child: MyApp(showPinOnStartup: isPinEnabled),
    ),
  );
}

/// Runs database encryption migration if needed.
/// This converts unencrypted databases to encrypted format.
Future<void> _runEncryptionMigration() async {
  try {
    final encryptionService = DatabaseEncryptionService();
    await encryptionService.migrateIfNeeded();
  } catch (e) {
    // Log but don't fail - the app will handle unencrypted DB
    print('Encryption migration error: $e');
  }
}

/// Runs schema-only migration (creates new tables).
/// This is fast - no UI needed.
Future<void> _runSchemaMigration() async {
  try {
    // Open database with version 3 - this triggers onUpgrade to create
    // missing tables like clinical_event (fast operation)
    final dbPath = '${await getDatabasesPath()}/indulge.db';
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      Logger.root.info('Schema migration: no DB file, skipping');
      return; // New install, onCreate will handle it
    }

    // Check if database is encrypted - if so, skip schema migration here
    // because it requires the encryption key which isn't available yet.
    // Schema migration will happen when the app properly opens with the key.
    final encryptionService = DatabaseEncryptionService();
    Logger.root.info('Schema migration: checking if DB is encrypted...');
    final isEncrypted = await encryptionService.isDatabaseEncrypted();
    Logger.root.info('Schema migration: isEncrypted = $isEncrypted');

    if (isEncrypted) {
      Logger.root.info(
        'Database is encrypted - skipping early schema migration',
      );
      return;
    }

    // Unencrypted DB - safe to open directly
    await openDatabase(
      dbPath,
      version: 3,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Perform actual schema upgrade (create missing tables)
        await DatabaseEngine.upgradeSchema(db, oldVersion, newVersion);
      },
    );
  } catch (e) {
    // Log but don't fail - let the app try to continue
    print('Schema migration error: $e');
  }
}

class MyApp extends StatefulWidget {
  final bool showPinOnStartup;

  const MyApp({super.key, required this.showPinOnStartup});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // GlobalKey to maintain MaterialApp state across hot reloads
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  bool _isUnlocked = false;
  bool _isDbInitialized = false;

  @override
  void initState() {
    super.initState();
    if (!widget.showPinOnStartup) {
      _isUnlocked = true;
      _isDbInitialized = true;
    }
  }

  Future<void> _initializeAfterPin() async {
    try {
      final encryptionService = DatabaseEncryptionService();
      final encryptionKey = await encryptionService.getEncryptionKey();
      await DatabaseConnectionService.instance.initialize(
        encryptionKey: encryptionKey,
      );
      setState(() {
        _isDbInitialized = true;
        _isUnlocked = true;
      });
    } catch (e) {
      Logger.root.warning('Error initializing database after PIN: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If PIN is required but not yet entered, show PIN screen
    if (widget.showPinOnStartup && !_isUnlocked) {
      // Use system brightness for theme to match device settings
      return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: Scaffold(body: PinEntryScreen(onSuccess: _initializeAfterPin)),
      );
    }

    // Wait for database to be initialized
    if (!_isDbInitialized && !widget.showPinOnStartup) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...'),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => EventStateStore()),
        ChangeNotifierProvider(
          create: (context) {
            final store = context.read<EventStateStore>();
            return SexualEventsProvider(stateStore: store);
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final store = context.read<EventStateStore>();
            return ClinicalEventsProvider(stateStore: store);
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Indulge',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeProvider.themeMode,
            home: MigrationCheck(child: MyHomePage(title: 'Indulge')),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Phase 1: All pages disabled - working on data layer
  // Navigation methods will be restored in later phases

  @override
  void initState() {
    super.initState();
    // Initialize theme provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThemeProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Phase 1: Navigation disabled - pages re-enabled in later phases
    return Scaffold(
      body: FutureBuilder<String>(
        future: context.read<SexualEventsProvider>().ready,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error initializing app',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          }

          // Phase 1: All pages disabled - working on data layer
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.construction, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Phase 1: Data Layer Updates',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Re-enabling pages in later phases'),
              ],
            ),
          );
        },
      ),
      // Phase 1: Bottom navigation disabled
      // bottomNavigationBar: BottomNavBar(currentPageIndex, (int index) {
      //   setState(() {
      //     currentPageIndex = index;
      //   });
      // }),
      // floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // Phase 1: FAB disabled - will be restored in later phases
}
