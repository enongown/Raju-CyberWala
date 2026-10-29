import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import 'common.dart';

/// Opens the phone dialer with [number] (tel: link). Shows a snackbar when
/// no dialer is available (e.g. desktop or web preview).
Future<void> callNumber(BuildContext context, String number) async {
  final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
  var ok = false;
  try {
    ok = await launchUrl(uri);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    showSoonSnack(context, 'Could not open the dialer. Number: $number');
  }
}

/// Sticky bottom bar with an outlined "Call" and a filled "Request" button,
/// optionally preceded by a short price/summary line.
class CallRequestBar extends StatelessWidget {
  const CallRequestBar({
    super.key,
    required this.onCall,
    required this.onRequest,
    this.summary,
    this.summaryCaption,
  });

  final VoidCallback onCall;
  final VoidCallback onRequest;
  final String? summary;
  final String? summaryCaption;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              if (summary != null) ...[
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          summary!,
                          key: ValueKey(summary),
                          style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (summaryCaption != null)
                        Text(
                          summaryCaption!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 48),
                  ),
                  onPressed: onCall,
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 48),
                  ),
                  onPressed: onRequest,
                  child: const Text('Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mock confirmation shown after tapping "Request".
Future<void> showRequestSentSheet(
  BuildContext context, {
  required String to,
  required List<String> details,
}) {
  final t = Theme.of(context).textTheme;
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (context, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.greenTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 34,
                    color: AppColors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Request sent',
              textAlign: TextAlign.center,
              style: t.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'We let $to know. They usually reply by call or SMS within a '
              'few hours.',
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final d in details)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(d, style: t.bodyMedium),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Demo only — no request has actually been sent and nothing was charged.',
              textAlign: TextAlign.center,
              style: t.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    ),
  );
}
