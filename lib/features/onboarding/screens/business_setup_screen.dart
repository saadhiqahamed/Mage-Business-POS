import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _typeController = TextEditingController();
  final _addressController = TextEditingController();
  File? _logoFile;

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _logoFile = File(pickedFile.path));
    }
  }

  Future<void> _saveBusinessInfo() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('business_name', _nameController.text.trim());
      await prefs.setString('business_phone', _phoneController.text.trim());
      await prefs.setString('business_type', _typeController.text.trim());
      await prefs.setString('business_address', _addressController.text.trim());

      if (_logoFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final logoPath = '${appDir.path}/business_logo.png';
        await _logoFile!.copy(logoPath);
        await prefs.setString('business_logo_path', logoPath);
      }

      await prefs.setBool('has_setup', true);
      if (mounted) context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Set Up Your Business', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('This info will appear on every bill you print.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),

              // Logo Picker
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A237E), width: 2),
                      image: _logoFile != null ? DecorationImage(image: FileImage(_logoFile!), fit: BoxFit.cover) : null,
                    ),
                    child: _logoFile == null
                        ? const Icon(Icons.add_a_photo, size: 40, color: Color(0xFF1A237E))
                        : null,
                  ),
                ),
              ).animate().scale(),
              const SizedBox(height: 8),
              const Center(child: Text('Add Logo (Optional)', style: TextStyle(color: Colors.grey, fontSize: 12))),
              const SizedBox(height: 32),

              _buildField(_nameController, 'Business Name *', Icons.store),
              const SizedBox(height: 16),
              _buildField(_typeController, 'Business Type (e.g. Retail, Cafe)', Icons.category),
              const SizedBox(height: 16),
              _buildField(_phoneController, 'Contact Number *', Icons.phone, type: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField(_addressController, 'Address (appears on bill)', Icons.location_on, required: false),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _saveBusinessInfo,
                child: const Text('Continue →'),
              ).animate().fade(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text, bool required = true}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
    ).animate().fade().slideX();
  }
}
