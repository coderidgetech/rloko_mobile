import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../delivery/presentation/guest_delivery_cubit.dart';
import '../region/app_region.dart';
import '../region/presentation/region_bloc.dart';
import '../theme/app_theme.dart';
import 'deliver_to_location_sheet.dart';
import '../../features/address/domain/entities/address_entity.dart';
import '../../features/address/presentation/bloc/address_list_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// Tappable row: same delivery line as home (guest pin/ZIP or default saved address).
class DeliveryLocationStrip extends StatelessWidget {
  const DeliveryLocationStrip({super.key});

  static String _lineSignedIn(AddressListState list) {
    if (list is AddressListLoading) {
      return 'Loading delivery address…';
    }
    if (list is AddressListError) {
      return 'Tap to set delivery location';
    }
    if (list is AddressListLoaded) {
      if (list.addresses.isEmpty) {
        return 'Add a delivery address';
      }
      AddressEntity? def;
      for (final a in list.addresses) {
        if (a.isDefault) {
          def = a;
          break;
        }
      }
      def ??= list.addresses.first;
      final head = 'Deliver to ${def.name} — ${def.addressLine}';
      if (head.length <= 64) return head;
      return '${head.substring(0, 61)}…';
    }
    if (list is AddressListInitial) {
      return 'Loading delivery address…';
    }
    return 'Set delivery location';
  }

  /// Same text as the guest row on home/cart; used when saved addresses are not available.
  static String guestDeliveryLine(AppRegion market, GuestDeliveryState g) {
    if (market == AppRegion.india) {
      final p = g.indiaPincode;
      if (p != null && p.length == 6) {
        final c = g.indiaCityHint;
        if (c != null && c.isNotEmpty) {
          return 'Deliver to $c $p';
        }
        return 'Deliver to $p';
      }
      return 'Set your location';
    } else {
      final z = g.usZip;
      if (z != null && z.isNotEmpty) {
        return 'Deliver to $z';
      }
      return 'Set your location';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, auth) {
        if (auth is AuthAuthenticated) {
          return BlocBuilder<AddressListBloc, AddressListState>(
            builder: (context, list) {
              return _row(
                context: context,
                line: _lineSignedIn(list),
                onTap: () => context.push('/delivery-location'),
              );
            },
          );
        }
        return BlocBuilder<RegionBloc, RegionState>(
          builder: (context, r) {
            return BlocBuilder<GuestDeliveryCubit, GuestDeliveryState>(
              builder: (context, g) {
                return _row(
                  context: context,
                  line: guestDeliveryLine(r.region, g),
                  onTap: () => showDeliverToLocationSheet(context),
                );
              },
            );
          },
        );
      },
    );
  }
}

Widget _row({
  required BuildContext context,
  required String line,
  required VoidCallback onTap,
}) {
  return Material(
    color: AppTheme.backgroundColor(context),
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.foregroundColor(context).withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 20,
              color: AppTheme.foregroundColor(context).withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                line,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foregroundColor(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: AppTheme.foregroundColor(context).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    ),
  );
}
