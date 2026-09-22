import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_config.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final username = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Default offline admin login
    if (username == 'admin1' && password == 'admin1') {
      if (mounted) context.go('/dashboard');
      return;
    }

    if (!SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use admin1 / admin1 to login offline, or configure Supabase.')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: username,
        password: password,
      );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010), // Premium dark background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo placeholder or image
                Image.asset(
                  'assets/branding/mage_business_logo.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.storefront, size: 100, color: Color(0xFFD6A51D)),
                ).animate().fade(duration: 500.ms).scale(curve: Curves.easeOutBack),
                
                const SizedBox(height: 32),
                
                const Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Sign in to manage your business',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ).animate().fade(delay: 300.ms).slideY(begin: 0.2),

                const SizedBox(height: 48),

                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Username or Email (e.g. admin1)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFD6A51D)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ).animate().fade(delay: 400.ms).slideX(begin: 0.1),

                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFD6A51D)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: true,
                ).animate().fade(delay: 500.ms).slideX(begin: 0.1),

                const SizedBox(height: 32),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFFD6A51D)))
                else
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD6A51D),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ).animate().fade(delay: 600.ms).scale(curve: Curves.easeOutBack),

                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () => context.go('/dashboard'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('Create Account / Offline Mode'),
                ).animate().fade(delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
