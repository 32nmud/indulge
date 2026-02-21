import 'package:flutter/material.dart';
import 'package:indulge/view/common/contact_editor/contact_editor_page.dart';
import 'package:indulge/view/home/daily_event_view.dart';
import 'package:indulge/view/common/bottom_nav_bar.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/clinical_event_provider.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:indulge/view/common/sexual_event_editor/sexual_event_editor.dart';
import 'package:indulge/view/contacts/contact_list_page.dart';
import 'package:indulge/view/settings/settings_page.dart';
import 'package:indulge/view/analysis/analysis_page.dart';
import 'package:indulge/view/search/search_page.dart';
import 'package:indulge/view/migration/migration_check.dart';
import 'package:indulge/view/common/navigation_helper.dart';
import 'package:indulge/view/security/pin_entry_screen.dart';
import 'dart:io';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:indulge/domain/database/database_engine.dart';
import 'package:indulge/view/common/speed_dial_fab.dart';
import 'package:indulge/view/common/clinical_event_editor/clinical_event_editor.dart';
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
  int currentPageIndex = 0;
  final GlobalKey<SearchPageState> _searchPageKey =
      GlobalKey<SearchPageState>();

  @override
  void initState() {
    super.initState();
    // Initialize theme provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThemeProvider>().initialize();
    });
  }

  // Method to navigate to search page with partner filter
  void navigateToSearchWithPartner(String partnerId) {
    setState(() {
      currentPageIndex = 1; // Search page index
    });
    // Wait for the page to build, then set the filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchPageKey.currentState?.setPartnerFilter(partnerId);
    });
  }

  // Method to navigate to search page with event type filter
  void navigateToSearchWithEventType(String eventType) {
    setState(() {
      currentPageIndex = 1; // Search page index
    });
    // Wait for the page to build, then set the filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchPageKey.currentState?.setEventTypeFilter(eventType);
    });
  }

  void navigateToSearchWithCategory(String categoryId) {
    setState(() {
      currentPageIndex = 1; // Search page index
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchPageKey.currentState?.applyFilters(categoryId: categoryId);
    });
  }

  // Method to navigate to search page with date range filter
  void navigateToSearchWithDateRange(DateTimeRange range) {
    setState(() {
      currentPageIndex = 1; // Search page index
    });
    // Wait for the page to build, then set the filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchPageKey.currentState?.setDateRangeFilter(range);
    });
  }

  void navigateToSearch({
    DateTimeRange? dateRange,
    String? eventType,
    String? partnerId,
    String? categoryId,
    bool sinceLastStiTest = false,
  }) {
    setState(() {
      currentPageIndex = 1; // Search page index
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchPageKey.currentState?.applyFilters(
        dateRange: dateRange,
        eventType: eventType,
        partnerId: partnerId,
        categoryId: categoryId,
        sinceLastStiTest: sinceLastStiTest,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return NavigationHelper(
      navigateToSearchWithPartner: navigateToSearchWithPartner,
      navigateToSearchWithEventType: navigateToSearchWithEventType,
      navigateToSearchWithCategory: navigateToSearchWithCategory,
      navigateToSearchWithDateRange: navigateToSearchWithDateRange,
      navigateToSearch: navigateToSearch,
      child: Scaffold(
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
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error initializing app',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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

            return IndexedStack(
              index: currentPageIndex,
              children: [
                const EventViewPage(),
                SearchPage(key: _searchPageKey),
                const AnalysisPage(),
                const ContactListPage(key: PageStorageKey('contact_list')),
                const SettingsPage(),
              ],
            );
          },
        ),
        bottomNavigationBar: BottomNavBar(currentPageIndex, (int index) {
          setState(() {
            currentPageIndex = index;
          });
        }),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Show different FAB based on current page
    switch (currentPageIndex) {
      case 0: // Events page - show speed-dial FAB with Sexual + Clinical actions
        return SpeedDialFab(
          items: [
            SpeedDialItem(
              icon: const Icon(Icons.local_fire_department),
              label: 'Sexual',
              onPressed: () {
                final selectedDate = context
                    .read<EventStateStore>()
                    .state
                    .selectedDate;
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        SexualEventEditorPage(initialDate: selectedDate),
                  ),
                );
              },
            ),
            SpeedDialItem(
              icon: const Icon(Icons.medical_services),
              label: 'Clinical',
              onPressed: () {
                final selectedDate = context
                    .read<EventStateStore>()
                    .state
                    .selectedDate;
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => ClinicalEventEditorPage(
                      initialDate: selectedDate,
                      onSave: (clinicalEvent) async {
                        try {
                          await context
                              .read<ClinicalEventsProvider>()
                              .saveEvent(clinicalEvent);
                          return true;
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error saving clinical event: $e',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return false;
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ],
          closedIcon: Icons.add,
        );
      case 3: // Contacts page
        return FloatingActionButton(
          heroTag: 'contacts_add_fab',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const ContactEditorPage(),
              ),
            );
          },
          tooltip: 'Add a new contact',
          child: const Icon(Icons.person_add),
        );
      default:
        return null; // No FAB for other pages
    }
  }
}
