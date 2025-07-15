import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/auth/token_manager.dart';
import 'package:frames_app/core/mixins/loading_mixin.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/home_screen.dart';
import 'package:frames_app/ui/Screens/login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with LoadingMixin {
  bool _redirectionInProgress = false;

  @override
  void initState() {
    super.initState();
    // Small delay to ensure the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRedirect();
    });
  }

  Future<void> _checkAuthAndRedirect() async {
    if (_redirectionInProgress) return;
    _redirectionInProgress = true;

    // Set loading state to true
    setLoading(true);

    // Add a small delay to show the splash screen
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    try {
      if (TokenManager().hasToken && TokenManager().username != null) {
        // Try to get user profile
        final success = await ref
            .read(userProvider.notifier)
            .getUserProfile(TokenManager().username!);

        if (!mounted) return;

        if (success) {
          // Valid token and profile loaded successfully
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // Profile loading failed, go to login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        // No token or username, go to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } finally {
      // Always turn off loading when done with auth check
      if (mounted) {
        setLoading(false);
      }
      _redirectionInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
