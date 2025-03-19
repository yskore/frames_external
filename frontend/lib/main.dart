import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/auth/token_manager.dart';
import 'package:frames_app/core/config/app_config.dart';
import 'package:frames_app/core/network/dio_client.dart';
import 'package:frames_app/core/services/email_service.dart';
import 'package:frames_app/core/services/storage_service.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/loading_provider.dart';
import 'package:frames_app/ui/Screens/login_screen.dart';
import 'package:frames_app/ui/Screens/splash_screen.dart';

import 'ui/Widgets/loading_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppConfig().initialize();
    await Future.wait([
      TokenManager().initialize(),
      EmailService().initialize(),
      StorageService().initialize(),
    ]);

    runApp(const ProviderScope(child: MainApp()));
  } catch (e) {
    debugPrint('Error during initialization: $e');
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
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for error messages
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
