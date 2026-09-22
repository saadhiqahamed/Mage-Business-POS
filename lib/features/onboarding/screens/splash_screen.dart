import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/license_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final isLicensed = await LicenseService.isLicensed();
    if (!isLicensed) {
      if (mounted) context.go('/license');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasSetup = prefs.getBool('has_setup') ?? false;

    if (hasSetup) {
      if (mounted) context.go('/dashboard');
    } else {
      if (mounted) context.go('/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/branding/mage_business_logo.png',
              width: 150,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.store,
                size: 150,
                color: Color(0xFFD6A51D),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mage Business',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'Developed by saadhiq_ahamed',
              style: TextStyle(
                color: Color(0xFFD6A51D),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
