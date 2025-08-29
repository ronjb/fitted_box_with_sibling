import 'package:fitted_box_with_siblings/fitted_box_with_siblings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        color: Colors.orange,
        child: FittedBoxWithSiblings(
          computeRects: (constraints, boxSize) {
            if (kDebugMode) {
              print('constraints=$constraints, boxSize=$boxSize');
            }
            final centerX = constraints.maxWidth / 2;
            return [
              Rect.fromLTWH(
                0,
                100,
                constraints.maxWidth,
                constraints.maxHeight - 100,
              ),
              Rect.fromLTWH(0, 0, centerX, 100),
              Rect.fromLTWH(centerX, 0, centerX, 100),
            ];
          },
          children: [
            const Text('You have pushed the button this many times:'),
            Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              color: Colors.yellow,
              child: Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              color: Colors.blue,
              child: Text(
                'Next: ${_counter + 1}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
