import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

import 'firebase_options.dart';
import 'screens/personal_info_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/enhanced_settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/i_miss_you_settings_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'services/background_service.dart';
import 'utils/app_strings.dart';

final logger = Logger();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late String currentLanguageCode;

// Initialize FlutterLocalNotificationsPlugin globally
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flutterLocalNotificationsPlugin
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // 1. Initialize local notifications
  await _initializeLocalNotifications();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    debugPrint('✅ Firebase initialized');
    
    // Initialize background service for notifications
    await BackgroundService().initialize();
    debugPrint('✅ Background service initialized');
  } catch (e) {
    debugPrint('❌ Firebase init failed: $e');
  }

  // Load user preferences (language, theme, login/pairing status)
  final prefs = await SharedPreferences.getInstance();

  // Load language
  final String savedLanguageCode = prefs.getString('languageCode') ?? 'en';
  currentLanguageCode = savedLanguageCode;
  await loadStrings();

  // Determine initial theme color based on gender or default color
  final int? savedThemeColorValue = prefs.getInt('appThemeColor');
  final String? savedGender = prefs.getString('userGender');
  Color initialThemeColor;

  if (savedThemeColorValue != null) {
    initialThemeColor = Color(savedThemeColorValue);
  } else {
    if (savedGender == 'male') {
      initialThemeColor = Colors.lightBlue.shade700;
    } else if (savedGender == 'female') {
      initialThemeColor = Colors.pink.shade300;
    } else {
      initialThemeColor = Colors.deepPurple;
    }
  }

  // 2. Determine initial route based on user status
  final String? userHeartCode = prefs.getString('userHeartCode');
  final String? partnerHeartCode = prefs.getString('partnerHeartCode');
  String initialRoute;

  if (userHeartCode != null && userHeartCode.isNotEmpty && partnerHeartCode != null && partnerHeartCode.isNotEmpty) {
    initialRoute = '/dashboard';
  } else if (userHeartCode != null && userHeartCode.isNotEmpty) {
    initialRoute = '/pairing';
  } else {
    initialRoute = '/';
  }

  runApp(MyApp(
    initialRoute: initialRoute,
    initialThemeColor: initialThemeColor,
  ));
}

Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    onDidReceiveLocalNotification:
        (int id, String? title, String? body, String? payload) async {
      debugPrint('iOS foreground notification received: $id, $title, $body, $payload');
    },
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
      debugPrint('Notification tapped: ${notificationResponse.payload}');
      if (notificationResponse.payload == 'i_miss_you_reminder') {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState?.pushNamed('/dashboard');
        } else {
          debugPrint('navigatorKey.currentState is null. Cannot navigate directly.');
        }
      }
    },
  );
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  final Color initialThemeColor;

  const MyApp({
    super.key,
    required this.initialRoute,
    required this.initialThemeColor,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Color _currentThemeColor;

  @override
  void initState() {
    super.initState();
    _currentThemeColor = widget.initialThemeColor;
  }

  void updateTheme(Color newColor) {
    setState(() {
      _currentThemeColor = newColor;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('appThemeColor', newColor.value);
    });
  }

  @override
  void didUpdateWidget(covariant MyApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialThemeColor != oldWidget.initialThemeColor) {
      setState(() {
        _currentThemeColor = widget.initialThemeColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    MaterialColor customSwatch = MaterialColor(_currentThemeColor.value, <int, Color>{
      50: _currentThemeColor.withOpacity(0.1),
      100: _currentThemeColor.withOpacity(0.2),
      200: _currentThemeColor.withOpacity(0.3),
      300: _currentThemeColor.withOpacity(0.4),
      400: _currentThemeColor.withOpacity(0.5),
      500: _currentThemeColor.withOpacity(0.6),
      600: _currentThemeColor.withOpacity(0.7),
      700: _currentThemeColor.withOpacity(0.8),
      800: _currentThemeColor.withOpacity(0.9),
      900: _currentThemeColor.withOpacity(1.0),
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: currentStrings['appTitle'] ?? 'HeartSync',
      theme: ThemeData(
        primaryColor: _currentThemeColor,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: customSwatch,
        ).copyWith(
          surface: Colors.grey.shade800,
          onSurface: Colors.white,
          primary: _currentThemeColor,
          onPrimary: Colors.white,
          secondary: _currentThemeColor.withOpacity(0.7),
          tertiary: _currentThemeColor.withOpacity(0.5),
          error: Colors.red.shade400,
          onError: Colors.white,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white),
          displayMedium: TextStyle(color: Colors.white),
          displaySmall: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: Colors.white),
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _currentThemeColor,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _currentThemeColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _currentThemeColor,
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _currentThemeColor,
            side: BorderSide(color: _currentThemeColor),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade800,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _currentThemeColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade700, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade600, width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.grey.shade800,
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.grey.shade800,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
          contentTextStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        listTileTheme: ListTileThemeData(
          iconColor: _currentThemeColor,
          textColor: Colors.white,
          tileColor: Colors.grey.shade800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _currentThemeColor,
          contentTextStyle: const TextStyle(color: Colors.white),
          actionTextColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),
        useMaterial3: true,
      ),
      initialRoute: widget.initialRoute,
      routes: {
        '/': (context) => const MyHomePage(title: 'Welcome'),
        '/personal_info': (context) => const PersonalInfoScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/pairing': (context) => const PairingScreen(),
        '/settings': (context) => SettingsScreen(
          updateTheme: (colorInt) => updateTheme(Color(colorInt)),
        ),
        '/enhanced_settings': (context) => EnhancedSettingsScreen(
          updateTheme: (colorInt) => updateTheme(Color(colorInt)),
        ),
        '/about': (context) => const AboutScreen(),
        '/i_miss_you_settings': (context) => const IMissYouSettingsScreen(),
        '/qr_scanner': (context) => const QRScannerScreen(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      locale: Locale(currentLanguageCode),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.7), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 100,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentStrings['appTitle'] ?? 'HeartSync',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      currentStrings['welcomeMessage'] ??
                          'Welcome to HeartSync ✨\nLet your heart guide the journey 💖',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/personal_info');
                    },
                    icon: const Icon(Icons.arrow_forward_ios),
                    label: Text(currentStrings['continueButton'] ?? 'Continue'),
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
