import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/sign_in_to_continue_panel.dart';
import '../../../product/presentation/widgets/empty_state.dart';
import '../../domain/entities/address_entity.dart';
import '../bloc/address_list_bloc.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthBloc>().state is AuthAuthenticated) {
        context.read<AddressListBloc>().add(const AddressListLoadRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mutedColor(context),
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
        backgroundColor: AppTheme.backgroundColor(context),
        foregroundColor: AppTheme.foregroundColor(context),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            prev is! AuthAuthenticated && curr is AuthAuthenticated,
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.read<AddressListBloc>().add(const AddressListLoadRequested());
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is AuthInitial || authState is AuthLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor(context)),
                    const SizedBox(height: 16),
                    Text(
                      'Loading…',
                      style: TextStyle(color: AppTheme.mutedForegroundColor(context)),
                    ),
                  ],
                ),
              );
            }
            if (authState is! AuthAuthenticated) {
              return SignInToContinuePanel(
                title: 'Sign in to view your addresses',
                subtitle:
                    'Your saved delivery addresses are available after you sign in — same as on the Account tab.',
                returnPath: '/addresses',
                icon: Icons.location_on_outlined,
              );
            }
            return BlocConsumer<AddressListBloc, AddressListState>(
              listenWhen: (prev, curr) =>
                  curr is AddressListError && prev is AddressListLoaded,
              listener: (context, state) {
                if (state is AddressListError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is AddressListLoading) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                if (state is AddressListError) {
                  return EmptyState(
                    title: 'Could not load addresses',
                    subtitle: state.message,
                    icon: Icons.location_on_outlined,
                    actionLabel: 'Retry',
                    onAction: () {
                      context.read<AddressListBloc>().add(const AddressListLoadRequested());
                    },
                  );
                }
                if (state is AddressListLoaded) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saved Addresses',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your delivery addresses',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
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
            );
          },
        ),
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
        color: AppTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_typeIcon(address.type), size: 18, color: AppTheme.primaryColor(context)),
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
                    color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Default',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primaryColor(context)),
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
            style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
          ),
          if (address.addressLine2 != null && address.addressLine2!.isNotEmpty)
            Text(
              address.addressLine2!,
              style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
            ),
          const SizedBox(height: 4),
          Text(
            '${address.city} - ${address.pincode}',
            style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            address.mobile,
            style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
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
                    side: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
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
                      backgroundColor: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                      foregroundColor: AppTheme.primaryColor(context),
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
