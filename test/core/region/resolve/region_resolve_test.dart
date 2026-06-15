import 'package:flutter_test/flutter_test.dart';
import 'package:rloco_mobile/core/region/app_region.dart';
import 'package:rloco_mobile/core/region/resolve/data/dto/region_resolution_dto.dart';
import 'package:rloco_mobile/core/region/resolve/domain/entities/region_resolution.dart';
import 'package:rloco_mobile/core/region/resolve/domain/repositories/region_resolve_repository.dart';
import 'package:rloco_mobile/core/region/resolve/domain/usecases/resolve_region_usecase.dart';
import 'package:rloco_mobile/core/region/resolve/presentation/location_gate_cubit.dart';

/// Fake repo behind a real ResolveRegionUseCase, so the cubit exercises the
/// same path as production minus Dio.
class _FakeRepo implements RegionResolveRepository {
  _FakeRepo({this.result, this.throwIt = false});
  RegionResolution? result;
  bool throwIt;
  int calls = 0;

  @override
  Future<RegionResolution> resolve({String? pincode, String? country, String? city}) async {
    calls++;
    if (throwIt) throw Exception('network');
    return result ?? RegionResolution.unresolved;
  }
}

void main() {
  group('RegionResolutionDto', () {
    test('maps IN market with all fields', () {
      final e = RegionResolutionDto.fromJson({
        'market': 'IN',
        'currency': 'INR',
        'city': 'Bengaluru',
        'enabled': false,
        'comingSoonMessage': 'Launching soon',
      }).toEntity();
      expect(e.region, AppRegion.india);
      expect(e.currencyCode, 'INR');
      expect(e.city, 'Bengaluru');
      expect(e.enabled, false);
      expect(e.comingSoonMessage, 'Launching soon');
      expect(e.isResolved, true);
    });

    test('maps US market and lowercases-safe', () {
      final e = RegionResolutionDto.fromJson({
        'market': 'us',
        'currency': 'usd',
        'enabled': true,
      }).toEntity();
      expect(e.region, AppRegion.unitedStates);
      expect(e.currencyCode, 'USD');
    });

    test('unknown market → unresolved', () {
      final e = RegionResolutionDto.fromJson({'market': 'GB'}).toEntity();
      expect(e.isResolved, false);
      expect(e.region, isNull);
    });

    test('missing fields do not throw; currency falls back to region default', () {
      final e = RegionResolutionDto.fromJson({'market': 'IN'}).toEntity();
      expect(e.region, AppRegion.india);
      expect(e.currencyCode, 'INR'); // fallback from AppRegion
      expect(e.city, '');
      expect(e.enabled, false);
    });
  });

  group('LocationGateCubit.enrich', () {
    test('resolved → emits resolved with region/enabled/city', () async {
      final repo = _FakeRepo(
        result: const RegionResolution(
          region: AppRegion.unitedStates,
          currencyCode: 'USD',
          city: 'NYC',
          enabled: true,
          comingSoonMessage: '',
        ),
      );
      final cubit = LocationGateCubit(ResolveRegionUseCase(repo));
      await cubit.enrich(pincode: '94107', country: 'US');
      expect(repo.calls, 1);
      expect(cubit.state.status, LocationGateStatus.resolved);
      expect(cubit.state.resolvedRegion, AppRegion.unitedStates);
      expect(cubit.state.enabled, true);
      expect(cubit.state.city, 'NYC');
      await cubit.close();
    });

    test('unresolved input → distinct unresolved status (not transport error)', () async {
      final repo = _FakeRepo(result: RegionResolution.unresolved);
      final cubit = LocationGateCubit(ResolveRegionUseCase(repo));
      await cubit.enrich(pincode: 'abc');
      expect(cubit.state.status, LocationGateStatus.unresolved);
      expect(cubit.state.error, isNotNull);
      await cubit.close();
    });

    test('transport throw → best-effort error status', () async {
      final repo = _FakeRepo(throwIt: true);
      final cubit = LocationGateCubit(ResolveRegionUseCase(repo));
      await cubit.enrich(pincode: '560001');
      expect(cubit.state.status, LocationGateStatus.error);
      expect(cubit.state.error, contains('continue anyway'));
      await cubit.close();
    });

    test('does not emit after close (no bad-state)', () async {
      final repo = _FakeRepo(
        result: const RegionResolution(
          region: AppRegion.india,
          currencyCode: 'INR',
          city: '',
          enabled: true,
          comingSoonMessage: '',
        ),
      );
      final cubit = LocationGateCubit(ResolveRegionUseCase(repo));
      final future = cubit.enrich(pincode: '560001');
      await cubit.close();
      await future; // must complete without throwing
      expect(cubit.isClosed, true);
    });
  });
}
