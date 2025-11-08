import 'package:flutter/material.dart';
import 'dart:io';
import 'services/discovery_service.dart';
import 'screens/control_screen.dart';

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

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  ServerDiscovery? _discovery;
  InternetAddress? _discoveredServer;
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
    });

    _discovery = await ServerDiscovery.start();
    _discovery!.discoveredServers.listen((address) {
      if (mounted) {
        setState(() {
          _discoveredServer = address;
          _isDiscovering = false;
        });
      }
    });

    _discovery!.discover();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _discoveredServer == null) {
        setState(() {
          _isDiscovering = false;
        });
      }
    });
  }

  void _connectToServer() {
    if (_discoveredServer != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ControlScreen(
            serverAddress: _discoveredServer!,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _discovery?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PointZ'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isDiscovering)
                const CircularProgressIndicator()
              else if (_discoveredServer != null) ...[
                const Icon(Icons.computer, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Server found: ${_discoveredServer!.address}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _connectToServer,
                  child: const Text('Connect'),
                ),
              ] else ...[
                const Icon(Icons.search_off, size: 64),
                const SizedBox(height: 16),
                const Text('No server found'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _startDiscovery,
                  child: const Text('Search Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

