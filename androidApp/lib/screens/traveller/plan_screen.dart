import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../data/trip_calculator.dart';
import '../../theme/app_colors.dart';
import '../../theme/transitions.dart';
import '../../widgets/common.dart';
import '../../widgets/fade_in.dart';
import 'place_detail_screen.dart';

/// Holds trip choices so they survive tab switches.
class PlanController extends ChangeNotifier {
  String hubId = 'tezpur';
  final Set<String> placeIds = {'bomdila', 'dirang', 'tawang'};
  int travellers = 2;
  TransportMode mode = TransportMode.taxi;
  Comfort comfort = Comfort.budget;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key, required this.controller});

  final PlanController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _PlanBody(c: controller),
    );
  }
}

class _PlanBody extends StatelessWidget {
  const _PlanBody({required this.c});
  final PlanController c;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final hub = MockData.hubById(c.hubId);
    final selected =
        MockData.places.where((p) => c.placeIds.contains(p.id)).toList()
          ..sort((a, b) => a.routeOrder.compareTo(b.routeOrder));
    final est = TripCalculator.estimate(
      hub: hub,
      places: selected,
      travellers: c.travellers,
      mode: c.mode,
      comfort: c.comfort,
      foreigner: false,
    );
    final month = DateTime.now().month;

    var i = 0;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        FadeIn(
          index: i++,
          child: const PageHeading(
            'Plan your trip',
            subtitle:
                'Pick places to see seasons, road times and a fair budget.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: FadeIn(
            index: i++,
            child: const Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                DotLabel('Works offline', color: AppColors.green),
                DotLabel('Times are approximate', color: AppColors.yellow),
              ],
            ),
          ),
        ),
        FadeIn(
          index: i++,
          child: const SectionHeader(
            'Start from',
            subtitle: 'Nearest airport or railway hub',
          ),
        ),
        FadeIn(
          index: i++,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              runSpacing: 8,
              children: [
                for (final h in MockData.hubs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      showCheckmark: false,
                      avatar: Icon(
                        h.kind.startsWith('Airport')
                            ? Icons.flight_outlined
                            : Icons.train_outlined,
                        size: 16,
                      ),
                      label: Text(h.name),
                      selected: c.hubId == h.id,
                      onSelected: (_) => c.update(() => c.hubId = h.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
        FadeIn(
          index: i++,
          child: SectionHeader(
            'Places',
            subtitle: '${selected.length} selected · tap to add or remove',
          ),
        ),
        FadeIn(
          index: i++,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in MockData.places)
                  FilterChip(
                    label: Text(p.name),
                    selected: c.placeIds.contains(p.id),
                    onSelected: (on) => c.update(
                      () => on ? c.placeIds.add(p.id) : c.placeIds.remove(p.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: selected.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                  child: Column(
                    children: [
                      const TintIcon(Icons.landscape_outlined, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        'Choose a few places to start',
                        style: t.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader('Your route'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _RouteCard(est: est),
                    ),
                    const SectionHeader(
                      'Budget estimate',
                      subtitle: 'Fair local prices, per trip',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _BudgetCard(c: c, est: est),
                    ),
                    SectionHeader(
                      'Seasons',
                      subtitle:
                          'Best and risky times · now: ${monthShort[month - 1]}',
                    ),
                    for (final (n, p) in selected.indexed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: FadeIn(
                          key: ValueKey(p.id),
                          index: n,
                          child: PlaceSeasonCard(
                            place: p,
                            leg: TripCalculator.hubToPlace(hub, p),
                            hubName: hub.name,
                            month: month,
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

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.est});
  final TripEstimate est;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return OutlineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stat(value: '${est.days}', label: 'days'),
              _Stat(value: '~${est.totalKm}', label: 'km by road'),
              _Stat(value: formatHours(est.totalHours), label: 'driving'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          for (final (i, l) in est.legs.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 0 || i == est.legs.length - 1
                          ? AppColors.blue
                          : AppColors.borderStrong,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${l.from} → ${l.to}', style: t.bodyMedium),
                  ),
                  Text(
                    '${l.leg.estimated ? '≈' : ''}${l.leg.km} km · ${formatHours(l.leg.hours)}',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          InfoNote(
            est.hasEstimatedLegs
                ? 'Approximate. ≈ legs are estimated from map distance with a hill-road factor.'
                : 'Approximate hill-road times. Allow buffer for weather and landslides.',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            key: ValueKey(value),
            builder: (context, v, child) => Opacity(opacity: v, child: child),
            child: Text(
              value,
              style: t.headlineSmall?.copyWith(color: AppColors.text),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: t.bodySmall),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.c, required this.est});
  final PlanController c;
  final TripEstimate est;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    String range(int lo, int hi) => '${formatRupees(lo)} – ${formatRupees(hi)}';
    return OutlineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Travellers', style: t.bodyMedium)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: c.travellers > 1
                    ? () => c.update(() => c.travellers--)
                    : null,
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '${c.travellers}',
                  textAlign: TextAlign.center,
                  style: t.titleMedium,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline),
                onPressed: c.travellers < 12
                    ? () => c.update(() => c.travellers++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<TransportMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: TransportMode.shared,
                      label: Text('Shared'),
                    ),
                    ButtonSegment(
                      value: TransportMode.taxi,
                      label: Text('Taxi'),
                    ),
                  ],
                  selected: {c.mode},
                  onSelectionChanged: (s) => c.update(() => c.mode = s.first),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<Comfort>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: Comfort.budget, label: Text('Budget')),
                    ButtonSegment(
                      value: Comfort.comfort,
                      label: Text('Comfort'),
                    ),
                  ],
                  selected: {c.comfort},
                  onSelectionChanged: (s) =>
                      c.update(() => c.comfort = s.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BudgetRow(
            icon: Icons.bed_outlined,
            label: 'Homestays',
            value: range(est.stayLow, est.stayHigh),
          ),
          _BudgetRow(
            icon: Icons.restaurant_outlined,
            label: 'Food',
            value: range(est.foodLow, est.foodHigh),
          ),
          _BudgetRow(
            icon: Icons.directions_car_outlined,
            label: c.mode == TransportMode.taxi ? 'Taxi' : 'Shared Sumo / bus',
            value: range(est.transportLow, est.transportHigh),
          ),
          _BudgetRow(
            icon: Icons.badge_outlined,
            label: 'ILP (Indian visitors)',
            value: range(est.permitLow, est.permitHigh),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Total', style: t.titleMedium)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  range(est.totalLow, est.totalHigh),
                  key: ValueKey(est.totalLow),
                  style: t.titleMedium?.copyWith(color: AppColors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const InfoNote(
            'Estimate only. Prices rise in peak season (Oct–Nov, festivals). '
            'Foreign visitors: PAP costs vary — see Permits.',
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: t.bodyMedium)),
          Text(
            value,
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Season summary for one place, also reused on the detail page.
class PlaceSeasonCard extends StatelessWidget {
  const PlaceSeasonCard({
    super.key,
    required this.place,
    required this.leg,
    required this.hubName,
    required this.month,
  });

  final Place place;
  final TravelLeg leg;
  final String hubName;
  final int month;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final status = place.statusFor(month);
    final (statusText, statusColor) = switch (status) {
      SeasonStatus.best => ('Great time to go', AppColors.green),
      SeasonStatus.okay => ('Okay — check weather', AppColors.yellow),
      SeasonStatus.risky => ('Risky now', AppColors.red),
    };
    return OutlineCard(
      onTap: () =>
          Navigator.of(context)
              .push(fadeRoute(PlaceDetailScreen(place: place))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: t.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${place.district} · ${place.altitudeM} m',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              TonePill(statusText, color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          DotLabel(
            'Best: ${monthRanges(place.bestMonths)}',
            color: AppColors.green,
          ),
          const SizedBox(height: 6),
          DotLabel(
            'Risky: ${monthRanges(place.riskyMonths)} — ${place.riskNote}',
            color: AppColors.red,
          ),
          const SizedBox(height: 6),
          DotLabel(
            'From $hubName: ${leg.estimated ? '≈' : '~'}${leg.km} km · ${formatHours(leg.hours)} by road',
            color: AppColors.blue,
          ),
        ],
      ),
    );
  }
}
