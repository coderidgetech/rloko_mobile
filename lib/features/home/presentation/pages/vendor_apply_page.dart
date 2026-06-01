import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';

/// Become a Seller / Vendor Application page.
/// Calls POST /vendor/apply (public, no auth required).
/// Matches the web VendorApplyPage form fields exactly.
class VendorApplyPage extends StatefulWidget {
  const VendorApplyPage({super.key});

  @override
  State<VendorApplyPage> createState() => _VendorApplyPageState();
}

class _VendorApplyPageState extends State<VendorApplyPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  // ── Form fields ──────────────────────────────────────────────────────────
  final _businessNameCtrl = TextEditingController();
  String _businessType = 'individual';
  final _gstCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();

  final _contactNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  final _address1Ctrl = TextEditingController();
  final _address2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _state = 'Maharashtra';
  final _pinCodeCtrl = TextEditingController();

  String _category = "Women's Clothing";
  final _productDescCtrl = TextEditingController();
  final _priceRangeCtrl = TextEditingController();
  final _estimatedListingsCtrl = TextEditingController();
  String _howHeard = 'social_media';
  final _messageCtrl = TextEditingController();

  static const _businessTypes = [
    ('individual', 'Individual / Freelancer'),
    ('small_business', 'Small Business'),
    ('brand', 'Established Brand'),
    ('manufacturer', 'Manufacturer'),
  ];

  static const _categories = [
    "Women's Clothing",
    "Men's Clothing",
    "Kids' Clothing",
    'Ethnic & Festive Wear',
    'Accessories',
    'Footwear',
    'Jewellery',
    'Bags & Handbags',
    'Home & Living',
    'Beauty & Wellness',
    'Activewear',
    'Vintage & Handmade',
    'Other',
  ];

  static const _howHeardOptions = [
    ('social_media', 'Social Media'),
    ('friend', 'Friend / Referral'),
    ('search_engine', 'Search Engine'),
    ('advertisement', 'Advertisement'),
    ('other', 'Other'),
  ];

  static const _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
    'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
    'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
    'West Bengal', 'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Puducherry',
    'Chandigarh',
  ];

  @override
  void dispose() {
    for (final c in [
      _businessNameCtrl, _gstCtrl, _websiteCtrl, _instagramCtrl,
      _contactNameCtrl, _emailCtrl, _phoneCtrl, _whatsappCtrl,
      _address1Ctrl, _address2Ctrl, _cityCtrl, _pinCodeCtrl,
      _productDescCtrl, _priceRangeCtrl, _estimatedListingsCtrl, _messageCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dioClient = sl<DioClient>();
      await dioClient.dio.post('/vendor/apply', data: {
        'business_name': _businessNameCtrl.text.trim(),
        'business_type': _businessType,
        if (_gstCtrl.text.trim().isNotEmpty)
          'gst_number': _gstCtrl.text.trim(),
        if (_websiteCtrl.text.trim().isNotEmpty)
          'website': _websiteCtrl.text.trim(),
        if (_instagramCtrl.text.trim().isNotEmpty)
          'instagram': _instagramCtrl.text.trim(),
        'contact_name': _contactNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        if (_whatsappCtrl.text.trim().isNotEmpty)
          'whatsapp': _whatsappCtrl.text.trim(),
        'address_line1': _address1Ctrl.text.trim(),
        if (_address2Ctrl.text.trim().isNotEmpty)
          'address_line2': _address2Ctrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _state,
        'pin_code': _pinCodeCtrl.text.trim(),
        'country': 'India',
        'category': _category,
        'product_description': _productDescCtrl.text.trim(),
        'price_range': _priceRangeCtrl.text.trim(),
        'estimated_listings': _estimatedListingsCtrl.text.trim(),
        'how_did_you_hear': _howHeard,
        if (_messageCtrl.text.trim().isNotEmpty)
          'message': _messageCtrl.text.trim(),
      });
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      final msg = getApiException(e)?.message ?? 'Submission failed. Please try again.';
      if (mounted) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: const Text('Become a Seller'),
        backgroundColor: AppTheme.backgroundColor(context),
        foregroundColor: AppTheme.foregroundColor(context),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  size: 64, color: Colors.green),
            ),
            const SizedBox(height: 24),
            const Text(
              'Application Submitted!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Thank you for applying to sell on Rloko. We'll review your application and get back to you within 2–3 business days.",
              style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.mutedForegroundColor(context),
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go('/'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    AppTheme.primaryColor(context).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.primaryColor(context)
                        .withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor(context)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.storefront_outlined,
                        color: AppTheme.primaryColor(context), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sell on Rloko',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Reach thousands of fashion-conscious customers.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedForegroundColor(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Error banner
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.destructive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: AppTheme.destructive),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.destructive)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Business Information ────────────────────────────────────
            _SectionHeader('Business Information'),
            _Field(
              label: 'Business name *',
              controller: _businessNameCtrl,
              hint: 'Your brand or business name',
              validator: _required,
            ),
            _DropdownField<String>(
              label: 'Business type *',
              value: _businessType,
              items: _businessTypes
                  .map((t) => DropdownMenuItem(
                      value: t.$1, child: Text(t.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _businessType = v ?? _businessType),
            ),
            _Field(
              label: 'GST number (optional)',
              controller: _gstCtrl,
              hint: 'e.g. 27AAPFU0939F1ZV',
            ),
            _Field(
              label: 'Website (optional)',
              controller: _websiteCtrl,
              hint: 'https://yourbrand.com',
              keyboardType: TextInputType.url,
            ),
            _Field(
              label: 'Instagram handle (optional)',
              controller: _instagramCtrl,
              hint: '@yourbrand',
            ),

            // ── Contact Details ─────────────────────────────────────────
            _SectionHeader('Contact Details'),
            _Field(
              label: 'Contact name *',
              controller: _contactNameCtrl,
              hint: 'Full name',
              validator: _required,
            ),
            _Field(
              label: 'Email address *',
              controller: _emailCtrl,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            _Field(
              label: 'Phone number *',
              controller: _phoneCtrl,
              hint: '+91 98765 43210',
              keyboardType: TextInputType.phone,
              validator: _required,
            ),
            _Field(
              label: 'WhatsApp (optional)',
              controller: _whatsappCtrl,
              hint: '+91 98765 43210',
              keyboardType: TextInputType.phone,
            ),

            // ── Address ─────────────────────────────────────────────────
            _SectionHeader('Business Address'),
            _Field(
              label: 'Address line 1 *',
              controller: _address1Ctrl,
              hint: 'Street address, building',
              validator: _required,
            ),
            _Field(
              label: 'Address line 2 (optional)',
              controller: _address2Ctrl,
              hint: 'Floor, unit, etc.',
            ),
            _Field(
              label: 'City *',
              controller: _cityCtrl,
              hint: 'Mumbai',
              validator: _required,
            ),
            _DropdownField<String>(
              label: 'State *',
              value: _state,
              items: _indianStates
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _state = v ?? _state),
            ),
            _Field(
              label: 'PIN code *',
              controller: _pinCodeCtrl,
              hint: '400001',
              keyboardType: TextInputType.number,
              validator: _required,
            ),

            // ── Product Details ─────────────────────────────────────────
            _SectionHeader('Product Details'),
            _DropdownField<String>(
              label: 'Primary category *',
              value: _category,
              items: _categories
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _category = v ?? _category),
            ),
            _Field(
              label: 'Product description *',
              controller: _productDescCtrl,
              hint:
                  'Describe your products, materials, and what makes them unique',
              maxLines: 4,
              validator: _required,
            ),
            _Field(
              label: 'Price range *',
              controller: _priceRangeCtrl,
              hint: 'e.g. ₹500 – ₹5,000',
              validator: _required,
            ),
            _Field(
              label: 'Estimated listings *',
              controller: _estimatedListingsCtrl,
              hint: 'How many products do you plan to list?',
              keyboardType: TextInputType.number,
              validator: _required,
            ),
            _DropdownField<String>(
              label: 'How did you hear about us? *',
              value: _howHeard,
              items: _howHeardOptions
                  .map((o) => DropdownMenuItem(
                      value: o.$1, child: Text(o.$2)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _howHeard = v ?? _howHeard),
            ),
            _Field(
              label: 'Additional message (optional)',
              controller: _messageCtrl,
              hint: 'Anything else you want to tell us?',
              maxLines: 3,
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Submit Application',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}

// ── Helper widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Divider(
              height: 1,
              color:
                  AppTheme.foregroundColor(context).withValues(alpha: 0.1)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        isExpanded: true,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
