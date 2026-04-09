import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'firebase_options.dart';
import 'services/local_bus_alert_notification_service.dart';

/// Splash
import 'screens/splash_screen.dart';

/// Roles
import 'screens/role_selection_screen.dart';

/// Main Screens
import 'screens/passenger_screen.dart';
import 'screens/driver_screen.dart';
import 'screens/conductor_screen.dart';

/// Passenger Features
import 'screens/passenger/track_bus_screen.dart';
import 'screens/passenger_mapscreen.dart';
import 'screens/passenger/routes_screen.dart';
import 'screens/passenger/schedule_screen.dart';
import 'screens/passenger/ticket_screen.dart';
import 'screens/passenger/mytickets_screen.dart';
import 'screens/passenger/history_screen.dart';
import 'screens/passenger/profile_screen.dart';
import 'screens/passenger/alerts_screen.dart';
import 'screens/passenger/ai_features_screen.dart';
import 'screens/admin/transport_control_dashboard_screen.dart';

/// Chatbot
import 'screens/chatbot_screen.dart';

/// Help AI
import 'screens/help_screen.dart';

Future<void> _enableScreenProtection() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    // Some Android launches can restore a pre-existing default Firebase app.
    if (e.code != 'duplicate-app') rethrow;
  }

  await _enableScreenProtection();
  await LocalBusAlertNotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme() {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF4F8CFF),
      onPrimary: Color(0xFF021534),
      secondary: Color(0xFF7C4DFF),
      onSecondary: Colors.white,
      tertiary: Color(0xFF2EC4B6),
      surface: Color(0xFF111B26),
      onSurface: Color(0xFFE8EEF7),
      error: Color(0xFFFF6B6B),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF09121C),
      canvasColor: const Color(0xFF0F1A26),
      dividerColor: const Color(0xFF27384A),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF0F1A26),
        foregroundColor: Color(0xFFE8EEF7),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 28,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
        ),
        titleSmall: TextStyle(
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: Color(0xFFB7C2CE),
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          letterSpacing: 0.2,
        ),
      ).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF132131),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFF2A3F53)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF162433),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2E455B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4F8CFF), width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          foregroundColor: colorScheme.onSurface,
          side: const BorderSide(color: Color(0xFF3A536A)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF152434),
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF7C4DFF),
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF18283A),
        selectedColor: colorScheme.primary.withValues(alpha: 0.18),
        side: const BorderSide(color: Color(0xFF31485F)),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Smart Transport System",
      themeMode: ThemeMode.dark,
      darkTheme: _buildTheme(),
      theme: _buildTheme(),
      home: const SplashScreen(),
      routes: {
        /// Roles
        '/roles': (context) => const RoleSelectionScreen(),

        '/passenger': (context) => const PassengerScreen(),
        '/driver': (context) => const DriverScreen(),
        '/conductor': (context) => const ConductorScreen(),

        /// Passenger
        '/trackbus': (context) => const TrackBusScreen(),
        '/city-map': (context) => const PassengerMapScreen(),
        '/routes': (context) => const RoutesScreen(),
        '/schedule': (context) => const ScheduleScreen(),
        '/tickets': (context) => const TicketScreen(),
        '/mytickets': (context) => const MyTicketsScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/alerts': (context) => const AlertsScreen(),
        '/ai-features': (context) => const AIFeaturesScreen(),
        '/admin-control': (context) => const TransportControlDashboardScreen(),

        /// Help + Chatbot
        '/chatbot': (context) => const ChatbotScreen(),
        '/help': (context) => const HelpScreen(),
      },
    );
  }
}
