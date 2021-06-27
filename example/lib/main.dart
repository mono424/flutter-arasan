import 'package:flutter/material.dart';
import 'package:arasan/arasan.dart';

import 'src/output_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<MyApp> {
  late Arasan arasan;

  @override
  void initState() {
    super.initState();
    arasan = Arasan();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Arasan example app'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedBuilder(
                animation: arasan.state,
                builder: (_, __) => Text(
                  'arasan.state=${arasan.state.value}',
                  key: ValueKey('arasan.state'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedBuilder(
                animation: arasan.state,
                builder: (_, __) => ElevatedButton(
                  onPressed: arasan.state.value == ArasanState.disposed
                      ? () {
                          final newInstance = Arasan();
                          setState(() => arasan = newInstance);
                        }
                      : null,
                  child: Text('Reset Arasan instance'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Custom UCI command',
                  hintText: 'go infinite',
                ),
                onSubmitted: (value) => arasan.stdin = value,
                textInputAction: TextInputAction.send,
              ),
            ),
            Wrap(
              children: [
                'd',
                'isready',
                'go infinite',
                'go movetime 3000',
                'stop',
                'quit',
              ]
                  .map(
                    (command) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () => arasan.stdin = command,
                        child: Text(command),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            Expanded(
              child: OutputWidget(arasan.stdout),
            ),
          ],
        ),
      ),
    );
  }
}
