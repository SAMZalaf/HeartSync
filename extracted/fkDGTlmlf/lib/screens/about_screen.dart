import 'package:flutter/material.dart';
import '../utils/app_strings.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentStrings['aboutAppTitle'] ?? 'About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              size: 100,
              color: primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              currentStrings['appTitle'] ?? 'HeartSync',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      currentStrings['appDescription'] ??
                          'HeartSync is an app designed to help you stay connected with your loved one through simple interactions and reminders.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildFeatureItem(
              context,
              Icons.favorite_border,
              currentStrings['heartbeatSent'] ?? 'Send Heartbeats',
              'Share your heartbeat with your partner',
            ),
            _buildFeatureItem(
              context,
              Icons.message,
              currentStrings['messageSent'] ?? 'Send Messages',
              'Stay connected with sweet messages',
            ),
            _buildFeatureItem(
              context,
              Icons.notifications_active,
              currentStrings['reminderSaved'] ?? 'Smart Reminders',
              'Get reminded to check on your partner',
            ),
            _buildFeatureItem(
              context,
              Icons.qr_code_scanner,
              currentStrings['qrScannerTitle'] ?? 'QR Code Pairing',
              'Easy pairing with QR codes',
            ),
            _buildFeatureItem(
              context,
              Icons.language,
              currentStrings['language'] ?? 'Multi-Language',
              'Available in English and Arabic',
            ),
            const SizedBox(height: 30),
            Divider(color: Colors.white24),
            const SizedBox(height: 20),
            Text(
              currentStrings['copyright'] ?? '© 2024 HeartSync. All rights reserved.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Made with ❤️ for couples around the world',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
