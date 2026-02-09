import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../shipping/domain/entities/shipping_method_entity.dart';
import '../../../shipping/domain/usecases/get_shipping_methods_usecase.dart';

/// Shipping Info – uses GET /shipping/methods API; design matches React ShippingPage.
class ShippingInfoPage extends StatefulWidget {
  const ShippingInfoPage({super.key});

  @override
  State<ShippingInfoPage> createState() => _ShippingInfoPageState();
}

class _ShippingInfoPageState extends State<ShippingInfoPage> {
  List<ShippingMethodEntity> _methods = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await sl<GetShippingMethodsUseCase>().call();
      if (!mounted) return;
      setState(() {
        _methods = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.05))),
              ),
              child: Column(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 24, color: AppTheme.mutedForegroundColor(context)),
                  const SizedBox(height: 8),
                  Text(
                    'DELIVERY INFORMATION',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 3,
                      color: AppTheme.mutedForegroundColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Shipping & Returns',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fast, reliable shipping and hassle-free returns. Your satisfaction is our priority.',
                    style: TextStyle(fontSize: 16, color: AppTheme.mutedForegroundColor(context)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              color: AppTheme.foregroundColor(context).withValues(alpha: 0.02),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _quickFact(Icons.local_shipping_outlined, 'Free Shipping', 'On orders over ₹2000'),
                  _quickFact(Icons.schedule, '5-7 Days', 'Standard delivery'),
                  _quickFact(Icons.replay, '30-Day Returns', 'Easy returns policy'),
                  _quickFact(Icons.check_circle_outline, 'Secure Packaging', 'Safe & protected'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 24, color: AppTheme.mutedForegroundColor(context)),
                      const SizedBox(width: 12),
                      const Text(
                        'Shipping Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Shipping Methods',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(strokeWidth: 2)))
                  else if (_error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(_error!, style: TextStyle(color: AppTheme.mutedForegroundColor(context))),
                            const SizedBox(height: 8),
                            TextButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      ),
                    )
                  else if (_methods.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor(context)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Standard delivery: 5-7 business days. Free shipping on orders over ₹2000.',
                        style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
                      ),
                    )
                  else
                    ..._methods.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderColor(context)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      m.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${m.estimatedDays} Business Days',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.mutedForegroundColor(context),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${m.baseCost.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.mutedForegroundColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 24),
                  const Text(
                    'Delivery Locations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• We ship to all addresses within India\n'
                    '• International shipping available to select countries\n'
                    '• P.O. boxes and military addresses accepted\n'
                    '• Currently unavailable in remote areas (will be notified at checkout)',
                    style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context), height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Order Processing',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Orders placed before 2 PM IST ship the same business day\n'
                    '• Orders placed after 2 PM ship the next business day\n'
                    '• No shipping on Sundays and public holidays\n'
                    "• You'll receive tracking information via email once shipped",
                    style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context), height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickFact(IconData icon, String title, String desc) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.1)),
          ),
          child: Icon(icon, size: 20, color: AppTheme.mutedForegroundColor(context)),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.mutedForegroundColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: TextStyle(fontSize: 11, color: AppTheme.mutedForegroundColor(context)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
