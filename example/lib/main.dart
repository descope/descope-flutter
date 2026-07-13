import 'package:flutter/material.dart';
import 'package:descope/descope.dart';

void main() {
  Descope.setup('project-id', (config) {});
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Descope example'))),
    );
  }
}
