import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/fade_in.dart';

class HostBookingsScreen extends StatefulWidget {
  const HostBookingsScreen({super.key});

  @override
  State<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends State<HostBookingsScreen> {
  bool _upcoming = true;
  late final List<Booking> _bookings = [...MockData.bookings];

  void _set(Booking b, BookingStatus s) {
    setState(() {
      final i = _bookings.indexWhere((x) => x.id == b.id);
      _bookings[i] = b.copyWith(status: s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _bookings.where((b) => b.upcoming == _upcoming).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const FadeIn(
          child: PageHeading(
            'Bookings',
            subtitle: 'Requests from travellers. Accept or decline.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Upcoming')),
              ButtonSegment(value: false, label: Text('Past')),
            ],
            selected: {_upcoming},
            onSelectionChanged: (s) => setState(() => _upcoming = s.first),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Column(
            key: ValueKey(_upcoming),
            children: [
              for (final (n, b) in list.indexed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: FadeIn(
                    index: n,
                    child: _BookingCard(
                      booking: b,
                      onAccept: () => _set(b, BookingStatus.confirmed),
                      onDecline: () => _set(b, BookingStatus.cancelled),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onAccept,
    required this.onDecline,
  });

  final Booking booking;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (label, color) = switch (booking.status) {
      BookingStatus.pending => ('Pending', AppColors.yellow),
      BookingStatus.confirmed => ('Confirmed', AppColors.green),
      BookingStatus.completed => ('Completed', AppColors.blue),
      BookingStatus.cancelled => ('Cancelled', AppColors.red),
    };
    return OutlineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceSoft,
                child: Text(
                  booking.guest[0],
                  style: t.titleSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.guest, style: t.titleSmall),
                    Text(
                      '${booking.item} · ${booking.guests} guests',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: TonePill(label, key: ValueKey(label), color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(booking.dates, style: t.bodyMedium),
              const Spacer(),
              Text(booking.amount, style: t.titleSmall),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: booking.status == BookingStatus.pending
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onDecline,
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(64, 44),
                            ),
                            onPressed: onAccept,
                            child: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
