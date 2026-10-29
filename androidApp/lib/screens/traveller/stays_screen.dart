import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../data/trip_calculator.dart';
import '../../theme/app_colors.dart';
import '../../theme/transitions.dart';
import '../../widgets/common.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/gender_rating.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/search_field.dart';
import 'guide_detail_screen.dart';
import 'stay_detail_screen.dart';

enum _Mode { stays, guides }

/// Stays / Guides tab: search, a Stays-vs-Guides switch, an optional
/// "Display total price" toggle and large listing cards.
class StaysScreen extends StatefulWidget {
  const StaysScreen({super.key});

  @override
  State<StaysScreen> createState() => _StaysScreenState();
}

class _StaysScreenState extends State<StaysScreen> {
  final _search = TextEditingController();
  String _query = '';
  _Mode _mode = _Mode.stays;
  bool _showTotal = false;
  int _nights = 2;
  bool _womenRecommended = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(String text) =>
      _query.trim().isEmpty ||
      text.toLowerCase().contains(_query.trim().toLowerCase());

  @override
  Widget build(BuildContext context) {
    final stays = MockData.stays
        .where((s) => _matches('${s.name} ${s.hostName} ${s.location}'))
        .where((s) => !_womenRecommended || s.ratings.isWomenRecommended)
        .toList();
    final guides = MockData.guides
        .where(
          (g) => _matches(
            '${g.name} ${g.tribe} ${g.location} ${g.specialty} '
            '${g.languages.join(' ')}',
          ),
        )
        .where((g) => !_womenRecommended || g.ratings.isWomenRecommended)
        .toList();
    final count = _mode == _Mode.stays ? stays.length : guides.length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: FadeIn(
            child: AppSearchField(
              controller: _search,
              hint: 'Search homestays, hosts, fixers…',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: FadeIn(
            index: 1,
            child: SegmentedButton<_Mode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _Mode.stays,
                  icon: Icon(Icons.cottage_outlined, size: 18),
                  label: Text('Stays'),
                ),
                ButtonSegment(
                  value: _Mode.guides,
                  icon: Icon(Icons.hiking, size: 18),
                  label: Text('Guides'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: FadeIn(
            index: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: genderRatingInfo,
                child: FilterChip(
                  avatar: Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: _womenRecommended
                        ? AppColors.womenDeep
                        : AppColors.textSecondary,
                  ),
                  showCheckmark: false,
                  label: const Text('Women recommended'),
                  selected: _womenRecommended,
                  selectedColor: AppColors.womenTint,
                  side: BorderSide(
                    color: _womenRecommended
                        ? AppColors.women
                        : AppColors.borderStrong,
                  ),
                  labelStyle: TextStyle(
                    color: _womenRecommended
                        ? AppColors.womenDeep
                        : AppColors.text,
                  ),
                  onSelected: (v) => setState(() => _womenRecommended = v),
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _mode == _Mode.stays
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: FadeIn(index: 3, child: _totalPriceCard(context)),
                )
              : const SizedBox(width: double.infinity),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            '${_mode == _Mode.stays ? '$count homestays · run by local families' : '$count local guides & fixers'}'
            '${_womenRecommended ? ' · women recommended' : ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          child: Column(
            key: ValueKey('$_mode$_query$_womenRecommended'),
            children: [
              if (_mode == _Mode.stays)
                for (final (n, s) in stays.indexed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: FadeIn(index: n, child: _stayCard(s)),
                  )
              else
                for (final (n, g) in guides.indexed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: FadeIn(index: n, child: _guideCard(g)),
                  ),
              if (count == 0)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _query.trim().isEmpty
                        ? 'No women-recommended listings yet'
                        : 'Nothing found offline for "$_query"',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: InfoNote(
            'Sample listings. Verified hosts have confirmed phone and ID with '
            'a local volunteer. Ratings come from past travellers; the pink '
            'and blue bar shows the share of women and men who rated.',
          ),
        ),
      ],
    );
  }

  Widget _totalPriceCard(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return OutlineCard(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      onTap: () => setState(() => _showTotal = !_showTotal),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Display total price', style: t.titleSmall),
                    Text('Includes all fees, before taxes', style: t.bodySmall),
                  ],
                ),
              ),
              Switch(
                value: _showTotal,
                onChanged: (v) => setState(() => _showTotal = v),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _showTotal
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total for $_nights night${_nights == 1 ? '' : 's'}',
                            style: t.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        IconButton.outlined(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Fewer nights',
                          onPressed: _nights > 1
                              ? () => setState(() => _nights--)
                              : null,
                          icon: const Icon(Icons.remove, size: 18),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '$_nights',
                            textAlign: TextAlign.center,
                            style: t.titleMedium,
                          ),
                        ),
                        IconButton.outlined(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'More nights',
                          onPressed: _nights < 14
                              ? () => setState(() => _nights++)
                              : null,
                          icon: const Icon(Icons.add, size: 18),
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

  Widget _stayCard(Stay s) {
    return ListingCard(
      id: s.id,
      palette: s.palette,
      icon: Icons.cottage_outlined,
      badge: s.verified ? const _Badge('Verified host') : null,
      title: s.name,
      subtitle: s.location,
      details:
          '${s.bedrooms} bedroom${s.bedrooms == 1 ? '' : 's'} · '
          '${s.beds} bed${s.beds == 1 ? '' : 's'} · '
          'up to ${s.maxGuests} guests',
      price: _showTotal
          ? formatRupees(s.totalFor(_nights))
          : formatRupees(s.pricePerNight),
      priceSuffix: _showTotal
          ? 'total · $_nights night${_nights == 1 ? '' : 's'}'
          : '/ night',
      ratings: s.ratings,
      onTap: () =>
          Navigator.of(context).push(fadeRoute(StayDetailScreen(stay: s))),
    );
  }

  Widget _guideCard(Guide g) {
    return ListingCard(
      id: g.id,
      palette: g.palette,
      photoOverlay: GuideInitials(guide: g),
      badge: g.verified ? const _Badge('Verified guide') : null,
      title: '${g.name} (${g.tribe})',
      subtitle: g.specialty,
      details:
          '${g.years} years guiding · ${g.languages.take(3).join(', ')} · '
          '${g.location}',
      price: formatRupees(g.pricePerDay),
      priceSuffix: '/ day',
      ratings: g.ratings,
      onTap: () =>
          Navigator.of(context).push(fadeRoute(GuideDetailScreen(guide: g))),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 14, color: AppColors.blue),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppColors.text, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
