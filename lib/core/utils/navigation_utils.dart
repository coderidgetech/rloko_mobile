import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

/// Global debounce lock: one navigation at a time, released after the
/// current frame completes.  This prevents two rapid taps (or simultaneous
/// callbacks from two visible widgets) from pushing the same route twice in
/// one frame — which produces duplicate GoRouter page keys and crashes the
/// Navigator's `_debugCheckDuplicatedPageKeys` assertion.
bool _navLocked = false;

/// Root paths of the five [StatefulShellRoute] branches (see app_router.dart).
/// These must be navigated to with `go` (which switches the active branch),
/// never `push`: imperatively pushing a route nested inside a stateful shell
/// re-includes the shell's own page in the root navigator, producing a
/// duplicate page key and crashing `_debugCheckDuplicatedPageKeys`.
const _shellBranchPaths = {'/', '/categories', '/search', '/account', '/cart'};

extension SafeGoRouter on BuildContext {
  /// Navigate to [location] safely:
  ///   1. No-op if [location] already equals the current route.
  ///   2. No-op if another navigation fired in the same frame (debounce).
  ///   3. Uses `go` for shell-branch roots (tab switch), `push` otherwise.
  ///
  /// GoRouter 14.x derives route keys from path + params. Two entries with
  /// identical keys in the Navigator's pages list trigger the assertion
  /// `!keyReservation.contains(key)` (HeroControllerScope / navigator.dart:4049).
  void safePush(String location, {Object? extra}) {
    if (!mounted) return;
    if (_navLocked) return;

    try {
      final current = GoRouterState.of(this).uri.toString();
      if (current == location) return;
    } catch (_) {
      // GoRouterState unavailable outside router scope — fall through.
    }

    _navLocked = true;
    // Release after the current frame so back-to-back same-frame taps are dropped.
    SchedulerBinding.instance.addPostFrameCallback((_) => _navLocked = false);

    // Shell-branch destinations switch tabs via `go`; pushing them duplicates
    // the shell page and crashes the Navigator (see [_shellBranchPaths]).
    if (_shellBranchPaths.contains(location)) {
      go(location, extra: extra);
    } else {
      push(location, extra: extra);
    }
  }
}
