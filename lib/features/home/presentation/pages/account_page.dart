import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../order/presentation/bloc/order_list_bloc.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _authCheckDispatched = false;
  bool _restoreAttempted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: false),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // Re-trigger auth check when landing on account with unknown state (e.g. race at startup)
          if (state is AuthInitial && !_authCheckDispatched) {
            _authCheckDispatched = true;
            context.read<AuthBloc>().add(const AuthCheckRequested());
          }
          // When showing guest, try once to restore session from stored token (e.g. getMe failed earlier due to network)
          if (state is AuthUnauthenticated && !_restoreAttempted) {
            _restoreAttempted = true;
            context.read<AuthBloc>().add(const AuthCheckRequested());
          }
        },
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _AccountContent(
              user: state.user,
            );
          }
          if (state is AuthLoading || state is AuthInitial) {
            return const _AuthLoadingContent();
          }
          return _GuestContent();
        },
      ),
    );
  }
}

/// Shown while determining auth state (initial check or re-check).
class _AuthLoadingContent extends StatelessWidget {
  const _AuthLoadingContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor(context)),
          const SizedBox(height: 16),
          Text('Loading...', style: TextStyle(color: AppTheme.mutedForegroundColor(context))),
        ],
      ),
    );
  }
}

/// Not logged in: matches React MobileAccountPage guest state (icon, Welcome, Sign In, Create Account, Browse as Guest).
class _GuestContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      child: Column(
        children: [
          const SizedBox(height: 48),
          // React: w-24 h-24 rounded-full bg-primary/10, User size 40
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_outline, size: 40, color: AppTheme.primaryColor(context)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to Rloko',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 320,
            child: Text(
              'Sign in to access your orders, wishlist, and personalized recommendations',
              style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          // React: max-w-xs (320), py-3.5 rounded-full, mb-3
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: FilledButton(
                onPressed: () => context.push('/login', extra: '/account'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                ),
                child: const Text('Sign In'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: OutlinedButton(
                onPressed: () => context.push('/signup'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                ),
                child: const Text('Create Account'),
              ),
            ),
          ),
          const SizedBox(height: 48),
          // React: text-xs text-foreground/40 uppercase tracking-wider mb-4
          Text(
            'Browse as Guest',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.foregroundColor(context).withValues(alpha: 0.4),
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 320,
            child: Column(
              children: [
                _GuestOption(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Continue Shopping',
                  onTap: () => context.go('/'),
                ),
                const SizedBox(height: 8),
                _GuestOption(
                  icon: Icons.help_outline,
                  label: 'Help Center',
                  onTap: () => context.push('/help'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestOption extends StatelessWidget {
  const _GuestOption({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // React: p-4 bg-foreground/5 rounded-xl, gap-3, ChevronRight 18 text-foreground/40
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.foregroundColor(context).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.chevron_right, size: 18, color: AppTheme.foregroundColor(context).withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logged in: matches React MobileAccountPage (profile, stats, menu sections, logout, version).
class _AccountContent extends StatefulWidget {
  const _AccountContent({required this.user});
  final UserEntity user;

  @override
  State<_AccountContent> createState() => _AccountContentState();
}

class _AccountContentState extends State<_AccountContent> {
  String get _memberSince {
    if (widget.user.createdAt.isEmpty) return 'Member';
    final year = DateTime.tryParse(widget.user.createdAt)?.year;
    return year != null ? 'Member since $year' : 'Member';
  }

  @override
  void initState() {
    super.initState();
    context.read<WishlistBloc>().add(const WishlistLoadRequested());
    context.read<OrderListBloc>().add(const OrderListLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final userName = user.name.isEmpty ? 'User' : user.name;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // React: flex gap-4 mb-6, avatar w-20 h-20 (80px), edit w-9 h-9 rounded-full bg-foreground/5
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.mutedColor(context),
                child: Text(
                  userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.primaryColor(context)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _memberSince,
                      style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/profile/edit'),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.settings_outlined, size: 18, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stats: orders from OrderListBloc, wishlist from WishlistBloc, points (0 until backend exists)
          BlocBuilder<OrderListBloc, OrderListState>(
            buildWhen: (prev, next) => prev != next,
            builder: (context, orderListState) {
              final ordersCount = orderListState is OrderListLoaded
                  ? '${orderListState.total}'
                  : (orderListState is OrderListLoading ? '...' : '0');
              return BlocBuilder<WishlistBloc, WishlistState>(
                buildWhen: (prev, next) => prev != next,
                builder: (context, wishlistState) {
                  final wishlistCount = wishlistState is WishlistLoaded ? '${wishlistState.count}' : '0';
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(value: ordersCount, label: 'Orders', onTap: () => context.push('/orders')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(value: wishlistCount, label: 'Wishlist', onTap: () => context.push('/wishlist')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(value: '0', label: 'Points', onTap: () => context.push('/rewards')),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Orders & Shopping'),
          _MenuButton(icon: Icons.inventory_2_outlined, label: 'My Orders', onTap: () => context.push('/orders')),
          _MenuButton(icon: Icons.favorite_border, label: 'Wishlist', onTap: () => context.push('/wishlist')),
          _MenuButton(icon: Icons.star_border, label: 'Reviews', onTap: () => context.push('/reviews')),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Account Settings'),
          _MenuButton(icon: Icons.person_outline, label: 'Profile Information', onTap: () => context.push('/profile/edit')),
          _MenuButton(icon: Icons.location_on_outlined, label: 'Addresses', onTap: () => context.push('/addresses')),
          _MenuButton(icon: Icons.credit_card_outlined, label: 'Payment Methods', onTap: () => context.push('/payment-methods')),
          _MenuButton(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () => context.push('/notifications')),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Rewards & Offers'),
          _MenuButton(icon: Icons.card_giftcard_outlined, label: 'Rloko Rewards', highlight: true, onTap: () => context.push('/rewards')),
          _MenuButton(icon: Icons.local_offer_outlined, label: 'Coupons & Offers', onTap: () => context.push('/coupons')),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Support & Information'),
          _MenuButton(icon: Icons.help_outline, label: 'Help Center', onTap: () => context.push('/help')),
          _MenuButton(icon: Icons.local_shipping_outlined, label: 'Shipping Info', onTap: () => context.push('/shipping')),
          _MenuButton(icon: Icons.replay_outlined, label: 'Returns & Refunds', onTap: () => context.push('/returns')),
          _MenuButton(icon: Icons.straighten_outlined, label: 'Size Guide', onTap: () => context.push('/size-guide')),
          _MenuButton(icon: Icons.mail_outline, label: 'Contact Us', onTap: () => context.push('/contact')),
          _MenuButton(icon: Icons.info_outline, label: 'About Rloko', onTap: () => context.push('/about')),
          _MenuButton(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () => context.push('/terms')),
          _MenuButton(icon: Icons.shield_outlined, label: 'Privacy Policy', onTap: () => context.push('/privacy')),
          _MenuButton(icon: Icons.settings_outlined, label: 'Settings', onTap: () => context.push('/settings')),
          const SizedBox(height: 24),
          // React: w-full py-4 border border-red-200 text-red-500 rounded-xl font-medium, LogOut 20 + Sign Out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
                context.go('/');
              },
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // React: text-xs text-foreground/40 text-center mt-6
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    // React: text-xs font-medium text-foreground/40 uppercase tracking-wider mb-3 px-2
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTheme.foregroundColor(context).withValues(alpha: 0.4),
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.onTap});
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // React: bg-foreground/5 rounded-2xl p-4 text-center, text-2xl font-semibold text-primary mb-1, text-xs text-foreground/60
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.foregroundColor(context).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.primaryColor(context)),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: highlight
                  ? AppTheme.primaryColor(context).withValues(alpha: 0.1)
                  : AppTheme.foregroundColor(context).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: highlight ? Border.all(color: AppTheme.primaryColor(context).withValues(alpha: 0.2)) : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: highlight ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: highlight ? AppTheme.primaryColor(context) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 18, color: AppTheme.foregroundColor(context).withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
