import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/sign_in_to_continue_panel.dart';
import '../../../../core/address/google_places_service.dart';
import '../../../../core/constants/form_hints.dart';
import '../../../../core/constants/phone_input_formatters.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/region/app_region.dart';
import '../../../../core/region/currency_scope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/address_validation.dart';
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
  final GooglePlacesService _places = GooglePlacesService();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _mobileController = TextEditingController();
  String _country = 'United States';

  String _type = 'HOME'; // HOME, OFFICE, OTHER
  bool _isDefault = false;
  bool _isLoading = false;
  bool _loadingAddress = false;
  String? _error;
  /// Default country from [CurrencyScope] must not be read in [initState].
  bool _didApplyDefaultCountry = false;

  /// Defer [GET /addresses/:id] until the user is signed in (avoid 401 + wasted input).
  bool _editLoadPending = false;
  bool _editFetchScheduled = false;

  bool get isEdit => widget.addressId != null;

  @override
  void initState() {
    super.initState();
    final a = widget.initialAddress;
    if (a != null) {
      _fillFromEntity(a);
    } else if (isEdit && widget.addressId != null) {
      _editLoadPending = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyDefaultCountry) return;
    if (widget.initialAddress != null) {
      _didApplyDefaultCountry = true;
      return;
    }
    if (isEdit) {
      _didApplyDefaultCountry = true;
      return;
    }
    _didApplyDefaultCountry = true;
    final scope = CurrencyScope.maybeOf(context);
    _country = scope?.region == AppRegion.india ? 'India' : 'United States';
  }

  void _fillFromEntity(AddressEntity a) {
    _nameController.text = a.name;
    _addressLineController.text = a.addressLine;
    _addressLine2Controller.text = a.addressLine2 ?? '';
    _cityController.text = a.city;
    _stateController.text = a.state;
    _pincodeController.text = a.pincode;
    _mobileController.text = a.mobile;
    _applyCountryForUi(a.country);
    if (a.type == 'HOME' || a.type == 'OFFICE' || a.type == 'OTHER') {
      _type = a.type;
    } else {
      _type = 'HOME';
    }
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
    super.dispose();
  }

  List<TextInputFormatter> get _phoneInputFormatters {
    if (isIndiaCountry(_country) || isUnitedStatesCountry(_country)) {
      return kPhoneLocal10DigitFormatters;
    }
    return [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)];
  }

  List<TextInputFormatter> get _pinInputFormatters {
    if (isIndiaCountry(_country)) {
      return [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)];
    }
    if (isUnitedStatesCountry(_country)) {
      return [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)];
    }
    return [LengthLimitingTextInputFormatter(12)];
  }

  String? _nameValidator(String? v) => validateFullName(v);

  String? _phoneValidator(String? v) => validateMobileForCountry(v, _country);

  String? _pinValidator(String? v) => validatePincodeForCountry(v, _country);

  void _applyCountryForUi(String? raw) {
    final n = normalizeAddressCountry(raw);
    if (n == 'India' || n == 'United States') {
      _country = n;
    } else {
      _country = 'United States';
    }
  }

  String? get _iso2 => GooglePlacesService.iso2ForAddressCountry(_country);

  Future<void> _onPlaceSelected(PlacePrediction p) async {
    final details = await _places.placeDetails(p.placeId);
    if (!mounted || details == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("We couldn't complete that address. Please fill the fields below or try another line."),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _addressLineController.text = details.addressLine;
      _cityController.text = details.city;
      _stateController.text = details.state;
      _pincodeController.text = details.pincode;
      _applyCountryForUi(details.country);
    });
  }

  Widget _countryDropdown() {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use — parent-controlled [value] for load/edit; initialValue is one-shot only
      value: _country == 'India' || _country == 'United States' ? _country : 'United States',
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.backgroundColor(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      borderRadius: BorderRadius.circular(12),
      isExpanded: true,
      items: const [
        DropdownMenuItem(value: 'India', child: Text('India')),
        DropdownMenuItem(value: 'United States', child: Text('United States')),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _country = v;
          final m = _mobileController.text.replaceAll(RegExp(r'\D'), '');
          if (m.length > 10) {
            _mobileController.text = m.substring(0, 10);
          } else {
            _mobileController.text = m;
          }
        });
      },
      validator: (v) => (v == null || v.isEmpty) ? 'Select a country' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final authState = context.watch<AuthBloc>().state;
    final authBusy = authState is AuthInitial || authState is AuthLoading;
    final authed = authState is AuthAuthenticated;

    if (authBusy) {
      return _addFormLoadingScaffold(context, 'Checking your account…');
    }

    if (!authed) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => context.pop(),
          ),
          title: Text(isEdit ? 'Edit Address' : 'Add New Address'),
        ),
        body: SignInToContinuePanel(
          title: isEdit ? 'Sign in to edit this address' : 'Sign in to add an address',
          subtitle:
              'Saved addresses are tied to your account. Sign in to continue, same as the Account tab.',
          returnPath: GoRouterState.of(context).uri.path,
          icon: Icons.person_outline,
        ),
      );
    }

    if (authed && _editLoadPending && isEdit && widget.addressId != null) {
      if (!_editFetchScheduled) {
        _editFetchScheduled = true;
        _editLoadPending = false;
        _loadingAddress = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _loadAddress();
        });
      }
    }

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
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    const Text('Address type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      'Choose where we should deliver',
                      style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
                    ),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TypeCard(
                            label: 'Work',
                            icon: Icons.work_outline,
                            selected: _type == 'OFFICE',
                            onTap: () => setState(() => _type = 'OFFICE'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TypeCard(
                            label: 'Other',
                            icon: Icons.place_outlined,
                            selected: _type == 'OTHER',
                            onTap: () => setState(() => _type = 'OTHER'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Full Name
                    _label('Full name *'),
                    const SizedBox(height: 8),
                    _input(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      hint: FormHints.fullName,
                      validator: _nameValidator,
                    ),
                    const SizedBox(height: 16),
                    // Phone
                    _label('Phone *'),
                    const SizedBox(height: 8),
                    _input(
                      controller: _mobileController,
                      hint: isIndiaCountry(_country) || isUnitedStatesCountry(_country)
                          ? '10-digit mobile number'
                          : FormHints.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: _phoneInputFormatters,
                      validator: _phoneValidator,
                    ),
                    const SizedBox(height: 24),
                    _label('House no., building, street *'),
                    const SizedBox(height: 8),
                    TypeAheadField<PlacePrediction>(
                      debounceDuration: const Duration(milliseconds: 300),
                      controller: _addressLineController,
                      hideOnEmpty: true,
                      hideOnError: true,
                      suggestionsCallback: (pattern) => _places.autocomplete(
                        pattern,
                        countryIso2: _iso2,
                      ),
                      builder: (context, c, focusNode) {
                        return TextFormField(
                          controller: c,
                          focusNode: focusNode,
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.streetAddress,
                          decoration: InputDecoration(
                            hintText: FormHints.streetAddress,
                            filled: true,
                            fillColor: AppTheme.backgroundColor(context),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            errorMaxLines: 2,
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Address line is required' : null,
                        );
                      },
                      itemBuilder: (context, p) {
                        return ListTile(
                          dense: true,
                          title: Text(
                            p.mainText != null && p.mainText!.isNotEmpty
                                ? p.mainText!
                                : p.description.split(',')[0].trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: p.secondaryText != null && p.secondaryText!.isNotEmpty
                              ? Text(p.secondaryText!, maxLines: 2, overflow: TextOverflow.ellipsis)
                              : (p.description.contains(',')
                                  ? Text(
                                      p.description.split(',').skip(1).join(',').trim(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null),
                        );
                      },
                      onSelected: _onPlaceSelected,
                    ),
                    const SizedBox(height: 16),
                    _label('Apartment, suite, landmark (optional)'),
                    const SizedBox(height: 8),
                    _input(
                      controller: _addressLine2Controller,
                      hint: 'Flat, floor, tower (optional)',
                      textCapitalization: TextCapitalization.sentences,
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
                    _label('${isIndiaCountry(_country) ? 'PIN code' : isUnitedStatesCountry(_country) ? 'ZIP code' : 'Postal code'} *'),
                    const SizedBox(height: 8),
                    _input(
                      controller: _pincodeController,
                      hint: isIndiaCountry(_country) ? '6-digit PIN' : (isUnitedStatesCountry(_country) ? '5 or 9 digits' : FormHints.zipCode),
                      keyboardType: TextInputType.number,
                      inputFormatters: _pinInputFormatters,
                      validator: _pinValidator,
                    ),
                    const SizedBox(height: 16),
                    _label('Country *'),
                    const SizedBox(height: 8),
                    _countryDropdown(),
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
                            activeTrackColor: AppTheme.primaryColor(context).withValues(alpha: 0.45),
                            activeThumbColor: AppTheme.primaryForegroundColor(context),
                            inactiveTrackColor: AppTheme.mutedColor(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 20, color: AppTheme.primaryColor(context)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Use a complete, accurate address so your order is delivered on time. '
                              'Couriers and customs use this for shipping quotes.',
                              style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.foregroundColor(context).withValues(alpha: 0.85)),
                            ),
                          ),
                        ],
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
                            Text(isEdit ? 'Update address' : 'Save address'),
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
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppTheme.backgroundColor(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorMaxLines: 2,
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
      country: _country,
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

  Widget _addFormLoadingScaffold(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text(isEdit ? 'Edit Address' : 'Add New Address'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.foregroundColor(context).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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
