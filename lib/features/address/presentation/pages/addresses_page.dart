import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../product/presentation/widgets/empty_state.dart';
import '../../domain/entities/address_entity.dart';
import '../bloc/address_list_bloc.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  bool _retriedAfterAuth = false;

  @override
  void initState() {
    super.initState();
    context.read<AddressListBloc>().add(const AddressListLoadRequested());
  }

  void _retryIfAuthenticated() {
    if (_retriedAfterAuth) return;
    final authState = context.read<AuthBloc>().state;
    final listState = context.read<AddressListBloc>().state;
    if (authState is AuthAuthenticated &&
        listState is AddressListError &&
        listState.message.contains('Sign in')) {
      _retriedAfterAuth = true;
      context.read<AddressListBloc>().add(const AddressListLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    // When opened from Account while logged in, retry if we're still showing 401
    if (context.read<AuthBloc>().state is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _retryIfAuthenticated();
      });
    }
    return Scaffold(
      backgroundColor: AppTheme.muted,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/account');
            }
          },
        ),
        title: const Text('Addresses'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.foreground,
      ),
      body: BlocBuilder<AddressListBloc, AddressListState>(
        builder: (context, state) {
          if (state is AddressListLoading) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (state is AddressListError) {
            final isUnauth = state.message.contains('Sign in');
            return EmptyState(
              title: isUnauth ? 'Sign in to view addresses' : 'Could not load addresses',
              subtitle: state.message,
              icon: Icons.location_on_outlined,
              actionLabel: isUnauth ? 'Sign in' : 'Retry',
              onAction: () {
                if (isUnauth) {
                  context.push('/login', extra: '/addresses');
                } else {
                  context.read<AddressListBloc>().add(const AddressListLoadRequested());
                }
              },
            );
          }
          if (state is AddressListLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // React: h1 text-2xl font-medium, p text-sm text-foreground/60 mt-1
                  const Text(
                    'Saved Addresses',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your delivery addresses',
                    style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 16),
                  // React: w-full bg-primary p-4 rounded-2xl, Plus 20, "Add New Address" font-medium
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await context.push('/addresses/add');
                        if (context.mounted) {
                          context.read<AddressListBloc>().add(const AddressListLoadRequested());
                        }
                      },
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add New Address'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.addresses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: EmptyState(
                        title: 'No addresses yet',
                        subtitle: 'Add an address for faster checkout',
                        icon: Icons.location_on_outlined,
                        actionLabel: 'Add address',
                        onAction: () => context.push('/addresses/add'),
                      ),
                    )
                  else
                    ...List.generate(state.addresses.length, (index) {
                      final address = state.addresses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AddressCard(
                          address: address,
                          onEdit: () {
                            context.push('/addresses/edit/${address.id}').then((_) {
                              if (context.mounted) {
                                context.read<AddressListBloc>().add(const AddressListLoadRequested());
                              }
                            });
                          },
                          onDelete: () => _confirmDelete(context, address),
                          onSetDefault: () => context
                              .read<AddressListBloc>()
                              .add(AddressListSetDefaultRequested(address.id)),
                        ),
                      );
                    }),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, AddressEntity address) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text(
          'Remove ${address.name} – ${address.addressLine}, ${address.city}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<AddressListBloc>()
                  .add(AddressListDeleteRequested(address.id));
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.destructive),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Match React: bg-white rounded-2xl p-4 border border-border/30 shadow-sm, type icon + label, Default badge, Edit / Set as Default / Delete
class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });
  final AddressEntity address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.foreground.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_typeIcon(address.type), size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                _typeLabel(address.type),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Default',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            address.addressLine,
            style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.7)),
          ),
          if (address.addressLine2 != null && address.addressLine2!.isNotEmpty)
            Text(
              address.addressLine2!,
              style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.7)),
            ),
          const SizedBox(height: 4),
          Text(
            '${address.city} - ${address.pincode}',
            style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            address.mobile,
            style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: AppTheme.foreground.withValues(alpha: 0.12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!address.isDefault) ...[
                Expanded(
                  child: FilledButton(
                    onPressed: onSetDefault,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Set as Default'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    side: BorderSide(color: Colors.red.shade200),
                    foregroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.delete_outline, size: 16),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'HOME':
        return Icons.home_outlined;
      case 'OFFICE':
      case 'WORK':
        return Icons.work_outline;
      default:
        return Icons.location_on_outlined;
    }
  }

  String _typeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'HOME':
        return 'Home';
      case 'OFFICE':
      case 'WORK':
        return 'Work';
      default:
        return 'Other';
    }
  }
}
