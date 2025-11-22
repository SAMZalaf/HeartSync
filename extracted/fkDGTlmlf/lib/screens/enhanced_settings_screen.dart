import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_strings.dart';
import 'pairing_screen.dart';

class EnhancedSettingsScreen extends StatefulWidget {
  final void Function(int)? updateTheme;

  const EnhancedSettingsScreen({super.key, this.updateTheme});

  @override
  State<EnhancedSettingsScreen> createState() => _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends State<EnhancedSettingsScreen> {
  late SharedPreferences prefs;
  late String currentLanguage;
  late int selectedColor;
  late String selectedThemeMode;
  late double selectedFontSize;
  late bool notificationsEnabled;
  late bool vibrationEnabled;
  late bool soundEnabled;
  late bool doNotDisturb;
  late bool showOnlineStatus;
  
  bool isLoading = true;

  final List<Map<String, dynamic>> themeColors = [
    {'name': 'Romantic Red', 'color': Colors.red.shade700, 'icon': Icons.favorite},
    {'name': 'Loving Pink', 'color': Colors.pink.shade400, 'icon': Icons.favorite_border},
    {'name': 'Mystic Purple', 'color': Colors.deepPurple.shade600, 'icon': Icons.auto_awesome},
    {'name': 'Calm Blue', 'color': Colors.blue.shade700, 'icon': Icons.water_drop},
    {'name': 'Fresh Green', 'color': Colors.green.shade600, 'icon': Icons.eco},
    {'name': 'Sunset Orange', 'color': Colors.orange.shade700, 'icon': Icons.wb_sunny},
    {'name': 'Royal Teal', 'color': Colors.teal.shade600, 'icon': Icons.diamond},
    {'name': 'Warm Amber', 'color': Colors.amber.shade700, 'icon': Icons.star},
  ];

  final List<String> themeModes = ['Light', 'Dark', 'Auto'];
  final List<double> fontSizes = [12, 14, 16, 18, 20];
  final List<String> fontSizeLabels = ['Extra Small', 'Small', 'Medium', 'Large', 'Extra Large'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      currentLanguage = prefs.getString('languageCode') ?? 'en';
      selectedColor = prefs.getInt('appThemeColor') ?? Colors.pink.value;
      selectedThemeMode = prefs.getString('themeMode') ?? 'Auto';
      selectedFontSize = prefs.getDouble('fontSize') ?? 16.0;
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      soundEnabled = prefs.getBool('soundEnabled') ?? true;
      doNotDisturb = prefs.getBool('doNotDisturb') ?? false;
      showOnlineStatus = prefs.getBool('showOnlineStatus') ?? true;
      isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  Future<void> _changeLanguage(String lang) async {
    await _saveSetting('languageCode', lang);
    setState(() => currentLanguage = lang);
    await loadStrings();
    _showSnackBar(currentStrings['languageUpdated'] ?? 'Language updated');
  }

  Future<void> _changeThemeColor(int colorValue) async {
    await _saveSetting('appThemeColor', colorValue);
    setState(() => selectedColor = colorValue);
    if (widget.updateTheme != null) {
      widget.updateTheme!(colorValue);
    }
    _showSnackBar(currentStrings['themeUpdated'] ?? 'Theme updated');
  }

  Future<void> _changeThemeMode(String mode) async {
    await _saveSetting('themeMode', mode);
    setState(() => selectedThemeMode = mode);
    _showSnackBar('Theme mode: $mode');
  }

  Future<void> _changeFontSize(double size) async {
    await _saveSetting('fontSize', size);
    setState(() => selectedFontSize = size);
    _showSnackBar('Font size: ${fontSizeLabels[fontSizes.indexOf(size)]}');
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 20, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(children: children),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(currentStrings['settingsTitle'] ?? 'Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentStrings['settingsTitle'] ?? 'Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSection(
            currentStrings['appearance'] ?? 'Appearance',
            [
              ListTile(
                leading: Icon(Icons.palette, color: Theme.of(context).colorScheme.primary),
                title: const Text('Theme Color'),
                subtitle: const Text('Choose your favorite color'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: themeColors.map((theme) {
                    final isSelected = selectedColor == theme['color'].value;
                    return GestureDetector(
                      onTap: () => _changeThemeColor(theme['color'].value),
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme['color'],
                              border: isSelected
                                  ? Border.all(width: 3, color: Colors.white)
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: theme['color'].withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(theme['icon'], color: Colors.white, size: 24),
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Icon(Icons.check_circle, 
                                color: theme['color'], size: 16),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.brightness_6, color: Theme.of(context).colorScheme.primary),
                title: const Text('Theme Mode'),
                subtitle: Text('Current: $selectedThemeMode'),
                trailing: SegmentedButton<String>(
                  segments: themeModes.map((mode) => ButtonSegment(
                    value: mode,
                    label: Text(mode, style: const TextStyle(fontSize: 12)),
                  )).toList(),
                  selected: {selectedThemeMode},
                  onSelectionChanged: (Set<String> newSelection) {
                    _changeThemeMode(newSelection.first);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.format_size, color: Theme.of(context).colorScheme.primary),
                title: const Text('Font Size'),
                subtitle: Text(fontSizeLabels[fontSizes.indexOf(selectedFontSize)]),
              ),
              Slider(
                value: selectedFontSize,
                min: fontSizes.first,
                max: fontSizes.last,
                divisions: fontSizes.length - 1,
                label: fontSizeLabels[fontSizes.indexOf(selectedFontSize)],
                onChanged: (value) {
                  final nearestSize = fontSizes.reduce((a, b) => 
                    (a - value).abs() < (b - value).abs() ? a : b);
                  _changeFontSize(nearestSize);
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Preview Text Sample',
                  style: TextStyle(fontSize: selectedFontSize),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          _buildSection(
            currentStrings['language'] ?? 'Language',
            [
              ListTile(
                leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                title: Text(currentStrings['language'] ?? 'Language'),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('English')),
                    ButtonSegment(value: 'ar', label: Text('العربية')),
                  ],
                  selected: {currentLanguage},
                  onSelectionChanged: (Set<String> newSelection) {
                    _changeLanguage(newSelection.first);
                  },
                ),
              ),
            ],
          ),
          _buildSection(
            currentStrings['notifications'] ?? 'Notifications',
            [
              SwitchListTile(
                secondary: Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary),
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive love notifications'),
                value: notificationsEnabled,
                onChanged: (value) {
                  setState(() => notificationsEnabled = value);
                  _saveSetting('notificationsEnabled', value);
                },
              ),
              SwitchListTile(
                secondary: Icon(Icons.vibration, color: Theme.of(context).colorScheme.primary),
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate on heartbeat'),
                value: vibrationEnabled,
                onChanged: (value) {
                  setState(() => vibrationEnabled = value);
                  _saveSetting('vibrationEnabled', value);
                },
                enabled: notificationsEnabled,
              ),
              SwitchListTile(
                secondary: Icon(Icons.volume_up, color: Theme.of(context).colorScheme.primary),
                title: const Text('Sound'),
                subtitle: const Text('Play sound on heartbeat'),
                value: soundEnabled,
                onChanged: (value) {
                  setState(() => soundEnabled = value);
                  _saveSetting('soundEnabled', value);
                },
                enabled: notificationsEnabled,
              ),
              SwitchListTile(
                secondary: Icon(Icons.do_not_disturb, color: Theme.of(context).colorScheme.primary),
                title: const Text('Do Not Disturb'),
                subtitle: const Text('Mute all notifications'),
                value: doNotDisturb,
                onChanged: (value) {
                  setState(() => doNotDisturb = value);
                  _saveSetting('doNotDisturb', value);
                },
              ),
            ],
          ),
          _buildSection(
            currentStrings['privacy'] ?? 'Privacy',
            [
              SwitchListTile(
                secondary: Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary),
                title: const Text('Show Online Status'),
                subtitle: const Text('Let partner see when you\'re online'),
                value: showOnlineStatus,
                onChanged: (value) {
                  setState(() => showOnlineStatus = value);
                  _saveSetting('showOnlineStatus', value);
                },
              ),
            ],
          ),
          _buildSection(
            currentStrings['account'] ?? 'Account',
            [
              ListTile(
                leading: Icon(Icons.sync, color: Theme.of(context).colorScheme.primary),
                title: Text(currentStrings['changePartner'] ?? 'Change Partner'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const PairingScreen()),
                    (_) => false,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                title: Text(currentStrings['aboutAppTitle'] ?? 'About'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.pushNamed(context, '/about'),
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text(currentStrings['logout'] ?? 'Log Out'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(currentStrings['logout'] ?? 'Log Out'),
                      content: Text(currentStrings['logoutConfirmation'] ?? 
                        'Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          child: Text(currentStrings['cancel'] ?? 'Cancel'),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        TextButton(
                          child: Text(currentStrings['confirm'] ?? 'Confirm'),
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await prefs.clear();
                    try {
                      await FirebaseAuth.instance.signOut();
                    } catch (e) {
                      debugPrint('Error signing out: $e');
                    }
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const PairingScreen()),
                        (_) => false,
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'HeartSync v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
