import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/constants/delivery_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../return_order/domain/entities/return_entity.dart';
import '../../../return_order/domain/usecases/list_returns_usecase.dart';

/// Returns & Refunds – uses GET /returns API; design matches React MobileReturnsPage.
class ReturnsPage extends StatefulWidget {
  const ReturnsPage({super.key});

  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage> {
  List<ReturnEntity> _returns = [];
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
      final result = await sl<ListReturnsUseCase>().call();
      if (!mounted) return;
      setState(() {
        _returns = result.returns;
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

  static const _steps = [
    (1, 'Initiate Return', 'Contact us within 30 days of delivery', Icons.info_outline),
    (2, 'Ship It Back', 'Pack items securely with original tags', Icons.replay),
    (3, 'We Process', DeliveryConstants.returnInspectionDays, Icons.schedule),
    (4, 'Get Refund', 'Refund issued to original payment method', Icons.check_circle_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppHeader(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.replay, size: 32, color: AppTheme.primary),
                  const SizedBox(height: 8),
                  const Text(
                    'Easy Returns',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '30-day hassle-free return policy',
                    style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ..._steps.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${s.$1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.$2,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.$3,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(s.$4, size: 20, color: AppTheme.primary),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            _section(
              'Return Policy',
              [
                'Items must be unused and in original condition',
                'Original tags and packaging must be intact',
                'Return initiated within 30 days of delivery',
                'Proof of purchase required',
              ],
              checkIcon: true,
            ),
            const SizedBox(height: 16),
            _section(
              'Non-Returnable Items',
              [
                'Intimate apparel and swimwear',
                'Earrings and pierced jewelry',
                'Final sale items',
                'Gift cards',
              ],
              red: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Refund Timeline',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _timelineRow(Icons.schedule, 'Processing Time',
                      DeliveryConstants.returnProcessingNote),
                  const SizedBox(height: 8),
                  _timelineRow(Icons.check_circle_outline, 'Refund Arrival',
                      '5-10 business days to appear in your account'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.muted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exchanges',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We currently don't offer direct exchanges. If you need a different size or color, please return your original item and place a new order.",
                    style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '💡 Tip: Contact us first - we may be able to hold the item you want while processing your return!',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'My Returns',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(_error!, style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else if (_returns.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No return requests yet',
                    style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
                  ),
                ),
              )
            else
              ..._returns.map((r) => _returnCard(r)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.foreground.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Need Help?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact our customer service team for assistance with your return',
                    style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.push('/contact'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Contact Support'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<String> items, {bool checkIcon = false, bool red = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: red ? Colors.red.shade50 : AppTheme.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: red ? Border.all(color: Colors.red.shade100) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: red ? Colors.red.shade700 : null,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      checkIcon ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: checkIcon ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _timelineRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _returnCard(ReturnEntity r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${r.orderNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(r.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    r.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(r.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              r.reason,
              style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
            ),
            const SizedBox(height: 4),
            Text(
              'Refund: ₹${r.refundAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'approved':
      case 'processing':
        return AppTheme.primary;
      case 'rejected':
        return Colors.red;
      default:
        return AppTheme.mutedForeground;
    }
  }
}
