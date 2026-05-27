import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/notifications/fcm_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Notifications: preference toggles (persisted) and notification history log.
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
  List<NotificationEntry> _log = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final log = await FCMService.readLog();
    if (!mounted) return;
    setState(() {
      _orderUpdates = prefs.getBool(_keyOrderUpdates) ?? true;
      _promotions = prefs.getBool(_keyPromotions) ?? true;
      _newArrivals = prefs.getBool(_keyNewArrivals) ?? false;
      _log = log;
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

  Future<void> _clearLog() async {
    await FCMService.clearLog();
    if (!mounted) return;
    setState(() => _log = []);
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      if (_log.isNotEmpty)
                        TextButton(
                          onPressed: _clearLog,
                          child: Text(
                            'Clear all',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.mutedForegroundColor(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_log.isEmpty)
                    _EmptyNotifications()
                  else
                    ..._log.map((n) => _NotificationCard(entry: n)),
                ],
              ),
            ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor(context).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: AppTheme.mutedForegroundColor(context),
          ),
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
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.entry});
  final NotificationEntry entry;

  static String _relativeTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[ts.month - 1]} ${ts.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor(context).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 18,
              color: AppTheme.primaryColor(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.title.isNotEmpty)
                  Text(
                    entry.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                if (entry.body.isNotEmpty) ...[
                  if (entry.title.isNotEmpty) const SizedBox(height: 2),
                  Text(
                    entry.body,
                    style: TextStyle(fontSize: 13, color: AppTheme.mutedForegroundColor(context)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _relativeTime(entry.ts),
            style: TextStyle(fontSize: 11, color: AppTheme.mutedForegroundColor(context)),
          ),
        ],
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
                      Text(
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.mutedForegroundColor(context),
                        ),
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
