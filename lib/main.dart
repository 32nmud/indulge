import 'package:flutter/material.dart';
import 'package:indulge/view/encounter_view.dart';
import 'package:indulge/view/bottom_nav_bar.dart';
import 'package:indulge/domain/data_access.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Indulge'),
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
  final Future<DataAccess> _dataAccess = DataAccess.create();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Add a new encounter',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavBar(currentPageIndex, (index) {
        setState(() {
          currentPageIndex = index;
        });
      }),
      body: FutureBuilder(future: _dataAccess, builder: (ctx, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return [
            EncounterViewPage(dataAccess: snapshot.data!),
            const Center(
              child: Text("This is the analysis page"),
            ),
            const Center(
              child: Text("This is the contacts page"),
            ),
            const Center(
              child: Text("This is the settings page"),
            )
          ][currentPageIndex];
      }
      throw Exception("Invalid state!");
      })
    );
  }
}
