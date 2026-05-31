import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../promotion/domain/entities/promotion_entity.dart';
import '../../../promotion/domain/usecases/get_promotions_usecase.dart';

/// Coupons & offers – uses GET /promotions API; design matches React MobileCouponsPage.
class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  List<PromotionEntity> _promotions = [];
  bool _loading = true;
  String? _error;
  String? _copiedCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await sl<GetPromotionsUseCase>().call(activeOnly: false);
      if (!mounted) return;
      setState(() {
        _promotions = list;
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

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _copiedCode = code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Coupon code "$code" copied!')),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedCode = null);
    });
  }

  static String _discountLabel(PromotionEntity p) {
    switch (p.type) {
      case 'percentage':
        return '${p.value.toInt()}% OFF';
      case 'fixed':
        return '₹${p.value.toInt()} OFF';
      case 'free_shipping':
        return 'FREE SHIPPING';
      default:
        return p.name;
    }
  }

  static String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${_month(d.month)} ${d.day}, ${d.year}';
  }

  static String _month(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final active = _promotions.where((e) => e.isActive).toList();
    final expired = _promotions.where((e) => !e.isActive).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: TextStyle(color: AppTheme.mutedForegroundColor(context))),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: AppTheme.backgroundColor(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Coupons & Offers',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${active.length} active ${active.length == 1 ? 'coupon' : 'coupons'} available',
                              style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Coupons',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 12),
                            if (active.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No active coupons',
                                    style: TextStyle(color: AppTheme.mutedForegroundColor(context)),
                                  ),
                                ),
                              )
                            else
                              ...active.asMap().entries.map((e) => _buildCouponCard(
                                    e.value,
                                    expired: false,
                                    copied: _copiedCode == e.value.code,
                                    onCopy: () => _copyCode(e.value.code),
                                  )),
                            if (expired.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'Expired Coupons',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 12),
                              ...expired.map((p) => _buildCouponCard(p, expired: true)),
                            ],
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFEFF6FF),
                                    const Color(0xFFF5F3FF),
                                ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '💡 How to use coupons',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '• Copy the coupon code\n• Add items to cart\n• Apply code at checkout\n• Enjoy your discount!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.mutedForegroundColor(context),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
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

  Widget _buildCouponCard(
    PromotionEntity coupon, {
    required bool expired,
    bool copied = false,
    VoidCallback? onCopy,
  }) {
    final discountLabel = _discountLabel(coupon);
    final expiryStr = _formatDate(coupon.endDate);
    final minOrder = coupon.minPurchase != null ? '₹${coupon.minPurchase!.toInt()}' : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: expired ? Colors.white.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: expired ? AppTheme.borderColor(context) : AppTheme.primaryColor(context).withValues(alpha: 0.3),
            width: expired ? 1 : 2,
          ),
          boxShadow: expired ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: expired
                    ? AppTheme.foregroundColor(context).withValues(alpha: 0.05)
                    : null,
                gradient: expired
                    ? null
                    : LinearGradient(
                        colors: [
                          AppTheme.primaryColor(context),
                          AppTheme.primaryColor(context).withValues(alpha: 0.8),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 20,
                        color: expired ? AppTheme.mutedForegroundColor(context) : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        discountLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: expired ? AppTheme.mutedForegroundColor(context) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    expired ? 'Expired' : 'Expires $expiryStr',
                    style: TextStyle(
                      fontSize: 12,
                      color: expired ? Colors.red.shade700 : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: expired ? AppTheme.mutedForegroundColor(context) : null,
                    ),
                  ),
                  if (coupon.code.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${coupon.code}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForegroundColor(context),
                      ),
                    ),
                  ],
                  if (minOrder != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Min. order: $minOrder',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForegroundColor(context).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  if (!expired && onCopy != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.foregroundColor(context).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                coupon.code,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: AppTheme.primaryColor(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: copied ? Colors.green : AppTheme.primaryColor(context),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: onCopy,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Icon(
                                copied ? Icons.check : Icons.copy,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (expired)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          coupon.code,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: AppTheme.mutedForegroundColor(context).withValues(alpha: 0.6),
                            decoration: TextDecoration.lineThrough,
                            letterSpacing: 2,
                          ),
                        ),
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
}
