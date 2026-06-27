import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-screen / section error state shown when a request fails.
///
/// Detects connectivity-style failures (no internet, server unreachable,
/// timeout) from the message and presents a friendly "offline" look — a
/// wifi-off icon, a short headline, the detail line, and a Retry button —
/// the way most e-commerce apps do, instead of dumping a raw error string.
///
/// For genuinely empty (non-error) states use [EmptyState] instead.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.compact = false,
  });

  /// The (already user-friendly) error message from the network layer.
  final String message;

  /// Called when the user taps Retry. If null, no button is shown.
  final VoidCallback? onRetry;

  final String retryLabel;

  /// Compact inline layout for sections inside a scrolling page (no full
  /// vertical centering, smaller icon).
  final bool compact;

  /// Heuristic: does this message describe a connectivity problem rather than
  /// a server/validation error? Mirrors the strings produced in dio_client.dart.
  static bool _isConnectivity(String m) {
    final s = m.toLowerCase();
    return s.contains("couldn't reach") ||
        s.contains('could not reach') ||
        s.contains('internet connection') ||
        s.contains('took too long') ||
        s.contains('no internet') ||
        s.contains('network') ||
        s.contains('connection');
  }

  @override
  Widget build(BuildContext context) {
    final offline = _isConnectivity(message);
    final icon = offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded;
    final title = offline ? 'No connection' : 'Something went wrong';

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: compact ? 40 : 64,
          color: AppTheme.mutedForegroundColor(context),
        ),
        SizedBox(height: compact ? 10 : 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.foregroundColor(context),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            color: AppTheme.mutedForegroundColor(context),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          SizedBox(height: compact ? 16 : 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(retryLabel),
          ),
        ],
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(child: content),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: content,
      ),
    );
  }
}
