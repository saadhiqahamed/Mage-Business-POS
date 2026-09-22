import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/license_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  String _deviceId = '';
  final _keyController = TextEditingController();
  bool _isLoading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceID();
  }

  Future<void> _loadDeviceID() async {
    final id = await LicenseService.getDeviceID();
    setState(() {
      _deviceId = id;
      _isLoading = false;
    });
  }

  Future<void> _activate() async {
    setState(() {
      _errorMsg = '';
    });
    final success = await LicenseService.activateLicense(_keyController.text);
    if (success) {
      if (mounted) {
        context.go('/setup');
      }
    } else {
      setState(() {
        _errorMsg = 'Invalid License Key. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Software Activation'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 80, color: Color(0xFF1A237E)).animate().scale(),
              const SizedBox(height: 24),
              const Text(
                'Mage Business PRO',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please enter your license key to activate this software offline.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Your Device ID:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    SelectableText(
                      _deviceId,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: Color(0xFFD6A51D)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Provide this ID to your software distributor to get your License Key.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 24),
                    
                    TextField(
                      controller: _keyController,
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: 'XXXX-XXXX',
                        filled: true,
                        fillColor: const Color(0xFFF0F4FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    
                    if (_errorMsg.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(_errorMsg, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                      
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _activate,
                        child: const Text('ACTIVATE NOW'),
                      ),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
