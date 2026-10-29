import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../data/models.dart';
import '../data/weather_repository.dart';
import '../theme/app_colors.dart';
import 'common.dart';
import 'explore_map_controller.dart';
import 'visuals.dart';

/// Explore tab map: OpenStreetMap tiles via flutter_map with coloured POI
/// pins around the (mock) user location, town markers with temperature
/// chips, and craft-shop pins for whatever area is in view (collapsed into
/// per-town count badges when zoomed far out). Every time the camera
/// settles (debounced) the visible area is reported to the controller,
/// which drives the pins and the lists below the map. When tiles cannot
/// load (offline), a drawn
/// placeholder map stays visible underneath and an "Offline map" pill
/// appears. In emergency mode the card gets a red border and the pins
/// switch to emergency points.
///
/// The inline map keeps a 4:3 shape; [fullscreen] fills its parent. Both
/// share one [ExploreMapController], so selection, emergency mode and the
/// camera carry over between them.
class ExploreMap extends StatefulWidget {
  const ExploreMap({
    super.key,
    required this.controller,
    required this.onPoiTap,
    required this.onShopTap,
    required this.onSelectionDetails,
    this.onFullscreen,
    this.fullscreen = false,
  });

  final ExploreMapController controller;
  final ValueChanged<MapPoi> onPoiTap;
  final ValueChanged<CraftShop> onShopTap;

  /// "View details" in the info chip (place, guide or shop).
  final VoidCallback onSelectionDetails;

  /// Fullscreen / exit-fullscreen button.
  final VoidCallback? onFullscreen;
  final bool fullscreen;

  @override
  State<ExploreMap> createState() => _ExploreMapState();
}

class _ExploreMapState extends State<ExploreMap>
    with SingleTickerProviderStateMixin {
  final _map = MapController();
  late final AnimationController _anim = AnimationController(vsync: this)
    ..addListener(_tick);
  bool _tilesFailed = false;
  bool _ready = false;
  int _handledFocus = 0;
  late int _handledSync = widget.controller.cameraSync;
  Timer? _viewTimer;
  StreamSubscription<MapEvent>? _events;

  /// Debounce for viewport updates after the camera stops moving.
  static const viewportDebounce = Duration(milliseconds: 300);

  /// Max individual shop pins; beyond this the nearest are shown.
  static const maxShopPins = 40;

  // Current camera flight.
  LatLng _from = ExploreMapController.me;
  LatLng _to = ExploreMapController.me;
  double _fromZoom = 13;
  double _toZoom = 13;
  double _bump = 0;

  ExploreMapController get c => widget.controller;

  static const _fitPadding = EdgeInsets.fromLTRB(44, 76, 44, 64);

  /// Leaves room for the info chip (top) and emergency pill (bottom).
  static const _focusPadding = EdgeInsets.fromLTRB(48, 124, 56, 68);

  LatLngBounds get _homeBounds => LatLngBounds.fromPoints([
    ExploreMapController.me,
    for (final p in [...c.nearbyPois, ...c.emergencyPois]) LatLng(p.lat, p.lng),
  ]);

  @override
  void initState() {
    super.initState();
    // A fullscreen view opens at the current camera without replaying the
    // last focus animation.
    _handledFocus = c.focus?.seq ?? 0;
    c.addListener(_onController);
  }

  @override
  void didUpdateWidget(ExploreMap old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
    }
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _events?.cancel();
    c.removeListener(_onController);
    _anim.dispose();
    _map.dispose();
    super.dispose();
  }

  void _onController() {
    if (!mounted) return;
    setState(() {});
    if (c.cameraSync != _handledSync) {
      _handledSync = c.cameraSync;
      if (_ready && c.center != null) {
        _anim.stop();
        _map.move(c.center!, c.zoom!);
        // The move may be a no-op; report the area for this map anyway.
        _scheduleViewport();
      }
    }
    _maybeFocus();
  }

  /// Only the map on screen drives the shared camera and the area lists:
  /// the inline map stays quiet while the fullscreen map is open.
  bool get _drives => widget.fullscreen || !c.fullscreenOpen;

  void _onCamera(MapCamera cam, bool hasGesture) {
    if (!_drives) return;
    c.rememberCamera(cam.center, cam.zoom);
    // A user gesture cancels any running fly-to so the map follows the
    // finger; either way the area is recomputed once the camera settles.
    if (hasGesture && _anim.isAnimating) _anim.stop();
    _scheduleViewport();
  }

  void _onMapEvent(MapEvent e) {
    if (e is MapEventMoveEnd ||
        e is MapEventFlingAnimationEnd ||
        e is MapEventDoubleTapZoomEnd ||
        e is MapEventScrollWheelZoom) {
      _scheduleViewport();
    }
  }

  void _scheduleViewport() {
    if (!_drives) return;
    _viewTimer?.cancel();
    _viewTimer = Timer(viewportDebounce, _reportViewport);
  }

  void _reportViewport() {
    if (!mounted || !_ready || !_drives) return;
    // Wait for an in-flight fly-to to land.
    if (_anim.isAnimating) return _scheduleViewport();
    final cam = _map.camera;
    c.updateViewport(cam.visibleBounds, cam.center, cam.zoom);
  }

  void _maybeFocus() {
    final f = c.focus;
    if (!_ready || f == null || f.seq == _handledFocus) return;
    _handledFocus = f.seq;
    final cam = _map.camera;
    switch (f.kind) {
      case MapFocusKind.town:
        final town = c.selectedTown;
        if (town == null) return;
        final fit = CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([
            LatLng(town.lat, town.lng),
            for (final s in c.shopsOfTown(town.id)) LatLng(s.lat, s.lng),
          ]),
          padding: _focusPadding,
          maxZoom: 13.5,
        ).fit(cam);
        _flyTo(fit.center, fit.zoom);
      case MapFocusKind.shop:
        final shop = c.selectedShop;
        if (shop == null) return;
        final zoom = math.max(cam.zoom, 14.0);
        // Fit the single point so it lands below the info chip.
        final fit = CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([LatLng(shop.lat, shop.lng)]),
          padding: _focusPadding,
          maxZoom: zoom,
          minZoom: zoom,
        ).fit(cam);
        _flyTo(fit.center, fit.zoom);
      case MapFocusKind.me:
        final fit = CameraFit.bounds(
          bounds: _homeBounds,
          padding: _fitPadding,
        ).fit(cam);
        _flyTo(ExploreMapController.me, fit.zoom);
    }
  }

  /// Smooth camera move; long hops zoom out a little mid-flight.
  void _flyTo(LatLng dest, double zoom) {
    final cam = _map.camera;
    _from = cam.center;
    _fromZoom = cam.zoom;
    _to = dest;
    _toZoom = zoom;
    final km = const Distance().as(LengthUnit.Kilometer, _from, dest);
    _bump = km < 20 ? 0 : (math.log(km / 20) / math.ln2).clamp(0.0, 3.0);
    _anim.duration = Duration(milliseconds: km < 20 ? 650 : 1200);
    _anim.forward(from: 0);
  }

  void _tick() {
    final t = Curves.easeInOutCubic.transform(_anim.value);
    double lerp(double a, double b) => a + (b - a) * t;
    _map.move(
      LatLng(
        lerp(_from.latitude, _to.latitude),
        lerp(_from.longitude, _to.longitude),
      ),
      lerp(_fromZoom, _toZoom) - _bump * math.sin(math.pi * t),
    );
  }

  void _onTileError() {
    if (_tilesFailed) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_tilesFailed) setState(() => _tilesFailed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final emergency = c.emergency;
    final full = widget.fullscreen;
    final radius = full ? 0.0 : 20.0;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: full && !emergency
            ? null
            : Border.all(
                color: emergency ? AppColors.red : AppColors.border,
                width: emergency ? 2 : 1,
              ),
        boxShadow: emergency && !full
            ? [
                BoxShadow(
                  color: AppColors.red.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(full ? 0 : 18),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _OfflineMapPainter()),
            ),
            _buildMap(emergency),
            Positioned(
              left: 12,
              top: 12,
              right: 60,
              child: Align(
                alignment: Alignment.topLeft,
                // One slot: emergency status, else the selection chip (which
                // also notes "offline map"), else the offline pill.
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topLeft,
                    children: [...previous, ?current],
                  ),
                  child: emergency
                      ? const TonePill(
                          'Emergency points nearby',
                          key: ValueKey('e'),
                          color: AppColors.red,
                          icon: Icons.emergency_outlined,
                        )
                      : c.selectedTown != null
                      ? _infoChip()
                      : _tilesFailed
                      ? const TonePill(
                          'Offline map',
                          key: ValueKey('o'),
                          color: AppColors.textSecondary,
                          icon: Icons.cloud_off_outlined,
                        )
                      : const SizedBox.shrink(key: ValueKey('n')),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Column(
                children: [
                  if (widget.onFullscreen != null)
                    MapControlButton(
                      key: ValueKey(
                        full ? 'map-exit-fullscreen' : 'map-fullscreen',
                      ),
                      icon: full ? Icons.fullscreen_exit : Icons.fullscreen,
                      tooltip: full ? 'Exit fullscreen' : 'Fullscreen map',
                      onTap: widget.onFullscreen!,
                    ),
                  const SizedBox(height: 8),
                  MapControlButton(
                    key: const ValueKey('map-recenter'),
                    icon: Icons.my_location,
                    iconColor: AppColors.blue,
                    tooltip: 'Recenter on me',
                    onTap: c.recenter,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              bottom: 8,
              child: Text(
                '© OpenStreetMap contributors',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(fontSize: 9, color: AppColors.textTertiary),
              ),
            ),
            if (full && !emergency)
              const Positioned(
                left: 12,
                right: 12,
                bottom: 64,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: _LegendCard(),
                ),
              ),
            Positioned(
              right: 12,
              bottom: 12,
              child: _EmergencyPill(on: emergency, onTap: c.toggleEmergency),
            ),
          ],
        ),
      ),
    );
    return full ? card : AspectRatio(aspectRatio: 4 / 3, child: card);
  }

  Widget _buildMap(bool emergency) {
    final clustered = c.clustered;
    // Emergency pins follow the viewport like the shops do; before the
    // first viewport report, all known emergency points are shown.
    final emergencyPois = c.viewportReady ? c.areaEmergency : c.emergencyPois;
    final pois = emergency
        ? (clustered ? const <MapPoi>[] : emergencyPois)
        : c.nearbyPois;
    final selTown = c.selectedTownId;
    final selShop = c.selectedShopId;
    final selectedShop = emergency ? null : c.selectedShop;
    final shops = emergency || clustered
        ? const <CraftShop>[]
        : c.areaShops.take(maxShopPins).toList();
    // Far out: one count badge per town instead of every pin.
    final clusters = !clustered
        ? const <(MapTown, int)>[]
        : _clusters(
            emergency
                ? [for (final p in emergencyPois) LatLng(p.lat, p.lng)]
                : [for (final s in c.areaShops) LatLng(s.lat, s.lng)],
          );
    // The selected town gets a label, unless one of its shops is selected
    // (then the shop gets the label and the town stays a dot).
    final town = selectedShop != null ? null : c.selectedTown;
    final showTemps = c.viewZoom >= 7.5 || !c.viewportReady;
    final towns = [
      for (final t in c.towns)
        if (t.id != town?.id &&
            (t.id != ExploreMapController.homeTownId || t.id == selTown))
          t,
    ];
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: c.center ?? ExploreMapController.me,
        initialZoom: c.zoom ?? 13,
        initialCameraFit: c.center == null
            ? CameraFit.bounds(bounds: _homeBounds, padding: _fitPadding)
            : null,
        backgroundColor: Colors.transparent,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: () {
          _ready = true;
          _events = _map.mapEventStream.listen(_onMapEvent);
          final cam = _map.camera;
          if (_drives) {
            c.rememberCamera(cam.center, cam.zoom);
            c.updateViewport(cam.visibleBounds, cam.center, cam.zoom);
          }
          _maybeFocus();
        },
        onPositionChanged: _onCamera,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.explorearunachal.explore_arunachal',
          errorTileCallback: (_, _, _) => _onTileError(),
        ),
        MarkerLayer(
          markers: [
            for (final t in towns)
              Marker(
                key: ValueKey('town-${t.id}'),
                point: LatLng(t.lat, t.lng),
                width: 28,
                height: 28,
                child: _TownDot(
                  key: ValueKey('town-pin-${t.id}'),
                  town: t,
                  onTap: () => c.focusTown(t.id),
                ),
              ),
            for (final (t, n) in clusters)
              Marker(
                key: ValueKey('cluster-${t.id}'),
                point: LatLng(t.lat, t.lng),
                width: 30,
                height: 30,
                alignment: const Alignment(1.1, -1.1),
                child: _CountBadge(
                  key: ValueKey('cluster-badge-${t.id}'),
                  count: n,
                  color: emergency ? AppColors.red : shopColor,
                  onTap: () => c.focusTown(t.id),
                ),
              ),
            Marker(
              point: ExploreMapController.me,
              width: 26,
              height: 26,
              child: const _MeDot(),
            ),
            for (final (i, p) in pois.indexed)
              Marker(
                key: ValueKey('${p.name}-$emergency'),
                point: LatLng(p.lat, p.lng),
                width: 36,
                height: 36,
                child: _Pin(poi: p, delay: i, onTap: () => widget.onPoiTap(p)),
              ),
            for (final (i, s) in shops.indexed)
              if (s.id != selShop)
                Marker(
                  key: ValueKey('shop-${s.id}'),
                  point: LatLng(s.lat, s.lng),
                  width: 34,
                  height: 34,
                  child: _ShopPin(
                    key: ValueKey('shop-pin-${s.id}'),
                    shop: s,
                    delay: math.min(i, 8),
                    onTap: () => _tapShop(s),
                  ),
                ),
            // Temperature chips sit just below each town dot, above shop pins.
            for (final t in [...towns, ?town])
              if (showTemps || t.id == town?.id)
                if (c.weather.forTown(t.id) case final w?)
                  Marker(
                    key: ValueKey('temp-${t.id}'),
                    point: LatLng(t.lat, t.lng),
                    width: 88,
                    height: 40,
                    alignment: Alignment.bottomCenter,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _TempChip(
                          key: ValueKey('temp-chip-${t.id}'),
                          weather: w,
                          emphasis: t.id == town?.id,
                        ),
                      ),
                    ),
                  ),
            if (town != null)
              Marker(
                key: ValueKey('town-label-${town.id}'),
                point: LatLng(town.lat, town.lng),
                width: 160,
                height: 58,
                alignment: Alignment.topCenter,
                child: _LabelPin(
                  key: ValueKey('town-selected-${town.id}'),
                  label: town.name,
                  icon: townIcon,
                  color: AppColors.blue,
                  onTap: widget.onSelectionDetails,
                ),
              ),
            for (final s in [?selectedShop])
              Marker(
                key: ValueKey('shop-label-${s.id}'),
                point: LatLng(s.lat, s.lng),
                width: 180,
                height: 58,
                alignment: Alignment.topCenter,
                child: _LabelPin(
                  key: ValueKey('shop-selected-${s.id}'),
                  label: s.craft.name,
                  icon: shopIcon,
                  color: shopColor,
                  onTap: () => widget.onShopTap(s),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Groups [points] by their nearest town: (town, count), largest first.
  List<(MapTown, int)> _clusters(List<LatLng> points) {
    final counts = <String, int>{};
    for (final p in points) {
      final t = c.nearestTown(p);
      if (t != null) counts[t.id] = (counts[t.id] ?? 0) + 1;
    }
    return [
      for (final e in counts.entries)
        if (c.townById(e.key) case final t?) (t, e.value),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
  }

  void _tapShop(CraftShop s) {
    c.focusShop(s);
    widget.onShopTap(s);
  }

  /// Small white chip naming the selection, with a "details" action.
  Widget _infoChip() {
    final shop = c.selectedShop;
    final town = c.selectedTown;
    if (town == null) return const SizedBox.shrink(key: ValueKey('none'));
    final t = Theme.of(context).textTheme;
    final String title;
    final String subtitle;
    final String action;
    final Color color;
    final IconData icon;
    if (shop != null) {
      title = shop.craft.name;
      subtitle = 'Shop in ${shop.townName}';
      action = 'Details';
      color = shopColor;
      icon = shopIcon;
    } else if (c.selectedGuideId != null) {
      title = 'Guide base · ${town.name}';
      subtitle = '${c.shopsOfTown(town.id).length} craft shops';
      action = 'View guide';
      color = AppColors.green;
      icon = Icons.hiking;
    } else {
      title = town.name;
      final w = c.weather.forTown(town.id);
      subtitle = [
        if (w != null) '${w.short} ${c.weather.noteFor(w)}',
        '${c.shopsOfTown(town.id).length} craft shops',
      ].join(' · ');
      action = 'View details';
      color = AppColors.blue;
      icon = townIcon;
    }
    return KeyedSubtree(
      key: ValueKey('chip-${town.id}-${shop?.id}-${c.selectedGuideId}'),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _tilesFailed ? '$subtitle · offline' : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              key: const ValueKey('map-chip-details'),
              onPressed: widget.onSelectionDetails,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fullscreen Explore map, pushed as a fade route. Shares the controller
/// with the inline map so markers, selection and camera carry over.
class ExploreMapFullscreen extends StatelessWidget {
  const ExploreMapFullscreen({
    super.key,
    required this.controller,
    required this.onPoiTap,
    required this.onShopTap,
    required this.onSelectionDetails,
  });

  final ExploreMapController controller;
  final ValueChanged<MapPoi> onPoiTap;
  final ValueChanged<CraftShop> onShopTap;
  final VoidCallback onSelectionDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ExploreMap(
          controller: controller,
          fullscreen: true,
          onPoiTap: onPoiTap,
          onShopTap: onShopTap,
          onSelectionDetails: onSelectionDetails,
          onFullscreen: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

/// Colour key for the map pins.
class ExploreMapLegend extends StatelessWidget {
  const ExploreMapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final k in [
          PoiKind.sight,
          PoiKind.nature,
          PoiKind.craft,
          PoiKind.food,
          PoiKind.stay,
        ])
          DotLabel(k.label, color: poiColor(k)),
        const DotLabel('Crafts & shops', color: shopColor),
        const DotLabel('Towns', color: townColor),
      ],
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const ExploreMapLegend(),
    );
  }
}

/// Small white square map control with a light border (Google Maps style).
class MapControlButton extends StatelessWidget {
  const MapControlButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor = AppColors.textSecondary,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.borderStrong),
        ),
        elevation: 1,
        shadowColor: Colors.black26,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 22, color: iconColor),
          ),
        ),
      ),
    );
  }
}

/// Unselected town: small white dot with a town icon.
class _TownDot extends StatelessWidget {
  const _TownDot({super.key, required this.town, required this.onTap});
  final MapTown town;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: town.name,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: townColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(townIcon, size: 15, color: townColor),
        ),
      ),
    );
  }
}

/// Craft shop pin: teal rounded square with a storefront icon.
class _ShopPin extends StatelessWidget {
  const _ShopPin({
    super.key,
    required this.shop,
    required this.delay,
    required this.onTap,
  });
  final CraftShop shop;
  final int delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delay * 70),
      curve: Curves.easeOutBack,
      builder: (context, v, child) =>
          Transform.scale(scale: v.clamp(0.0, 1.2), child: child),
      child: Tooltip(
        message: '${shop.craft.name} · ${shop.townName}',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: shopColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(shopIcon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Small white "12°" chip with a weather icon under a town dot.
class _TempChip extends StatelessWidget {
  const _TempChip({super.key, required this.weather, this.emphasis = false});
  final TownWeather weather;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final typical = weather.source == WeatherSource.typical;
    final fg = typical ? AppColors.textSecondary : AppColors.text;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 1, 6, 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: emphasis ? AppColors.blue : AppColors.border,
          width: emphasis ? 1.2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(weatherIcon(weather.code), size: 11, color: fg),
          const SizedBox(width: 2),
          Text(
            typical ? '~${weather.short}' : weather.short,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Count of shops / emergency points around a town when zoomed far out.
class _CountBadge extends StatelessWidget {
  const _CountBadge({
    super.key,
    required this.count,
    required this.color,
    required this.onTap,
  });
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Highlighted marker: a labelled pill with a pointer, sitting above its
/// point (use with `Marker.alignment: Alignment.topCenter`).
class _LabelPin extends StatelessWidget {
  const _LabelPin({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(
        scale: v.clamp(0.0, 1.15),
        alignment: Alignment.bottomCenter,
        child: child,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: const Size(14, 8),
              painter: _PointerPainter(color),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}

class _EmergencyPill extends StatelessWidget {
  const _EmergencyPill({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final fg = on ? AppColors.red : Colors.white;
    return Semantics(
      button: true,
      toggled: on,
      label: 'Emergency mode',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: ShapeDecoration(
              color: on ? Colors.white : AppColors.red,
              shape: StadiumBorder(
                side: BorderSide(color: AppColors.red, width: on ? 1.5 : 0),
              ),
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  on ? Icons.close_rounded : Icons.emergency_outlined,
                  size: 16,
                  color: fg,
                ),
                const SizedBox(width: 6),
                Text(
                  on ? 'Exit emergency' : 'Emergency mode',
                  style: t.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.poi, required this.delay, required this.onTap});
  final MapPoi poi;
  final int delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = poiColor(poi.kind);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + delay * 60),
      curve: Curves.easeOutBack,
      builder: (context, v, child) =>
          Transform.scale(scale: v.clamp(0.0, 1.2), child: child),
      child: Tooltip(
        message: poi.name,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(poiIcon(poi.kind), size: 17, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Blue "you are here" dot with a soft halo.
class _MeDot extends StatelessWidget {
  const _MeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
        ),
      ),
    );
  }
}

/// Hand-drawn style terrain shown underneath (and instead of) map tiles.
class _OfflineMapPainter extends CustomPainter {
  const _OfflineMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF1F4EC),
    );

    // Forested hills
    final hill = Paint()..color = const Color(0xFFDCE9D2);
    final hill2 = Paint()..color = const Color(0xFFCFE2C3);
    for (final (x, y, r) in [
      (0.12, 0.2, 0.22),
      (0.85, 0.15, 0.25),
      (0.7, 0.85, 0.2),
      (0.2, 0.9, 0.18),
      (0.45, 0.05, 0.14),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x * w, y * h),
          width: r * w * 2,
          height: r * h * 1.6,
        ),
        hill,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x * w, y * h),
          width: r * w * 1.1,
          height: r * h * 0.9,
        ),
        hill2,
      );
    }

    // River
    final river = Path()..moveTo(-10, h * 0.62);
    for (var x = 0.0; x <= w + 10; x += 6) {
      river.lineTo(x, h * 0.62 + math.sin(x / w * math.pi * 2.4) * h * 0.08);
    }
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFB9D7F2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // Roads
    final roadEdge = Paint()
      ..color = const Color(0xFFE0E0D8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5;
    final road = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    final roads = [
      Path()
        ..moveTo(0, h * 0.42)
        ..cubicTo(w * 0.3, h * 0.30, w * 0.55, h * 0.55, w, h * 0.38),
      Path()
        ..moveTo(w * 0.36, 0)
        ..cubicTo(w * 0.40, h * 0.35, w * 0.30, h * 0.65, w * 0.42, h),
      Path()
        ..moveTo(w * 0.6, h * 0.45)
        ..quadraticBezierTo(w * 0.75, h * 0.7, w * 0.95, h * 0.78),
    ];
    for (final r in roads) {
      canvas.drawPath(r, roadEdge);
      canvas.drawPath(r, road);
    }
  }

  @override
  bool shouldRepaint(_OfflineMapPainter oldDelegate) => false;
}
