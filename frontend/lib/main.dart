import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/user_provider.dart';
import 'package:frames_app/core/auth/token_manager.dart';
import 'package:frames_app/core/config/app_config.dart';
import 'package:frames_app/core/network/dio_client.dart';
import 'package:frames_app/core/repositories/notification_repository.dart';
import 'package:frames_app/core/services/notification_service.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/loading_provider.dart';
import 'package:frames_app/ui/Screens/login_screen.dart';
import 'package:frames_app/ui/Screens/splash_screen.dart';

import 'firebase_options.dart';
import 'ui/Widgets/loading_overlay.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Process and store the notification
  final repository = NotificationRepository();
  await repository.processReceivedNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppConfig().initialize();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await Future.wait([
      TokenManager().initialize(),
      NotificationService().initialize(),
    ]);

    runApp(const ProviderScope(child: MainApp()));
  } catch (e) {
    runApp(const SizedBox());
  }
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // Set up token expired listener safely after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Listen for token expiration
      DioClient().onTokenExpired.listen((_) {
        ref
            .read(errorProvider.notifier)
            .setError('Session expired. Please login');

        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      });

      // Set up push token update callback
      NotificationService().setTokenUpdateCallback((token) {
        // Only update token if user is logged in
        if (ref.read(userProvider) != null) {
          ref.read(userProvider.notifier).updatePushToken(token);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(errorProvider, (previous, next) {
      if (next != null) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              next,
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    ref.listen(messageProvider, (previous, next) {
      if (next != null) {
        Color backgroundColor;
        switch (next.type) {
          case MessageType.info:
            backgroundColor = Colors.blue;
            break;
          case MessageType.success:
            backgroundColor = Colors.green;
            break;
        }

        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              next.text,
              textAlign: TextAlign.center,
            ),
            backgroundColor: backgroundColor,
          ),
        );
      }
    });

    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      navigatorKey: _navigatorKey,
      title: 'FRAMES',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, _) {
            final isLoading = ref.watch(loadingProvider);
            return LoadingOverlay(
              isLoading: isLoading,
              loadingText: 'Loading...',
              child: child!,
            );
          },
        );
      },
      home: const SplashScreen(),
    );
  }
}
