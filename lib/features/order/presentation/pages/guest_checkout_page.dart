import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/phone_input_formatters.dart';
import '../../../../core/constants/shipping.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../shipping/domain/entities/calculate_shipping_params.dart';
import '../../../shipping/domain/entities/shipping_method_entity.dart';
import '../../../shipping/domain/usecases/calculate_shipping_usecase.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/order_usecases.dart';

/// Guest checkout — COD only, no account required.
class GuestCheckoutPage extends StatefulWidget {
  const GuestCheckoutPage({super.key});

  @override
  State<GuestCheckoutPage> createState() => _GuestCheckoutPageState();
}

class _GuestCheckoutPageState extends State<GuestCheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  // Personal
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Address
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  String _country = 'India';

  bool _placing = false;

  // Shipping rate selection (so guest orders honor the chosen rate, not the cheapest).
  List<ShippingMethodEntity> _shippingMethods = [];
  String? _selectedShippingMethodId;
  bool _ratesLoading = false;
  String? _ratesError;

  static const _countries = ['India', 'United States'];

  ShippingMethodEntity? get _selectedShippingMethod {
    for (final m in _shippingMethods) {
      if (m.id == _selectedShippingMethodId) return m;
    }
    return null;
  }

  Future<void> _fetchRates(List<CartItemEntity> cartItems) async {
    if (cartItems.isEmpty) return;
    final subtotal = cartItems.fold<double>(0, (s, i) => s + i.price * i.quantity);
    final weight = cartItems.fold<double>(0, (s, i) => s + i.quantity * kDefaultItemWeightLb);
    setState(() {
      _ratesLoading = true;
      _ratesError = null;
    });
    try {
      final methods = await sl<CalculateShippingUseCase>().call(
        CalculateShippingParams(
          country: _country,
          state: _stateController.text.trim(),
          city: _cityController.text.trim(),
          address: _addressController.text.trim(),
          postalCode: _zipController.text.trim(),
          firstName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          subtotal: subtotal,
          weight: weight > 0 ? weight : kDefaultItemWeightLb,
        ),
      );
      if (!mounted) return;
      setState(() {
        _shippingMethods = methods;
        _selectedShippingMethodId = methods.isNotEmpty ? methods.first.id : null;
        _ratesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ratesError = 'Could not load delivery options. You can still place your order.';
        _ratesLoading = false;
      });
    }
  }

  Widget _buildDeliveryOptions(List<CartItemEntity> cartItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Delivery options',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foregroundColor(context).withValues(alpha: 0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: _ratesLoading ? null : () => _fetchRates(cartItems),
              child: Text(_shippingMethods.isEmpty ? 'Show options' : 'Refresh'),
            ),
          ],
        ),
        if (_ratesLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
        if (_ratesError != null)
          Text(
            _ratesError!,
            style: TextStyle(fontSize: 12, color: AppTheme.mutedForegroundColor(context)),
          ),
        ..._shippingMethods.map((m) {
          final selected = m.id == _selectedShippingMethodId;
          final cost = m.baseCost == 0
              ? 'Free'
              : (m.currency == 'USD'
                  ? '\$${m.baseCost.toStringAsFixed(2)}'
                  : '₹${m.baseCost.round()}');
          return InkWell(
            onTap: () => setState(() => _selectedShippingMethodId = m.id),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? AppTheme.primaryColor(context)
                      : AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 18,
                    color: selected
                        ? AppTheme.primaryColor(context)
                        : AppTheme.mutedForegroundColor(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(
                          '${m.carrier} · ${m.estimatedDays} days',
                          style: TextStyle(fontSize: 12, color: AppTheme.mutedForegroundColor(context)),
                        ),
                      ],
                    ),
                  ),
                  Text(cost, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(List<CartItemEntity> cartItems) async {
    if (!_formKey.currentState!.validate()) return;
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }
    setState(() => _placing = true);
    try {
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final items = cartItems
          .map((item) => OrderItemEntity(
                productId: item.productId,
                productName: item.productName,
                image: item.image,
                price: item.price,
                size: item.size,
                quantity: item.quantity,
              ))
          .toList();

      final shipping = ShippingInfoEntity(
        firstName: firstName,
        lastName: lastName,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipController.text.trim(),
        country: _country,
      );

      final order = await sl<CreateGuestOrderUseCase>().call(
        guestEmail: _emailController.text.trim(),
        guestName: _nameController.text.trim(),
        items: items,
        shippingInfo: shipping,
        shippingCarrier: _selectedShippingMethod?.carrier,
        shippingService: _selectedShippingMethod?.name,
      );

      if (!mounted) return;
      // Clear cart after successful guest order
      context.read<CartBloc>().add(const CartClearRequested());
      context.go('/order-confirmation/${order.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          final cartItems = cartState is CartLoaded ? cartState.cart.items : <CartItemEntity>[];
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Guest Checkout',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cash on Delivery · No account required',
                    style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
                  ),
                  const SizedBox(height: 8),
                  _InfoBanner(),
                  const SizedBox(height: 24),

                  // Order summary
                  if (cartItems.isNotEmpty) ...[
                    _sectionHeader('Order Summary (${cartItems.length} item${cartItems.length == 1 ? '' : 's'})'),
                    const SizedBox(height: 8),
                    ...cartItems.map((item) => _OrderSummaryRow(item: item)),
                    const SizedBox(height: 20),
                  ],

                  _sectionHeader('Your Details'),
                  const SizedBox(height: 12),
                  _field(
                    label: 'Full Name',
                    controller: _nameController,
                    hint: 'First and last name',
                    icon: Icons.person_outline,
                    validator: (v) => (v?.trim() ?? '').isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    label: 'Email',
                    controller: _emailController,
                    hint: 'you@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if ((v?.trim() ?? '').isEmpty) return 'Email is required';
                      if (!(v ?? '').contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(
                    label: 'Phone',
                    controller: _phoneController,
                    hint: '10-digit number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: kPhoneLocal10DigitFormatters,
                    validator: (v) {
                      if ((v?.trim() ?? '').isEmpty) return 'Phone is required';
                      if ((v?.trim().length ?? 0) < 10) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  _sectionHeader('Delivery Address'),
                  const SizedBox(height: 12),
                  _field(
                    label: 'Street Address',
                    controller: _addressController,
                    hint: 'House no., street, locality',
                    icon: Icons.home_outlined,
                    validator: (v) => (v?.trim() ?? '').isEmpty ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: 'City',
                          controller: _cityController,
                          hint: 'City',
                          icon: Icons.location_city_outlined,
                          validator: (v) => (v?.trim() ?? '').isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          label: 'State',
                          controller: _stateController,
                          hint: 'State',
                          icon: Icons.map_outlined,
                          validator: (v) => (v?.trim() ?? '').isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: 'PIN / ZIP',
                          controller: _zipController,
                          hint: '000000',
                          icon: Icons.pin_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v?.trim() ?? '').isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Country',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.foregroundColor(context).withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: _country,
                                isExpanded: true,
                                underline: const SizedBox.shrink(),
                                items: _countries
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14))))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _country = v);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Delivery options — optional rate selection (defaults to cheapest)
                  _buildDeliveryOptions(cartItems),
                  const SizedBox(height: 24),

                  // Payment method — COD only
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.mutedColor(context).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payments_outlined, color: AppTheme.primaryColor(context)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cash on Delivery', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                'Pay when your order arrives',
                                style: TextStyle(fontSize: 12, color: AppTheme.mutedForegroundColor(context)),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.check_circle, color: AppTheme.primaryColor(context)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _placing ? null : () => _placeOrder(cartItems),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _placing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Place Order (COD)', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/login', extra: '/checkout'),
                      child: Text(
                        'Already have an account? Sign in for faster checkout',
                        style: TextStyle(fontSize: 12, color: AppTheme.mutedForegroundColor(context)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<dynamic>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.foregroundColor(context).withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters?.cast() ?? [],
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            prefixIcon: Icon(icon, size: 18, color: AppTheme.foregroundColor(context).withValues(alpha: 0.4)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.2)),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Guest orders use Cash on Delivery only. Sign in for card/UPI payment and to track your order history.',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryRow extends StatelessWidget {
  const _OrderSummaryRow({required this.item});
  final CartItemEntity item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.productName,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${item.size} · ×${item.quantity}',
            style: TextStyle(fontSize: 12, color: AppTheme.mutedForegroundColor(context)),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${(item.price * item.quantity).toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
