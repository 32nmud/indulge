import 'package:flutter/material.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/clinical_event_provider.dart';
import 'package:indulge/provider/event_state_store.dart';
import 'package:indulge/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:indulge/view/migration/migration_check.dart';
import 'package:indulge/view/common/navigation_helper.dart';
import 'package:indulge/view/security/pin_entry_screen.dart';
import 'package:indulge/view/home/daily_event_view.dart';
import 'package:indulge/view/search/search_page.dart';
import 'package:indulge/view/analysis/analysis_page.dart';
import 'package:indulge/view/contacts/contact_list_page.dart';
import 'package:indulge/view/settings/settings_page.dart';
import 'package:indulge/view/common/speed_dial_fab.dart';
import 'package:indulge/view/common/sexual_event_editor/sexual_event_editor.dart';
import 'package:indulge/view/common/clinical_event_editor/clinical_event_editor.dart';
import 'package:indulge/provider/clinical_event_provider.dart'
    show ClinicalEventsProvider;
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
  int _currentPageIndex = 0;

  /// Set when navigation is triggered programmatically (e.g. "search this
  /// partner") so the back button/gesture can return the user to where they
  /// came from.  Cleared whenever the user taps a bottom-nav destination
  /// themselves.
  int? _previousPageIndex;

  /// Pages that have been visited at least once.  The IndexedStack only builds
  /// a page on first visit so we don't pay the cost of constructing all five
  /// pages at startup.
  final Set<int> _builtPages = {0};

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

  /// Called when the user explicitly taps a bottom-nav destination.
  /// Clears the back-history so the OS back button exits normally.
  void _userNavigateTo(int index) {
    if (index == _currentPageIndex) return;
    setState(() {
      _builtPages.add(index);
      _previousPageIndex = null;
      _currentPageIndex = index;
    });
  }

  /// Called when code inside a page navigates to another tab (e.g. opening
  /// Search from within Analysis).  Records the origin so the user can swipe /
  /// press back to return there.
  void _programmaticNavigateTo(int index) {
    if (index == _currentPageIndex) return;
    setState(() {
      _builtPages.add(index);
      _previousPageIndex = _currentPageIndex;
      _currentPageIndex = index;
    });
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const EventViewPage();
      case 1:
        return SearchPage(key: _searchPageKey);
      case 2:
        return const AnalysisPage();
      case 3:
        return const ContactListPage();
      case 4:
        return const SettingsPage();
      default:
        return const EventViewPage();
    }
  }

  @override
  Widget build(BuildContext context) {
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

          return NavigationHelper(
            navigateToSearchWithPartner: (String partnerId) {
              _programmaticNavigateTo(1);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _searchPageKey.currentState?.applyFilters(partnerId: partnerId);
              });
            },
            navigateToSearchWithEventType: (String eventType) {
              _programmaticNavigateTo(1);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _searchPageKey.currentState?.applyFilters(eventType: eventType);
              });
            },
            navigateToSearchWithCategory: (String categoryId) {
              _programmaticNavigateTo(1);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _searchPageKey.currentState?.applyFilters(
                  categoryId: categoryId,
                );
              });
            },
            navigateToSearchWithDateRange: (DateTimeRange range) {
              _programmaticNavigateTo(1);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _searchPageKey.currentState?.applyFilters(dateRange: range);
              });
            },
            navigateToSearch:
                ({
                  DateTimeRange? dateRange,
                  String? eventType,
                  String? partnerId,
                  String? categoryId,
                  bool sinceLastStiTest = false,
                }) {
                  _programmaticNavigateTo(1);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _searchPageKey.currentState?.applyFilters(
                      dateRange: dateRange,
                      eventType: eventType,
                      partnerId: partnerId,
                      categoryId: categoryId,
                      sinceLastStiTest: sinceLastStiTest,
                    );
                  });
                },
            // IndexedStack keeps every visited page alive in the widget tree
            // so state (scroll position, loaded data, page index, etc.) is
            // preserved when the user switches tabs or is sent to Search
            // programmatically.  Pages that haven't been visited yet are
            // replaced with a cheap SizedBox so we don't pay build cost
            // upfront for all five pages.
            child: PopScope(
              // Allow the OS back gesture/button only when there is nowhere to
              // go back to (i.e. normal app-exit behaviour).
              canPop: _previousPageIndex == null,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop && _previousPageIndex != null) {
                  setState(() {
                    _currentPageIndex = _previousPageIndex!;
                    _previousPageIndex = null;
                  });
                }
              },
              child: IndexedStack(
                index: _currentPageIndex,
                children: List.generate(5, (i) {
                  if (!_builtPages.contains(i)) return const SizedBox.shrink();
                  return _buildPageWithFab(i);
                }),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentPageIndex,
        onDestinationSelected: _userNavigateTo,
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.search),
            icon: Icon(Icons.search_outlined),
            label: 'Search',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.bar_chart),
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Analysis',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.contacts),
            icon: Icon(Icons.contacts_outlined),
            label: 'Contacts',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings),
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildPageWithFab(int index) {
    return Scaffold(
      body: _buildPage(index),
      floatingActionButton: index == 0
          ? SpeedDialFab(
              items: [
                SpeedDialItem(
                  icon: const Icon(Icons.edit),
                  label: 'Log Event',
                  onPressed: () => _openEventEditor(null),
                ),
                SpeedDialItem(
                  icon: const Icon(Icons.medical_services),
                  label: 'Log Test Result',
                  onPressed: () => _openClinicalEventEditor(null),
                ),
              ],
            )
          : null,
    );
  }

  void _openEventEditor(DateTime? initialDate) {
    // If no date was explicitly provided, use the currently selected date from
    // the store (e.g. the user has navigated to a past day in the calendar).
    // Fall back to today only when the store has no selection.
    final selectedDate =
        initialDate ??
        context.read<EventStateStore>().state.selectedDate ??
        DateTime.now();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SexualEventEditorPage(initialDate: selectedDate),
      ),
    );
  }

  void _openClinicalEventEditor(DateTime? initialDate) {
    final selectedDate =
        initialDate ??
        context.read<EventStateStore>().state.selectedDate ??
        DateTime.now();
    final clinicalProvider = context.read<ClinicalEventsProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClinicalEventEditorPage(
          initialDate: selectedDate,
          onSave: (event) async {
            try {
              await clinicalProvider.saveEvent(event);
              return true;
            } catch (_) {
              return false;
            }
          },
        ),
      ),
    );
  }
}
