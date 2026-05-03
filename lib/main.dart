import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_preview/device_preview.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'firebase_options.dart';
import 'core/providers/settings_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Set up background messaging handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notifications
  await NotificationService().initialize();
  
  // Print FCM token for testing in Firebase Console
  await NotificationService().getFCMToken();

  // Initialize settings
  await SettingsProvider().loadSettings();
  
  runApp(
    DevicePreview(
      enabled: true, // Set to true to always show, or use a condition
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsProvider(),
      builder: (context, child) {
        return MaterialApp(
          title: 'Smart Billing App',
          useInheritedMediaQuery: true, // For DevicePreview
          locale: DevicePreview.locale(context), // For DevicePreview
          builder: DevicePreview.appBuilder, // For DevicePreview
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: SettingsProvider().themeMode,
          debugShowCheckedModeBanner: false,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const DashboardScreen();
        }
        return const SplashScreen(); // Shows splash then navigates to Login normally
      },
    );
  }
}
