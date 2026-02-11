import 'package:flutter/material.dart';
import 'package:indulge/view/daily_event_view/daily_event_view.dart';
import 'package:indulge/view/bottom_nav_bar.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:indulge/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:indulge/view/event_editor/event_editor.dart';
import 'package:indulge/view/person_list/person_list_page.dart';
import 'package:indulge/view/person_editor/person_editor_page.dart';
import 'package:indulge/view/settings/settings_page.dart';
import 'package:indulge/view/analysis/analysis_page.dart';
import 'package:indulge/view/search/search_page.dart';
import 'package:indulge/view/migration/migration_check.dart';
import 'package:logging/logging.dart';

// InheritedWidget to provide navigation callback
class NavigationHelper extends InheritedWidget {
  final void Function(String partnerId) navigateToSearchWithPartner;

  const NavigationHelper({
    super.key,
    required this.navigateToSearchWithPartner,
    required super.child,
  });

  static NavigationHelper? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NavigationHelper>();
  }

  @override
  bool updateShouldNotify(NavigationHelper oldWidget) => false;
}

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.message}');
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // GlobalKey to maintain MaterialApp state across hot reloads
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SexualEventsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
            home: const MigrationCheck(child: MyHomePage(title: 'Indulge')),
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

  @override
  build(BuildContext context) {
    return NavigationHelper(
      navigateToSearchWithPartner: navigateToSearchWithPartner,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
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
                const PersonListPage(),
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
      case 0: // Events page
        return FloatingActionButton(
          heroTag: 'events_add_fab',
          onPressed: () {
            final selectedDate = context
                .read<SexualEventsProvider>()
                .state
                .selectedDate;
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) =>
                    EventEditorPage(initialDate: selectedDate),
              ),
            );
          },
          tooltip: 'Add a new encounter',
          child: const Icon(Icons.add),
        );
      case 3: // Contacts page
        return FloatingActionButton(
          heroTag: 'contacts_add_fab',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const PersonEditorPage(),
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
