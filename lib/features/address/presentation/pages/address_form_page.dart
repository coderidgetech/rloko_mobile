import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/form_hints.dart';
import '../../../../core/constants/phone_input_formatters.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/region/app_region.dart';
import '../../../../core/region/currency_scope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/usecases/address_usecases.dart';

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({
    super.key,
    this.addressId,
    this.initialAddress,
  });

  final String? addressId;
  final AddressEntity? initialAddress;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _mobileController = TextEditingController();
  final _countryController = TextEditingController();

  String _type = 'HOME'; // HOME, OFFICE (Work)
  bool _isDefault = false;
  bool _isLoading = false;
  bool _loadingAddress = false;
  String? _error;

  bool get isEdit => widget.addressId != null;

  @override
  void initState() {
    super.initState();
    final a = widget.initialAddress;
    if (a != null) {
      _fillFromEntity(a);
    } else if (isEdit && widget.addressId != null) {
      _loadingAddress = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAddress());
    } else {
      final scope = CurrencyScope.maybeOf(context);
      _countryController.text = scope?.region == AppRegion.india ? 'India' : 'USA';
    }
  }

  void _fillFromEntity(AddressEntity a) {
    _nameController.text = a.name;
    _addressLineController.text = a.addressLine;
    _addressLine2Controller.text = a.addressLine2 ?? '';
    _cityController.text = a.city;
    _stateController.text = a.state;
    _pincodeController.text = a.pincode;
    _mobileController.text = a.mobile;
    _countryController.text = a.country;
    _type = a.type;
    _isDefault = a.isDefault;
  }

  Future<void> _loadAddress() async {
    if (widget.addressId == null) return;
    try {
      final a = await sl<GetAddressByIdUseCase>().call(widget.addressId!);
      if (mounted) {
        setState(() {
          _fillFromEntity(a);
          _loadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingAddress = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressLineController.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _mobileController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    if (_loadingAddress) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
          title: Text(isEdit ? 'Edit Address' : 'Add New Address'),
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Fixed header – match React
            Container(
              padding: EdgeInsets.only(top: topPadding, left: 16, right: 16, bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor(context),
                border: Border(bottom: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.08))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Material(
                    color: AppTheme.foregroundColor(context).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.chevron_left, size: 24),
                      ),
                    ),
                  ),
                  Text(
                    isEdit ? 'Edit Address' : 'Add New Address',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    // Delivery Details section – match React
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 20, color: AppTheme.primaryColor(context)),
                        const SizedBox(width: 8),
                        const Text(
                          'Delivery Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add a new delivery address for your orders',
                      style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 24),
                    // Address type – Home / Work cards
                    const Text('Address Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeCard(
                            label: 'Home',
                            icon: Icons.home_outlined,
                            selected: _type == 'HOME',
                            onTap: () => setState(() => _type = 'HOME'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TypeCard(
                            label: 'Work',
                            icon: Icons.work_outline,
                            selected: _type == 'OFFICE',
                            onTap: () => setState(() => _type = 'OFFICE'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Full Name
                    _label('Full Name *'),
                    const SizedBox(height: 8),
                    _input(
                      controller: _nameController,
                      hint: FormHints.fullName,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Phone
                    _label('Phone Number *'),
                    const SizedBox(height: 8),
                    _input(
                      controller: _mobileController,
                      hint: FormHints.phone,
                      keyboardType: TextInputType.number,
                      inputFormatters: kPhoneLocal10DigitFormatters,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    // Street
                    _label('Street Address *'),
                    const SizedBox(height: 8),
                    _input(
                      controller: _addressLineController,
                      hint: FormHints.streetAddress,
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    // City, State
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('City *'),
                              const SizedBox(height: 8),
                              _input(
                                controller: _cityController,
                                hint: FormHints.city,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('State *'),
                              const SizedBox(height: 8),
                              _input(
                                controller: _stateController,
                                hint: FormHints.state,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ZIP, Country
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('ZIP Code *'),
                              const SizedBox(height: 8),
                              _input(
                                controller: _pincodeController,
                                hint: FormHints.zipCode,
                                keyboardType: TextInputType.number,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Country'),
                              const SizedBox(height: 8),
                              _input(
                                controller: _countryController,
                                hint: FormHints.country,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Set as default – match React toggle row
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Set as default address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(
                                  'Use this address for future orders',
                                  style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isDefault,
                            onChanged: (v) => setState(() => _isDefault = v),
                            activeColor: AppTheme.primaryColor(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Tip box – match React
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // blue-50
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '💡 Tip: Make sure your address is complete and accurate to avoid delivery delays.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.destructive.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!, style: const TextStyle(color: AppTheme.destructive)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Sticky bottom – Save Address
            Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor(context),
                border: Border(top: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    backgroundColor: AppTheme.primaryColor(context),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text(isEdit ? 'Save Address' : 'Save Address'),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500));
  }

  Widget _input({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppTheme.backgroundColor(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final street = _addressLineController.text.trim();
    final line2 = _addressLine2Controller.text.trim();

    final entity = AddressEntity(
      id: widget.addressId ?? '',
      userId: widget.initialAddress?.userId ?? '',
      name: _nameController.text.trim(),
      type: _type,
      addressLine: street,
      addressLine2: line2.isEmpty ? null : line2,
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      mobile: _mobileController.text.trim(),
      country: _countryController.text.trim(),
      isDefault: _isDefault,
      createdAt: widget.initialAddress?.createdAt ?? '',
      updatedAt: widget.initialAddress?.updatedAt ?? '',
    );

    try {
      if (isEdit && widget.addressId != null) {
        await sl<UpdateAddressUseCase>().call(widget.addressId!, entity);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address updated')),
          );
          context.pop(true);
        }
      } else {
        await sl<CreateAddressUseCase>().call(entity);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address saved successfully!')),
          );
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor(context).withValues(alpha: 0.05) : AppTheme.backgroundColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.12),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: selected ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
