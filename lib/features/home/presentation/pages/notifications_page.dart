import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Notifications: preference toggles (persisted) and notification list.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const _keyOrderUpdates = 'notif_order_updates';
  static const _keyPromotions = 'notif_promotions';
  static const _keyNewArrivals = 'notif_new_arrivals';

  bool _orderUpdates = true;
  bool _promotions = true;
  bool _newArrivals = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderUpdates = prefs.getBool(_keyOrderUpdates) ?? true;
      _promotions = prefs.getBool(_keyPromotions) ?? true;
      _newArrivals = prefs.getBool(_keyNewArrivals) ?? false;
      _loading = false;
    });
  }

  Future<void> _setOrderUpdates(bool v) async {
    setState(() => _orderUpdates = v);
    (await SharedPreferences.getInstance()).setBool(_keyOrderUpdates, v);
  }

  Future<void> _setPromotions(bool v) async {
    setState(() => _promotions = v);
    (await SharedPreferences.getInstance()).setBool(_keyPromotions, v);
  }

  Future<void> _setNewArrivals(bool v) async {
    setState(() => _newArrivals = v);
    (await SharedPreferences.getInstance()).setBool(_keyNewArrivals, v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage what you receive',
                    style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Preferences',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _SwitchTile(
                    title: 'Order updates',
                    subtitle: 'Shipping and delivery status',
                    value: _orderUpdates,
                    onChanged: _setOrderUpdates,
                  ),
                  _SwitchTile(
                    title: 'Promotions & offers',
                    subtitle: 'Coupons and sales',
                    value: _promotions,
                    onChanged: _setPromotions,
                  ),
                  _SwitchTile(
                    title: 'New arrivals',
                    subtitle: 'New products and restocks',
                    value: _newArrivals,
                    onChanged: _setNewArrivals,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.notifications_none, size: 48, color: AppTheme.mutedForegroundColor(context)),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications yet',
                          style: TextStyle(fontSize: 16, color: AppTheme.mutedForegroundColor(context)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order and promo updates will appear here.',
                          style: TextStyle(fontSize: 13, color: AppTheme.mutedForegroundColor(context)),
                          textAlign: TextAlign.center,
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

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(!value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor(context)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: AppTheme.mutedForegroundColor(context)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
