import 'package:flutter/material.dart';
import 'screens/discovery_screen.dart';

void main() {
  runApp(const PointZApp());
}

class PointZApp extends StatelessWidget {
  const PointZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PointZ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DiscoveryScreen(),
    );
  }
}

