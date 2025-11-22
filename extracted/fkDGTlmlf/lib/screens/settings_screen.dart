import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_strings.dart';
import 'pairing_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(int)? updateTheme;

  const SettingsScreen({super.key, this.updateTheme});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences prefs;
  late String currentLanguage;
  late int selectedColor;
  late List<int> themeColors;
  bool isLoading = true;

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
      themeColors = [
        Colors.pink.value,
        Colors.teal.value,
        Colors.blue.value,
        Colors.deepPurple.value,
        Colors.amber.value,
        Colors.red.value,
        Colors.green.value,
        Colors.orange.value,
      ];
      isLoading = false;
    });
  }

  Future<void> _changeLanguage(String lang) async {
    await prefs.setString('languageCode', lang);
    setState(() => currentLanguage = lang);
    await loadStrings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(currentStrings['languageUpdated'] ?? 'Language updated')),
      );
    }
  }

  Future<void> _changeThemeColor(int colorValue) async {
    await prefs.setInt('appThemeColor', colorValue);
    setState(() => selectedColor = colorValue);

    if (widget.updateTheme != null) {
      widget.updateTheme!(colorValue);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(currentStrings['themeUpdated'] ?? 'Theme updated')),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(currentStrings['logout'] ?? 'Log Out'),
        content: Text(currentStrings['logoutConfirmation'] ?? 'Are you sure you want to log out?'),
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
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(currentStrings['settingsTitle'] ?? 'Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.language, color: colors.primary),
                    title: Text(currentStrings['language'] ?? 'Language'),
                    trailing: DropdownButton<String>(
                      value: currentLanguage,
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      ],
                      onChanged: (lang) => _changeLanguage(lang!),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentStrings['themeColor'] ?? 'App Theme Color',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: themeColors.map((colorValue) {
                      final isSelected = selectedColor == colorValue;
                      return GestureDetector(
                        onTap: () => _changeThemeColor(colorValue),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(colorValue),
                            border: isSelected
                                ? Border.all(width: 3, color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  ListTile(
                    leading: Icon(Icons.sync, color: colors.primary),
                    title: Text(currentStrings['changePartner'] ?? 'Change Partner'),
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const PairingScreen()),
                        (_) => false,
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: colors.error),
                    title: Text(currentStrings['logout'] ?? 'Log Out'),
                    onTap: _logout,
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: colors.primary),
                    title: Text(currentStrings['aboutAppTitle'] ?? 'About'),
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),
                ],
              ),
      ),
    );
  }
}
