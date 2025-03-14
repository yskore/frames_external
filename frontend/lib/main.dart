import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Screens/login_screen.dart';
import 'package:frames_app/core/auth/token_manager.dart';
import 'package:frames_app/core/config/app_config.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/loading_provider.dart';
import 'package:frames_app/widgets/loading_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppConfig().initialize();
    await TokenManager().initialize();

    runApp(const ProviderScope(child: MainApp()));
  } catch (e) {
    print('Error during initialization: $e');
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

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider);

    ref.listen(errorProvider, (previous, next) {
      if (next != null) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              next,
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.red,
            // action: SnackBarAction(
            //   label: 'Dismiss',
            //   textColor: Colors.white,
            //   onPressed: () {
            //     _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
            //     ref.read(errorProvider.notifier).clearError();
            //   },
            // ),
          ),
        );
      }
    });

    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'FRAMES',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: LoadingOverlay(
        isLoading: isLoading,
        loadingText: 'Please wait...',
        child: const LoginScreen(),
      ),
    );
  }
}
