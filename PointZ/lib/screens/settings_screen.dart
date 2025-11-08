import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;

  const SettingsScreen({
    super.key,
    required this.settings,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _settings = AppSettings()
      ..mouseSensitivity = widget.settings.mouseSensitivity
      ..minAcceleration = widget.settings.minAcceleration
      ..maxAcceleration = widget.settings.maxAcceleration
      ..accelerationThreshold = widget.settings.accelerationThreshold
      ..scrollSpeed = widget.settings.scrollSpeed;
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _save() async {
    widget.settings.mouseSensitivity = _settings.mouseSensitivity;
    widget.settings.minAcceleration = _settings.minAcceleration;
    widget.settings.maxAcceleration = _settings.maxAcceleration;
    widget.settings.accelerationThreshold = _settings.accelerationThreshold;
    widget.settings.scrollSpeed = _settings.scrollSpeed;
    await widget.settings.save();
    setState(() {
      _hasChanges = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  Future<void> _reset() async {
    await _settings.reset();
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          final shouldDiscard = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unsaved changes'),
              content: const Text('You have unsaved changes. Discard them?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard'),
                ),
              ],
            ),
          );
          if (shouldDiscard == true && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset to defaults',
              onPressed: _reset,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Mouse Sensitivity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Sensitivity: ${_settings.mouseSensitivity.toStringAsFixed(1)}'),
            Slider(
              value: _settings.mouseSensitivity,
              min: 0.5,
              max: 5.0,
              divisions: 45,
              label: _settings.mouseSensitivity.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _settings.mouseSensitivity = value;
                  _markChanged();
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Acceleration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Min: ${_settings.minAcceleration.toStringAsFixed(1)}'),
            Slider(
              value: _settings.minAcceleration,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: _settings.minAcceleration.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _settings.minAcceleration = value;
                  _markChanged();
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Max: ${_settings.maxAcceleration.toStringAsFixed(1)}'),
            Slider(
              value: _settings.maxAcceleration,
              min: 1.0,
              max: 3.0,
              divisions: 20,
              label: _settings.maxAcceleration.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _settings.maxAcceleration = value;
                  _markChanged();
                });
              },
            ),
            const SizedBox(height: 8),
            Text('Threshold: ${_settings.accelerationThreshold.toStringAsFixed(1)} px/ms'),
            Slider(
              value: _settings.accelerationThreshold,
              min: 10.0,
              max: 50.0,
              divisions: 40,
              label: _settings.accelerationThreshold.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _settings.accelerationThreshold = value;
                  _markChanged();
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Scrolling',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Speed: ${_settings.scrollSpeed.toStringAsFixed(2)}'),
            Slider(
              value: _settings.scrollSpeed,
              min: 0.1,
              max: 1.0,
              divisions: 90,
              label: _settings.scrollSpeed.toStringAsFixed(2),
              onChanged: (value) {
                setState(() {
                  _settings.scrollSpeed = value;
                  _markChanged();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

