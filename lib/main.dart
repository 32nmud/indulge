import 'package:flutter/material.dart';
import 'package:indulge/view/daily_event_view/daily_event_view.dart';
import 'package:indulge/view/bottom_nav_bar.dart';
import 'package:indulge/provider/sexual_event_provider.dart';
import 'package:provider/provider.dart';
import 'package:indulge/view/event_editor/event_editor.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.message}');
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SexualEventsProvider(),
      child: MaterialApp(
        title: 'Indulge',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Indulge'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const EventEditorPage(),
            ),
          ),
        },
        tooltip: 'Add a new encounter',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavBar(currentPageIndex, (index) {
        setState(() {
          currentPageIndex = index;
        });
      }),
      body: FutureBuilder<void>(
        future: context.read<SexualEventsProvider>().ready,
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return IndexedStack(
            index: currentPageIndex,
            children: const [
              EventViewPage(),
              Center(child: Text("This is the analysis page")),
              Center(child: Text("This is the contacts page")),
              Center(child: Text("This is the settings page")),
            ],
          );
        },
      ),
    );
  }
}
