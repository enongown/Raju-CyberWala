import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../data/trip_calculator.dart';
import '../../theme/app_colors.dart';
import '../../widgets/call_request_bar.dart';
import '../../widgets/common.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/gender_rating.dart';
import '../../widgets/photo_placeholder.dart';
import '../../widgets/visuals.dart';

/// "Selected Stay": photo, amenities, a trip planner (dates, guests, total)
/// and a sticky Call / Request bar.
class StayDetailScreen extends StatefulWidget {
  const StayDetailScreen({super.key, required this.stay});

  final Stay stay;

  @override
  State<StayDetailScreen> createState() => _StayDetailScreenState();
}

class _StayDetailScreenState extends State<StayDetailScreen> {
  late DateTimeRange _dates = _defaultDates();
  late int _guests = widget.stay.maxGuests >= 2 ? 2 : 1;

  DateTimeRange _defaultDates() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day + 14);
    return DateTimeRange(
      start: start,
      end: start.add(Duration(days: widget.stay.tripDays - 1)),
    );
  }

  int get _days => _dates.end.difference(_dates.start).inDays + 1;
  int get _nights => _days - 1 < 1 ? 1 : _days - 1;

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      initialDateRange: _dates,
      helpText: 'Select trip dates',
    );
    if (picked != null) setState(() => _dates = picked);
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _fmt(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final s = widget.stay;
    final t = Theme.of(context).textTheme;
    final total = s.totalFor(_nights);
    final place = MockData.placeById(s.placeId);
    var i = 0;
    return Scaffold(
      appBar: detailAppBar(context, s.hostName),
      bottomNavigationBar: CallRequestBar(
        summary: formatRupees(total),
        summaryCaption: '$_nights night${_nights == 1 ? '' : 's'} · total',
        onCall: () => callNumber(context, s.phone),
        onRequest: () => showRequestSentSheet(
          context,
          to: s.hostName,
          details: [
            '$_days-Day ${s.tripName} Trip',
            '${_fmt(_dates.start)} – ${_fmt(_dates.end)}',
            '$_guests guest${_guests == 1 ? '' : 's'} · ${formatRupees(total)} total',
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'photo-${s.id}',
                  child: PhotoPlaceholder(
                    palette: s.palette,
                    icon: Icons.cottage_outlined,
                    iconSize: 32,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: FavouriteButton(id: s.id),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FadeIn(
            index: i++,
            child: Text(s.name, style: t.headlineSmall),
          ),
          const SizedBox(height: 6),
          FadeIn(
            index: i++,
            child: Row(
              children: [
                const Icon(Icons.place_outlined, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    s.location,
                    style: t.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FadeIn(
            index: i++,
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                RatingLabel(s.rating, count: s.reviews),
                VerifiedPill(verified: s.verified),
                Text(
                  '${s.bedrooms} bedroom${s.bedrooms == 1 ? '' : 's'} · ${s.beds} beds · up to ${s.maxGuests} guests',
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FadeIn(
            index: i++,
            child: OutlineCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Who rated this stay', style: t.titleSmall),
                  const SizedBox(height: 10),
                  GenderRatingSummary(ratings: s.ratings),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeIn(
            index: i++,
            child: Text('What this place offers', style: t.titleMedium),
          ),
          const SizedBox(height: 12),
          FadeIn(
            index: i++,
            child: SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: s.amenities.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, n) =>
                    _AmenityTile(amenity: s.amenities[n]),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FadeIn(
            index: i++,
            child: Text(
              s.about,
              style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 22),
          FadeIn(
            index: i++,
            child: OutlineCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          layoutBuilder: (current, previous) => Stack(
                            alignment: AlignmentDirectional.centerStart,
                            children: [...previous, ?current],
                          ),
                          child: Text(
                            '$_days-Day ${s.tripName} Trip',
                            key: ValueKey(_days),
                            style: t.titleLarge,
                          ),
                        ),
                      ),
                      TonePill(place.district, color: AppColors.green),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stay with ${s.hostName} and explore ${place.name}.',
                    style: t.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  _TripRow(
                    icon: Icons.calendar_month_outlined,
                    label: '${_fmt(_dates.start)} – ${_fmt(_dates.end)}',
                    action: TextButton(
                      onPressed: _pickDates,
                      child: const Text('Change'),
                    ),
                  ),
                  const Divider(),
                  _TripRow(
                    icon: Icons.group_outlined,
                    label: '$_guests guest${_guests == 1 ? '' : 's'}',
                    action: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Fewer guests',
                          onPressed: _guests > 1
                              ? () => setState(() => _guests--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        IconButton(
                          tooltip: 'More guests',
                          onPressed: _guests < s.maxGuests
                              ? () => setState(() => _guests++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  _PriceLine(
                    '${formatRupees(s.pricePerNight)} × $_nights night${_nights == 1 ? '' : 's'}',
                    formatRupees(s.pricePerNight * _nights),
                  ),
                  _PriceLine(
                    'Cleaning & service fee',
                    formatRupees(s.serviceFee),
                  ),
                  const SizedBox(height: 6),
                  _PriceLine(
                    'Total (before taxes)',
                    formatRupees(total),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const InfoNote(
            'Sample listing and prices. Hosts confirm by call or SMS; pay the '
            'family directly on arrival.',
          ),
        ],
      ),
    );
  }
}

class _AmenityTile extends StatelessWidget {
  const _AmenityTile({required this.amenity});
  final Amenity amenity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(amenityIcon(amenity), size: 24, color: AppColors.text),
          const SizedBox(height: 6),
          Text(
            amenity.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({
    required this.icon,
    required this.label,
    required this.action,
  });
  final IconData icon;
  final String label;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          action,
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final style = bold
        ? t.titleMedium?.copyWith(fontWeight: FontWeight.w600)
        : t.bodyMedium?.copyWith(color: AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(value, key: ValueKey(value), style: style),
          ),
        ],
      ),
    );
  }
}
