import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_strings.dart';
import 'package:permission_handler/permission_handler.dart';

class IMissYouSettingsScreen extends StatefulWidget {
  const IMissYouSettingsScreen({super.key});

  @override
  State<IMissYouSettingsScreen> createState() => _IMissYouSettingsScreenState();
}

class _IMissYouSettingsScreenState extends State<IMissYouSettingsScreen> {
  TimeOfDay? _reminderTime;
  bool _remindersEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? timeString = prefs.getString('reminderTime');
    
    setState(() {
      _remindersEnabled = prefs.getBool('remindersEnabled') ?? false;
      if (timeString != null) {
        final parts = timeString.split(':');
        _reminderTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } else {
        _reminderTime = const TimeOfDay(hour: 20, minute: 0); // Default 8:00 PM
      }
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_reminderTime == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminderTime', '${_reminderTime!.hour}:${_reminderTime!.minute}');
    await prefs.setBool('remindersEnabled', _remindersEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentStrings['reminderSaved'] ?? 'Reminder settings saved!'),
        ),
      );
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 20, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
      await _saveSettings();
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      setState(() {
        _remindersEnabled = true;
      });
      await _saveSettings();
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(currentStrings['openAppSettings'] ?? 'Open App Settings'),
            content: Text(
              currentStrings['appSettingsExplanation'] ??
                  'To ensure reminders work, please enable notifications for HeartSync in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(currentStrings['cancel'] ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: Text(currentStrings['openAppSettings'] ?? 'Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(currentStrings['iMissYouSettingsTitle'] ?? 'I Miss You Settings'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentStrings['iMissYouSettingsTitle'] ?? 'I Miss You Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentStrings['setReminderTime'] ?? 'Set Reminder Time',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.access_time, color: primaryColor),
                    title: Text(currentStrings['reminderTime'] ?? 'Reminder Time'),
                    subtitle: Text(
                      _reminderTime != null
                          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                          : currentStrings['tapToPick'] ?? 'Tap to select',
                    ),
                    onTap: _selectTime,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(currentStrings['enableReminders'] ?? 'Enable Reminders'),
                    subtitle: Text(
                      _remindersEnabled
                          ? 'You will be reminded daily'
                          : 'Turn on to receive reminders',
                    ),
                    value: _remindersEnabled,
                    activeColor: primaryColor,
                    onChanged: (bool value) async {
                      if (value) {
                        await _requestNotificationPermission();
                      } else {
                        setState(() {
                          _remindersEnabled = false;
                        });
                        await _saveSettings();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'About Reminders',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentStrings['reminderMessage'] ??
                        'Get a daily reminder to check on your partner and send them a heartbeat!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
