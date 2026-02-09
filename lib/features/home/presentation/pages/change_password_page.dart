import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Change password (mock UI to match React MobileChangePasswordPage).
/// Backend has forgot-password + reset with token; in-app change password can be added later.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a strong password to keep your account secure',
                style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
              ),
              const SizedBox(height: 24),
              TextFormField(
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'New password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading
                      ? null
                      : () {
                          setState(() => _loading = true);
                          Future.delayed(const Duration(milliseconds: 800), () {
                            if (!mounted) return;
                            setState(() => _loading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password changed successfully')),
                            );
                            context.go('/settings');
                          });
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
