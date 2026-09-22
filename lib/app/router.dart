import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/onboarding/screens/splash_screen.dart';
import '../features/onboarding/screens/language_selection_screen.dart';
import '../features/licensing/screens/license_screen.dart';
import '../features/onboarding/screens/business_setup_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/inventory/screens/stock_screen.dart';
import '../features/sales/screens/billing_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/customers/screens/customers_screen.dart';
import '../features/credit/screens/credit_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/drawer/screens/drawer_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/language', builder: (context, state) => const LanguageSelectionScreen()),
      GoRoute(path: '/license', builder: (context, state) => const LicenseScreen()),
      GoRoute(path: '/setup', builder: (context, state) => const BusinessSetupScreen()),
      // Dashboard is now MainShell which includes persistent bottom nav
      GoRoute(path: '/dashboard', builder: (context, state) => const MainShell()),
      // These routes are used for context.push() from places outside MainShell
      GoRoute(path: '/stock', builder: (context, state) => const StockScreen()),
      GoRoute(path: '/billing', builder: (context, state) => const BillingScreen()),
      GoRoute(path: '/customers', builder: (context, state) => const CustomersScreen()),
      GoRoute(path: '/credit', builder: (context, state) => const CreditScreen()),
      GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/drawer', builder: (context, state) => const CashDrawerScreen()),
    ],
  );
});

