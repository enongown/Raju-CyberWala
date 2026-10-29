import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../data/poi_repository.dart';
import '../../data/town_guides.dart';
import '../../data/trip_calculator.dart';
import '../../data/weather_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/transitions.dart';
import '../../widgets/call_request_bar.dart';
import '../../widgets/common.dart';
import '../../widgets/explore_map.dart';
import '../../widgets/explore_map_controller.dart';
import '../../widgets/fade_in.dart';
import '../../widgets/gender_rating.dart';
import '../../widgets/search_field.dart';
import '../../widgets/visuals.dart';
import 'guide_detail_screen.dart';
import 'place_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    this.initialEmergency = false,
    this.repository = const MockPoiRepository(),
    this.weatherRepository,
  });

  /// Only used by the web screenshot preview.
  final bool initialEmergency;

  /// Source of map towns, craft shops and POIs. Swap in the real database
  /// API implementation here once it exists (see [PoiRepository]).
  final PoiRepository repository;

  /// Live temperatures; defaults to Open-Meteo (see [WeatherRepository]).
  final WeatherRepository? weatherRepository;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

/// One row in the search dropdown.
class _Suggestion {
  const _Suggestion.town(this.town, this.rank) : shop = null, poi = null;
  const _Suggestion.shop(this.shop, this.rank) : town = null, poi = null;
  const _Suggestion.poi(this.poi, this.rank) : town = null, shop = null;

  final MapTown? town;
  final CraftShop? shop;
  final MapPoi? poi;

  /// Lower is better: prefix matches before substring matches, towns
  /// before shops before other points.
  final int rank;

  String get key => town != null
      ? 'suggest-town-${town!.id}'
      : shop != null
      ? 'suggest-shop-${shop!.id}'
      : 'suggest-poi-${poi!.name}';
}

/// Case-insensitive prefix / substring search over towns (and their
/// aliases and districts), craft shops and everyday points of interest.
List<_Suggestion> _searchSuggestions(
  String query,
  List<MapTown> towns,
  List<CraftShop> shops,
  List<MapPoi> pois,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  int? score(Iterable<String> names, Iterable<String> extra) {
    for (final n in names) {
      final l = n.toLowerCase();
      if (l.startsWith(q) ||
          l.split(RegExp(r'[\s(]+')).any((w) => w.startsWith(q))) {
        return 0;
      }
    }
    for (final n in [...names, ...extra]) {
      if (n.toLowerCase().contains(q)) return 1;
    }
    return null;
  }

  final out = <_Suggestion>[];
  for (final t in towns) {
    final g = TownGuides.byId(t.id);
    final r = score([t.name, ...?g?.aliases], [?g?.district]);
    if (r != null) out.add(_Suggestion.town(t, r));
  }
  for (final s in shops) {
    final r = score(
      [s.craft.name],
      [s.craft.category.label, s.townName, s.craft.description],
    );
    if (r != null) out.add(_Suggestion.shop(s, 10 + r));
  }
  for (final p in pois) {
    final r = score([p.name], [p.note, p.kind.label]);
    if (r != null) out.add(_Suggestion.poi(p, 20 + r));
  }
  out.sort((a, b) => a.rank.compareTo(b.rank));
  final townHits = out.where((s) => s.town != null).take(5);
  final shopHits = out.where((s) => s.shop != null).take(4);
  final poiHits = out.where((s) => s.poi != null).take(2);
  return [...townHits, ...shopHits, ...poiHits];
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _searchBoxKey = GlobalKey();
  final _portal = OverlayPortalController();
  final _searchGroup = Object();
  String _query = '';
  bool _suggestOpen = false;
  double _searchWidth = 360;
  final _mapKey = GlobalKey();
  late final _map = ExploreMapController(
    repository: widget.repository,
    emergency: widget.initialEmergency,
    weatherRepository: widget.weatherRepository,
  );

  /// Focus request the user closed the town info card for.
  int? _infoClosedSeq;

  /// Place card ("Places & Guides") expanded to show its best season.
  String? _expandedPlace;
  final _miniScroll = ScrollController();

  /// Max rows in the crafts list (the rest are counted in the subtitle).
  static const maxCraftRows = 20;

  bool get _emergency => _map.emergency;

  @override
  void initState() {
    super.initState();
    _map.addListener(_onMap);
    _map.load();
  }

  @override
  void dispose() {
    _map.removeListener(_onMap);
    _map.dispose();
    _search.dispose();
    _searchFocus.dispose();
    _miniScroll.dispose();
    super.dispose();
  }

  void _onMap() {
    if (mounted) setState(() {});
  }

  /// Scrolls the page up just enough to show the whole map.
  void _revealMap() {
    final ctx = _mapKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }

  void _focusItem(_MiniItem item) {
    setState(() {
      // Place cards expand to show the best season (tap again to fold);
      // guide cards keep their plain focus behaviour.
      _expandedPlace = item.guideId == null && _expandedPlace != item.townId
          ? item.townId
          : null;
    });
    if (_expandedPlace != null) _revealMiniCard(_miniItems.indexOf(item));
    _map.focusTown(item.townId, guideId: item.guideId);
    _revealMap();
  }

  /// Scrolls the Places & Guides row so the widened card [n] fits.
  void _revealMiniCard(int n) {
    // After the card has finished widening (AnimatedContainer, 300 ms).
    Future.delayed(const Duration(milliseconds: 320), () {
      if (!mounted || n < 0 || !_miniScroll.hasClients) return;
      final pos = _miniScroll.position;
      final start = n * (112.0 + 10);
      final end = start + _MiniCard.expandedWidth + 40;
      final target = start < pos.pixels
          ? start
          : end > pos.pixels + pos.viewportDimension
          ? end - pos.viewportDimension
          : null;
      if (target == null) return;
      _miniScroll.animateTo(
        target.clamp(0, pos.maxScrollExtent),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _focusShop(CraftShop shop) {
    _map.focusShop(shop);
    _revealMap();
  }

  // --- Search ---------------------------------------------------------------

  List<_Suggestion> get _suggestions =>
      _searchSuggestions(_query, _map.towns, _map.shops, _map.nearbyPois);

  void _onQuery(String v) {
    setState(() {
      _query = v;
      _suggestOpen = v.trim().isNotEmpty;
    });
    if (_suggestOpen) _portal.show();
  }

  void _closeSuggestions() {
    if (!_suggestOpen) return;
    setState(() => _suggestOpen = false);
  }

  void _submit(String _) {
    final best = _suggestions.firstOrNull;
    if (best == null) {
      // Keep the dropdown open so "No matches" stays visible.
      setState(() => _suggestOpen = true);
      _portal.show();
      return;
    }
    _pick(best);
  }

  void _pick(_Suggestion s) {
    final label = s.town?.name ?? s.shop?.craft.name ?? s.poi!.name;
    _search.value = TextEditingValue(
      text: label,
      selection: TextSelection.collapsed(offset: label.length),
    );
    _searchFocus.unfocus();
    setState(() {
      _query = label;
      _suggestOpen = false;
      _expandedPlace = null;
    });
    if (s.town != null) {
      _map.focusTown(s.town!.id);
      _revealMap();
    } else if (s.shop != null) {
      _focusShop(s.shop!);
    } else {
      _showPoi(s.poi!);
    }
  }

  Widget _searchBar() {
    return TapRegion(
      groupId: _searchGroup,
      onTapOutside: (_) => _closeSuggestions(),
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _suggestionsOverlay,
        child: KeyedSubtree(
          key: _searchBoxKey,
          child: LayoutBuilder(
            builder: (context, box) {
              _searchWidth = box.maxWidth;
              return AppSearchField(
                controller: _search,
                focusNode: _searchFocus,
                hint: 'Search places, crafts, food…',
                onChanged: _onQuery,
                onSubmitted: _submit,
                onClear: () => _searchFocus.requestFocus(),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Google-style dropdown under the search pill.
  Widget _suggestionsOverlay(BuildContext context) {
    if (!_suggestOpen || _query.trim().isEmpty) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    final items = _suggestions;
    // Drop down just below the search bar (positioned explicitly so taps
    // and screenshots agree on where it is; the page closes it on scroll).
    final box = _searchBoxKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final at = box != null && box.hasSize
        ? box.localToGlobal(
            Offset(0, box.size.height + 6),
            ancestor: overlayBox,
          )
        : const Offset(20, 64);
    return Positioned(
      left: at.dx,
      top: at.dy,
      width: box?.size.width ?? _searchWidth,
      child: Builder(
        builder: (context) => TapRegion(
          groupId: _searchGroup,
          child: Material(
            key: const ValueKey('search-suggestions'),
            color: Colors.white,
            elevation: 3,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: items.isEmpty
                  ? Padding(
                      key: const ValueKey('search-no-results'),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No places or shops match "${_query.trim()}"',
                              style: t.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      children: [for (final s in items) _suggestionRow(s, t)],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _suggestionRow(_Suggestion s, TextTheme t) {
    final IconData icon;
    final Color color;
    final String title;
    final String subtitle;
    String? trailing;
    if (s.town case final town?) {
      final g = TownGuides.byId(town.id);
      final w = _map.weather.forTown(town.id);
      icon = Icons.place_outlined;
      color = AppColors.blue;
      title = town.name;
      subtitle = [
        ?g?.district,
        if (g != null && g.aliases.isNotEmpty) 'also ${g.aliases.join(', ')}',
      ].join(' · ');
      trailing = w?.short;
    } else if (s.shop case final shop?) {
      icon = shopIcon;
      color = shopColor;
      title = shop.craft.name;
      subtitle = '${shop.craft.category.label} · ${shop.townName}';
    } else {
      final poi = s.poi!;
      icon = poiIcon(poi.kind);
      color = poiColor(poi.kind);
      title = poi.name;
      subtitle = '${poi.kind.label} · ${poi.note}';
    }
    return InkWell(
      key: ValueKey(s.key),
      onTap: () => _pick(s),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Highlighted(title, query: _query.trim(), style: t.bodyLarge),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall,
                    ),
                ],
              ),
            ),
            if (trailing != null) Text(trailing, style: t.labelLarge),
          ],
        ),
      ),
    );
  }

  // --- Fullscreen & sheets --------------------------------------------------

  Future<void> _openFullscreen() async {
    _map.fullscreenOpen = true;
    await Navigator.of(context).push(
      fadeRoute<void>(
        ExploreMapFullscreen(
          controller: _map,
          onPoiTap: _showPoi,
          onShopTap: _showShop,
          onSelectionDetails: _openSelection,
        ),
      ),
    );
    // Carry the fullscreen camera back to the inline map, which then
    // reports its own visible area to the lists.
    _map.fullscreenOpen = false;
    _map.syncCamera();
  }

  /// "View details" on the map chip: the selected shop, guide or place.
  void _openSelection() {
    final shop = _map.selectedShop;
    if (shop != null) return _showShop(shop);
    final guideId = _map.selectedGuideId;
    if (guideId != null) {
      final guide = MockData.guides.firstWhere((g) => g.id == guideId);
      Navigator.of(context).push(fadeRoute(GuideDetailScreen(guide: guide)));
      return;
    }
    final id = _map.selectedTownId;
    final place = MockData.places.where((p) => p.id == id).firstOrNull;
    if (place != null) {
      Navigator.of(context).push(fadeRoute(PlaceDetailScreen(place: place)));
    } else if (_map.selectedTown case final town?) {
      showSoonSnack(context, '${town.name}: details coming soon');
    }
  }

  void _showShop(CraftShop shop) => _showCraft(shop.craft, shop: shop);

  void _openPlace(String townId) {
    final place = MockData.places.where((p) => p.id == townId).firstOrNull;
    if (place != null) {
      Navigator.of(context).push(fadeRoute(PlaceDetailScreen(place: place)));
    }
  }

  /// Craft info sheet, opened from a craft pin or the map chip.
  void _showCraft(Craft craft, {CraftShop? shop}) {
    final t = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const TintIcon(shopIcon, color: shopColor, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(craft.name, style: t.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          shop == null
                              ? '${craft.origin} · fair price ${craft.fairPrice}'
                              : '${craft.category.label} · ${shop.townName} · '
                                    '${_km(shop.lat, shop.lng)} · '
                                    'fair price ${craft.fairPrice}',
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  RatingLabel(craft.rating, count: craft.reviews),
                ],
              ),
              const SizedBox(height: 12),
              GenderRatingCompact(ratings: craft.ratings, showStar: false),
              const SizedBox(height: 12),
              Text(craft.description, style: t.bodyMedium),
              if (shop != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Shop location is approximate (sample data).',
                  style: t.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(sheet),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPoi(MapPoi poi) {
    final t = Theme.of(context).textTheme;
    final color = poiColor(poi.kind);
    final place = poi.placeId == null ? null : MockData.placeById(poi.placeId!);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TintIcon(poiIcon(poi.kind), color: color, size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(poi.name, style: t.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${poi.kind.label} · ${_km(poi.lat, poi.lng)} · ${poi.note}',
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (poi.phone != null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.red),
                  onPressed: () {
                    Navigator.pop(sheet);
                    callNumber(context, poi.phone!);
                  },
                  icon: const Icon(Icons.call),
                  label: Text('Call ${poi.phone}'),
                )
              else if (place != null)
                FilledButton(
                  onPressed: () {
                    Navigator.pop(sheet);
                    Navigator.of(context)
                        .push(fadeRoute(PlaceDetailScreen(place: place)));
                  },
                  child: Text('Open ${place.name}'),
                )
              else
                OutlinedButton(
                  onPressed: () => Navigator.pop(sheet),
                  child: const Text('Close'),
                ),
              if (poi.kind.isEmergency) ...[
                const SizedBox(height: 10),
                Text(
                  'Approximate location and placeholder number (sample '
                  'data). In danger, dial 112.',
                  textAlign: TextAlign.center,
                  style: t.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final infoTown = _infoTown;
    return NotificationListener<ScrollStartNotification>(
      onNotification: (n) {
        if (n.dragDetails != null && _suggestOpen) _closeSuggestions();
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: FadeIn(child: _searchBar()),
          ),
          FadeIn(
            index: 1,
            child: SectionHeader(
              'Nearby Point of Interest',
              subtitle: _map.viewportReady && _map.areaTown != null
                  ? 'Map near ${_map.areaTown!.name} · you are in '
                        '${MockData.mockLocationName}'
                  : 'From your location (${MockData.mockLocationName})',
            ),
          ),
          Padding(
            key: _mapKey,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FadeIn(
              index: 2,
              child: ExploreMap(
                controller: _map,
                onPoiTap: _showPoi,
                onShopTap: _showShop,
                onSelectionDetails: _openSelection,
                onFullscreen: _openFullscreen,
              ),
            ),
          ),
          // Town info card: slides open under the map after a search or a
          // tap on a town / place card.
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SizeTransition(
                  sizeFactor: a,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              ),
              child: infoTown == null
                  ? const SizedBox(
                      key: ValueKey('no-info'),
                      width: double.infinity,
                    )
                  : Padding(
                      key: ValueKey('town-info-${infoTown.id}'),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _TownInfoCard(
                        town: infoTown,
                        guide: TownGuides.byId(infoTown.id),
                        weather: _map.weather,
                        hasDetails: MockData.places.any(
                          (p) => p.id == infoTown.id,
                        ),
                        onDetails: () => _openPlace(infoTown.id),
                        onClose: () =>
                            setState(() => _infoClosedSeq = _map.focus?.seq),
                      ),
                    ),
            ),
          ),
          if (!_emergency)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: ExploreMapLegend(),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _emergency
                  ? _EmergencyPanel(
                      key: const ValueKey('emergency'),
                      map: _map,
                      onPoiTap: _showPoi,
                    )
                  : const SizedBox(
                      key: ValueKey('none'),
                      width: double.infinity,
                    ),
            ),
          ),
          const FadeIn(index: 3, child: SectionHeader('Places & Guides')),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: _expandedPlace == null ? 112 : _MiniCard.expandedHeight,
            child: ListView.separated(
              controller: _miniScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _miniItems.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, n) {
                final item = _miniItems[n];
                final expanded =
                    item.guideId == null && _expandedPlace == item.townId;
                return FadeIn(
                  index: n,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _MiniCard(
                      key: ValueKey('mini-${item.townId}-${item.guideId}'),
                      item: item,
                      index: n,
                      expanded: expanded,
                      selected:
                          _map.selectedTownId == item.townId &&
                          _map.selectedGuideId == item.guideId,
                      onTap: () => _focusItem(item),
                    ),
                  ),
                );
              },
            ),
          ),
          ..._craftsSection(t),
          SectionHeader(
            'Spots added by travellers',
            subtitle:
                'Marked real after ${CommunitySpot.requiredConfirmations} confirmations',
            action: TextButton.icon(
              onPressed: () => showSoonSnack(
                context,
                'Adding spots with photos is coming soon',
              ),
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text('Add'),
            ),
          ),
          for (final (n, s) in MockData.communitySpots.indexed)
            FadeIn(
              index: n,
              child: _SpotTile(spot: s),
            ),
        ],
      ),
    );
  }

  /// Town whose info card is open: the focused town (not a guide or shop
  /// focus) unless the user closed the card for this focus.
  MapTown? get _infoTown {
    final town = _map.selectedTown;
    if (town == null ||
        _map.selectedGuideId != null ||
        _map.selectedShopId != null ||
        _map.focus == null ||
        _map.focus!.seq == _infoClosedSeq) {
      return null;
    }
    return town;
  }

  /// "Local crafts & shops near …": the shops in the map's visible area,
  /// nearest to the map centre first.
  List<Widget> _craftsSection(TextTheme t) {
    final area = _map.areaShops;
    final shown = area.take(maxCraftRows).toList();
    final near = _map.areaTown?.name;
    final count = area.length;
    final subtitle = !_map.viewportReady
        ? 'Loading the map area…'
        : [
            '$count ${count == 1 ? 'place' : 'places'} in view',
            if (count > shown.length) 'nearest ${shown.length}',
            'sample data',
          ].join(' · ');
    final Widget body;
    if (!_map.viewportReady) {
      body = const SizedBox(key: ValueKey('crafts-loading'), height: 24);
    } else if (shown.isEmpty) {
      body = Padding(
        key: const ValueKey('crafts-empty'),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: OutlineCard(
          child: Row(
            children: [
              const TintIcon(
                Icons.storefront_outlined,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No crafts or shops in this area yet',
                  style: t.bodyMedium,
                ),
              ),
              TextButton(
                key: const ValueKey('crafts-show-nearest'),
                onPressed: () {
                  _map.showNearestShops();
                  _revealMap();
                },
                child: const Text('Show nearest'),
              ),
            ],
          ),
        ),
      );
    } else {
      body = Column(
        key: ValueKey('crafts-${shown.map((s) => s.id).join(',')}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (n, s) in shown.indexed)
            FadeIn(
              index: n,
              child: _ShopTile(
                key: ValueKey('shop-tile-${s.id}'),
                shop: s,
                distanceKm: _map.kmFromCenter(s.lat, s.lng),
                selected: _map.selectedShopId == s.id,
                onTap: () => _focusShop(s),
              ),
            ),
        ],
      );
    }
    return [
      SectionHeader(
        near == null
            ? 'Local crafts & shops'
            : 'Local crafts & shops near $near',
        key: const ValueKey('crafts-header'),
        subtitle: subtitle,
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          child: body,
        ),
      ),
    ];
  }
}

String _km(double lat, double lng) {
  final d = TripCalculator.straightKm(
    MockData.mockLat,
    MockData.mockLng,
    lat,
    lng,
  );
  return _fmtKm(d);
}

String _fmtKm(double d) =>
    d < 1 ? '${(d * 1000).round()} m' : '${d.toStringAsFixed(1)} km';

/// Bolds the part of [text] that matches [query] (search suggestions).
class _Highlighted extends StatelessWidget {
  const _Highlighted(this.text, {required this.query, this.style});
  final String text;
  final String query;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final i = query.isEmpty
        ? -1
        : text.toLowerCase().indexOf(query.toLowerCase());
    if (i < 0) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final bold = style?.copyWith(fontWeight: FontWeight.w700);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(text: text.substring(i, i + query.length), style: bold),
          TextSpan(text: text.substring(i + query.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Info card under the map for the focused town: temperature, a short
/// description, best season, how to reach and a link to the place page.
class _TownInfoCard extends StatelessWidget {
  const _TownInfoCard({
    required this.town,
    required this.guide,
    required this.weather,
    required this.hasDetails,
    required this.onDetails,
    required this.onClose,
  });
  final MapTown town;
  final TownGuide? guide;
  final WeatherStore weather;
  final bool hasDetails;
  final VoidCallback onDetails;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final w = weather.forTown(town.id);
    final g = guide;
    return OutlineCard(
      key: const ValueKey('town-info-card'),
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(town.name, style: t.titleMedium),
                    if (g != null) Text(g.district, style: t.bodySmall),
                  ],
                ),
              ),
              if (w != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            weatherIcon(w.code),
                            size: 20,
                            color: AppColors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            w.short,
                            key: const ValueKey('town-info-temp'),
                            style: t.titleLarge,
                          ),
                        ],
                      ),
                      Text(
                        [
                          if (weatherLabel(w.code).isNotEmpty)
                            weatherLabel(w.code),
                          weather.noteFor(w),
                        ].join(' · '),
                        style: t.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              IconButton(
                key: const ValueKey('town-info-close'),
                tooltip: 'Close',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
          if (g != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(g.description, style: t.bodyMedium),
            ),
            const SizedBox(height: 10),
            _SeasonChip(guide: g),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(g.seasonDetail, style: t.bodySmall),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.directions_car_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Nearest hub: ${g.reach}', style: t.bodySmall),
                ),
              ],
            ),
          ],
          if (hasDetails)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('town-info-details'),
                onPressed: onDetails,
                child: const Text('Details'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Coloured "Best Nov–Feb" chip with a season icon.
class _SeasonChip extends StatelessWidget {
  const _SeasonChip({required this.guide, this.compact = false});
  final TownGuide guide;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = seasonColor(guide.seasonIcon);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint(color, 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            seasonIconData(guide.seasonIcon),
            size: compact ? 12 : 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Best ${guide.bestLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Emergency contacts (India) and the emergency points in the map's
/// visible area, nearest to the map centre first.
class _EmergencyPanel extends StatelessWidget {
  const _EmergencyPanel({super.key, required this.map, required this.onPoiTap});
  final ExploreMapController map;
  final ValueChanged<MapPoi> onPoiTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pois = map.viewportReady
        ? map.areaEmergency
        : ([...map.emergencyPois]..sort(
            (a, b) => map
                .kmFromCenter(a.lat, a.lng)
                .compareTo(map.kmFromCenter(b.lat, b.lng)),
          ));
    final near = map.areaTown?.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          'Emergency contacts',
          subtitle: 'India numbers · free from any phone · tap to call',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final (i, c) in MockData.emergencyContacts.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: FadeIn(
                    index: i,
                    child: OutlineCard(
                      color: AppColors.redTint,
                      borderColor: const Color(0xFFF6C7C2),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      onTap: () => callNumber(context, c.number),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                c.number,
                                style: t.headlineSmall?.copyWith(
                                  color: const Color(0xFFB3261E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.call,
                                size: 18,
                                color: Color(0xFFB3261E),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: InfoNote(
            '112 connects to police, fire and ambulance anywhere in India. '
            'Mobile signal can be weak in the hills; try from higher ground.',
          ),
        ),
        SectionHeader(
          near == null ? 'Nearest help' : 'Nearest help near $near',
          key: const ValueKey('sos-header'),
          subtitle:
              '${pois.length} in view · approximate · sample data, '
              'placeholder numbers',
        ),
        if (pois.isEmpty)
          Padding(
            key: const ValueKey('sos-empty'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: OutlineCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'No emergency points in this area yet. Dial 112.',
                      style: t.bodyMedium,
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('sos-show-nearest'),
                    onPressed: map.showNearestEmergency,
                    child: const Text('Show nearest'),
                  ),
                ],
              ),
            ),
          ),
        for (final (i, p) in pois.indexed)
          FadeIn(
            key: ValueKey('sos-${p.name}'),
            index: i,
            child: ListTile(
              leading: TintIcon(poiIcon(p.kind), color: AppColors.red),
              title: Text(p.name),
              subtitle: Text(
                '${p.kind.label} · ${_fmtKm(map.kmFromCenter(p.lat, p.lng))} '
                '· ${p.note}',
              ),
              trailing: IconButton(
                tooltip: 'Call ${p.phone}',
                icon: const Icon(Icons.call_outlined, color: AppColors.red),
                onPressed: () => callNumber(context, p.phone ?? '112'),
              ),
              onTap: () => onPoiTap(p),
            ),
          ),
      ],
    );
  }
}

class _MiniItem {
  const _MiniItem(
    this.name,
    this.caption,
    this.icon,
    this.townId, [
    this.guideId,
  ]);
  final String name;
  final String caption;
  final IconData icon;

  /// Town the map focuses on: the place itself or the guide's base.
  final String townId;
  final String? guideId;
}

final _miniItems = <_MiniItem>[
  for (final (i, id) in [
    'tawang',
    'ziro',
    'dirang',
    'mechuka',
    'namdapha',
    'bomdila',
    'sela',
    'itanagar',
  ].indexed) ...[
    _MiniItem(
      MockData.placeById(id).name,
      MockData.placeById(id).district,
      Icons.landscape_outlined,
      id,
    ),
    if (i < MockData.guides.length)
      _MiniItem(
        MockData.guides[i].name.split(' ').first,
        'Guide · ${MockData.guides[i].tribe}',
        Icons.hiking,
        MockData.guides[i].placeId,
        MockData.guides[i].id,
      ),
  ],
];

/// Small pastel tile in the "Places & Guides" row.
class _MiniCard extends StatelessWidget {
  const _MiniCard({
    super.key,
    required this.item,
    required this.index,
    required this.selected,
    required this.onTap,
    this.expanded = false,
  });
  final _MiniItem item;
  final int index;
  final bool selected;

  /// Place cards widen to show the best season and risky months.
  final bool expanded;
  static const expandedHeight = 168.0;
  static const expandedWidth = 236.0;

  /// Focuses the item's town on the map (details open from the map chip).
  final VoidCallback onTap;

  static const _tints = [
    (AppColors.blueTint, AppColors.blue),
    (AppColors.redTint, AppColors.red),
    (AppColors.yellowTint, Color(0xFFE37400)),
    (AppColors.greenTint, AppColors.green),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (bg, fg) = _tints[index % _tints.length];
    return Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: expanded ? expandedWidth : 112,
        height: expanded ? expandedHeight : 112,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? fg : Colors.transparent,
            width: 2,
          ),
        ),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: expanded
                  ? _expandedBody(context, fg)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, size: 18, color: fg),
                        ),
                        const Spacer(),
                        if (selected)
                          Icon(Icons.my_location, size: 12, color: fg),
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleSmall,
                        ),
                        Text(
                          item.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Name, season chip, headline and risky months for an expanded card.
  Widget _expandedBody(BuildContext context, Color fg) {
    final t = Theme.of(context).textTheme;
    final g = TownGuides.byId(item.townId);
    final place = MockData.places.where((p) => p.id == item.townId).firstOrNull;
    final risky = place?.riskyMonths ?? g?.riskyMonths ?? const <int>[];
    return Column(
      key: ValueKey('mini-season-${item.townId}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 16, color: fg),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall,
                  ),
                  Text(
                    item.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.my_location, size: 12, color: fg),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (g != null) ...[
                _SeasonChip(guide: g, compact: true),
                const SizedBox(height: 5),
                Flexible(
                  child: Text(
                    g.seasonHeadline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 13,
              color: Color(0xFFB06000),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Risky: ${monthRanges(risky)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.labelSmall?.copyWith(color: const Color(0xFFB06000)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One craft / shop in the area list, with its distance from the map
/// centre and the gender split of its ratings.
class _ShopTile extends StatelessWidget {
  const _ShopTile({
    super.key,
    required this.shop,
    required this.distanceKm,
    required this.onTap,
    this.selected = false,
  });
  final CraftShop shop;
  final double distanceKm;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final craft = shop.craft;
    return ListTile(
      selected: selected,
      selectedTileColor: tint(shopColor, 0.07),
      leading: const TintIcon(shopIcon, color: shopColor),
      title: Row(
        children: [
          Flexible(
            child: Text(
              craft.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.text),
            ),
          ),
          const SizedBox(width: 6),
          TonePill('in ${shop.townName}', color: shopColor),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${craft.category.label} · ${craft.fairPrice} · '
            '${_fmtKm(distanceKm)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          GenderRatingCompact(
            ratings: craft.ratings,
            showStar: false,
            barWidth: 44,
          ),
        ],
      ),
      trailing: RatingLabel(craft.rating, count: craft.reviews),
      onTap: onTap,
    );
  }
}

class _SpotTile extends StatelessWidget {
  const _SpotTile({required this.spot});
  final CommunitySpot spot;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final progress = (spot.confirmations / CommunitySpot.requiredConfirmations)
        .clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: OutlineCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(spot.name, style: t.titleSmall)),
                spot.isConfirmedReal
                    ? const TonePill(
                        'Confirmed real',
                        color: AppColors.green,
                        icon: Icons.check,
                      )
                    : TonePill(
                        '${spot.confirmations}/${CommunitySpot.requiredConfirmations} confirmations',
                        color: AppColors.yellow,
                      ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${spot.near} · added by ${spot.addedBy} · ${spot.photos} photos',
              style: t.bodySmall,
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 4,
                  color: spot.isConfirmedReal
                      ? AppColors.green
                      : AppColors.yellow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
