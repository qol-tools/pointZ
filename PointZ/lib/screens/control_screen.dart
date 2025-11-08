import 'package:flutter/material.dart';
import 'dart:io';
import '../services/command_service.dart';
import '../features/gesture/gesture_handler.dart';
import '../features/gesture/gesture_detector.dart';
import '../features/mouse_control/implementations/command_service_executor.dart';

class ControlScreen extends StatefulWidget {
  final InternetAddress serverAddress;

  const ControlScreen({
    super.key,
    required this.serverAddress,
  });

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  late CommandService _commandService;
  late GestureHandler _gestureHandler;
  late FlutterGestureConverter _gestureConverter;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _commandService = CommandService(widget.serverAddress);
    final executor = CommandServiceExecutor(_commandService);
    _gestureHandler = GestureHandler(executor);
    _gestureConverter = FlutterGestureConverter();
    _connect();
  }

  Future<void> _connect() async {
    await _commandService.connect();
    setState(() {
      _isConnected = true;
    });
  }

  Future<void> _onScaleStart(ScaleStartDetails details) async {
    if (!_isConnected) return;
    final event = _gestureConverter.onScaleStart(details);
    if (event != null) {
      await _gestureHandler.handleEvent(event);
    }
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    if (!_isConnected) return;
    final event = _gestureConverter.onScaleUpdate(details);
    if (event != null) {
      await _gestureHandler.handleEvent(event);
    }
  }

  Future<void> _onScaleEnd(ScaleEndDetails details) async {
    if (!_isConnected) return;
    final event = _gestureConverter.onScaleEnd(details);
    await _gestureHandler.handleEvent(event);
  }

  @override
  void dispose() {
    _commandService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Control - ${widget.serverAddress.address}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        child: Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.error,
                  size: 64,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 32),
                const Text(
                  'One finger: Move/Click\nTwo fingers: Right click/Scroll\nThree fingers: Middle click\nDouble tap: Select/Drag',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
