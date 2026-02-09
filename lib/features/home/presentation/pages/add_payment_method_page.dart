import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/form_hints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Add payment method – design matches React MobileAddPaymentMethodPage (mock).
class AddPaymentMethodPage extends StatefulWidget {
  const AddPaymentMethodPage({super.key});

  @override
  State<AddPaymentMethodPage> createState() => _AddPaymentMethodPageState();
}

class _AddPaymentMethodPageState extends State<AddPaymentMethodPage> {
  bool _isCard = true;
  bool _loading = false;
  final _cardNumber = TextEditingController();
  final _cardName = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _upiId = TextEditingController();

  @override
  void dispose() {
    _cardNumber.dispose();
    _cardName.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _upiId.dispose();
    super.dispose();
  }

  String _formatCardNumber(String value) {
    final cleaned = value.replaceAll(RegExp(r'\s'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < cleaned.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length >= 2) {
      return '${cleaned.substring(0, 2)}/${cleaned.substring(2, cleaned.length > 4 ? 4 : cleaned.length)}';
    }
    return cleaned;
  }

  void _submit() {
    if (_loading) return;
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment method added successfully!')),
      );
      context.go('/payment-methods');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Payment Method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose your preferred payment method',
              style: TextStyle(fontSize: 12, color: AppTheme.mutedForegroundColor(context)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _typeChip(
                    icon: Icons.credit_card,
                    label: 'Card',
                    selected: _isCard,
                    onTap: () => setState(() => _isCard = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _typeChip(
                    icon: Icons.smartphone,
                    label: 'UPI',
                    selected: !_isCard,
                    onTap: () => setState(() => _isCard = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isCard) ...[
              _field('Card Number', (v) {
                final formatted = _formatCardNumber(v);
                if (formatted != _cardNumber.text) {
                  _cardNumber.text = formatted;
                  _cardNumber.selection = TextSelection.collapsed(offset: formatted.length);
                }
              }, controller: _cardNumber, hint: FormHints.cardNumber, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _field('Cardholder Name', (v) => _cardName.text = v.toUpperCase(),
                  controller: _cardName, hint: FormHints.nameOnCard),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field('Expiry Date', (v) {
                      final formatted = _formatExpiry(v);
                      if (formatted != _expiry.text) {
                        _expiry.text = formatted;
                        _expiry.selection = TextSelection.collapsed(offset: formatted.length);
                      }
                    }, controller: _expiry, hint: FormHints.expiryDate, keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field('CVV', (v) {
                      if (v.length > 3) _cvv.text = v.substring(0, 3);
                    }, controller: _cvv, hint: FormHints.cvv, obscure: true, keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor(context),
                      AppTheme.primaryColor(context).withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor(context).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Icon(Icons.credit_card, size: 24, color: Colors.white.withValues(alpha: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _cardNumber.text.isEmpty ? '•••• •••• •••• ••••' : _cardNumber.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cardholder',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              _cardName.text.isEmpty ? 'YOUR NAME' : _cardName.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Expires',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              _expiry.text.isEmpty ? 'MM/YY' : _expiry.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              _field('UPI ID', (v) => _upiId.text = v.toLowerCase(),
                  controller: _upiId, hint: FormHints.upiId),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.smartphone, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How to find your UPI ID?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Open your UPI app\n• Go to Profile or Settings\n• Copy your UPI ID',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedForegroundColor(context),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Secure & Encrypted',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'CVV is never stored. All transactions are protected with bank-grade security.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Add Payment Method'),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor(context).withValues(alpha: 0.05) : Colors.white,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryColor(context) : AppTheme.mutedColor(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.mutedForegroundColor(context)),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppTheme.primaryColor(context) : null,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                Icon(Icons.check, size: 16, color: AppTheme.primaryColor(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    ValueChanged<String> onChanged, {
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.foregroundColor(context).withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.2)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
