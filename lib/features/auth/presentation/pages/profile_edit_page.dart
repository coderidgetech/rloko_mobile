import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../bloc/auth_bloc.dart';

/// Edit profile – design matches React MobileProfileEditPage; API: PUT /auth/profile (phone, birthday).
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  String? _birthdayStr;
  String _gender = 'male';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      _nameController.text = state.user.name;
      _emailController.text = state.user.email;
      _phoneController.text = state.user.phone ?? '';
      _birthdayStr = state.user.birthday;
      _cityController.text = '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await sl<UpdateProfileUseCase>().call(
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        birthday: _birthdayStr != null ? DateTime.tryParse(_birthdayStr!) : null,
      );
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthCheckRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Update your personal information',
                style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryColor(context),
                                AppTheme.primaryColor(context).withValues(alpha: 0.6),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor(context),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to change photo',
                      style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _labeledField(
                label: 'Full Name',
                icon: Icons.person_outline,
                child: TextFormField(
                  controller: _nameController,
                  readOnly: true,
                  decoration: _inputDecoration('Enter your name', Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              _labeledField(
                label: 'Email Address',
                icon: Icons.email_outlined,
                child: TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: _inputDecoration('Enter your email', Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              _labeledField(
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('Enter your phone', Icons.phone_outlined),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isNotEmpty && t.length < 10) return 'Enter a valid phone number';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gender',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['male', 'female', 'other'].map((g) {
                  final selected = _gender == g;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: g != 'other' ? 12 : 0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _gender = g),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.primaryColor(context) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                g == 'male' ? 'Male' : g == 'female' ? 'Female' : 'Other',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: selected ? Colors.white : AppTheme.mutedForegroundColor(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _labeledField(
                label: 'Date of Birth',
                icon: Icons.calendar_today_outlined,
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _birthdayStr != null
                          ? DateTime.tryParse(_birthdayStr!) ?? DateTime.now()
                          : DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _birthdayStr = date.toIso8601String().split('T').first);
                    }
                  },
                  child: InputDecorator(
                    decoration: _inputDecoration('Select date', Icons.calendar_today_outlined),
                    child: Text(
                      _birthdayStr ?? 'Select date',
                      style: TextStyle(
                        color: _birthdayStr != null ? null : AppTheme.mutedForegroundColor(context),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _labeledField(
                label: 'City',
                icon: Icons.location_on_outlined,
                child: TextFormField(
                  controller: _cityController,
                  decoration: _inputDecoration('Enter your city', Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 20),
                            SizedBox(width: 8),
                            Text('Save Changes'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labeledField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.foregroundColor(context).withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.2)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIcon: Icon(icon, size: 20, color: AppTheme.foregroundColor(context).withValues(alpha: 0.4)),
    );
  }
}
