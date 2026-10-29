import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../data/poi_repository.dart';
import '../data/weather_repository.dart';

/// What the map should animate to after a selection.
enum MapFocusKind { town, shop, me }

class MapFocusRequest {
  const MapFocusRequest(this.seq, this.kind);
  final int seq;
  final MapFocusKind kind;
}

/// Shared state for the inline Explore map and its fullscreen view:
/// emergency mode, the selected town / guide / craft shop, the loaded pins,
/// the last camera position (so both views open at the same spot) and the
/// shops / emergency points inside the visible map area ("viewport"), which
/// drive both the pins and the lists below the map.
class ExploreMapController extends ChangeNotifier {
  ExploreMapController({
    this.repository = const MockPoiRepository(),
    this._emergency = false,
    WeatherRepository? weatherRepository,
  }) : weather = WeatherStore(repository: weatherRepository) {
    weather.addListener(_onWeather);
  }

  final PoiRepository repository;

  /// Current temperature per town (live, cached or typical).
  final WeatherStore weather;

  void _onWeather() {
    if (!_disposed) notifyListeners();
  }

  /// Shops are shown around this town until the user picks another one.
  static const homeTownId = 'itanagar';

  static final me = LatLng(MockData.mockLat, MockData.mockLng);

  // --- Data ---------------------------------------------------------------

  List<MapTown> towns = const [];
  List<CraftShop> shops = const [];
  List<MapPoi> nearbyPois = MockData.nearbyPois;
  List<MapPoi> emergencyPois = MockData.emergencyPois;
  bool loaded = false;

  Future<void> load() async {
    final results = await Future.wait([
      repository.towns(),
      repository.crafts(),
      repository.nearbyPois(),
      repository.emergencyPois(),
    ]);
    towns = results[0] as List<MapTown>;
    shops = results[1] as List<CraftShop>;
    nearbyPois = results[2] as List<MapPoi>;
    emergencyPois = results[3] as List<MapPoi>;
    loaded = true;
    if (!_disposed) notifyListeners();
    // Background: cached values first, then live; never awaited by the UI.
    unawaited(weather.init(towns));
  }

  MapTown? townById(String? id) {
    if (id == null) return null;
    for (final t in towns) {
      if (t.id == id) return t;
    }
    return null;
  }

  // --- Emergency ----------------------------------------------------------

  bool _emergency;
  bool get emergency => _emergency;

  void toggleEmergency() {
    _emergency = !_emergency;
    notifyListeners();
  }

  // --- Selection ----------------------------------------------------------

  String? _townId;
  String? _guideId;
  String? _shopId;

  /// The focused town, or null before the user picks one.
  String? get selectedTownId => _townId;

  /// Set when the town was focused from a guide card.
  String? get selectedGuideId => _guideId;
  String? get selectedShopId => _shopId;

  MapTown? get selectedTown => townById(_townId);

  CraftShop? get selectedShop {
    for (final s in shops) {
      if (s.id == _shopId) return s;
    }
    return null;
  }

  /// All shops in [townId] (used to frame a town when it is focused).
  List<CraftShop> shopsOfTown(String townId) =>
      shops.where((s) => s.townId == townId).toList();

  /// Shops pinned on the map: the ones in the current viewport.
  List<CraftShop> get visibleShops => areaShops;

  void focusTown(String townId, {String? guideId}) {
    _townId = townId;
    _guideId = guideId;
    _shopId = null;
    _request(MapFocusKind.town);
  }

  void focusShop(CraftShop shop) {
    _townId = shop.townId;
    _guideId = null;
    _shopId = shop.id;
    _request(MapFocusKind.shop);
  }

  void recenter() => _request(MapFocusKind.me);

  void clearSelection() {
    _townId = null;
    _guideId = null;
    _shopId = null;
    notifyListeners();
  }

  // --- Camera -------------------------------------------------------------

  int _seq = 0;
  MapFocusRequest? _focus;

  /// Latest focus request; maps animate when its [MapFocusRequest.seq]
  /// changes.
  MapFocusRequest? get focus => _focus;

  void _request(MapFocusKind kind) {
    _focus = MapFocusRequest(++_seq, kind);
    notifyListeners();
  }

  LatLng? center;
  double? zoom;

  /// Bumped by [syncCamera] so a map that was hidden jumps to [center].
  int cameraSync = 0;

  /// Called by whichever map the user is moving. Does not notify.
  void rememberCamera(LatLng c, double z) {
    center = c;
    zoom = z;
  }

  /// Makes every map jump to the remembered camera (after fullscreen).
  void syncCamera() {
    cameraSync++;
    notifyListeners();
  }

  /// True while the fullscreen map is open; the inline map underneath then
  /// stops reporting its camera so only the visible map drives the lists.
  bool fullscreenOpen = false;

  // --- Viewport (what the map is looking at) ------------------------------

  /// Below this half-diagonal the visible bounds count as "tiny" and the
  /// area becomes a circle of this radius around the map centre.
  static const minAreaRadiusKm = 3.0;

  /// Below this zoom, shop / emergency pins collapse into per-town counts.
  static const clusterZoom = 10.5;

  /// Shops / emergency points inside the visible area, nearest to the map
  /// centre first.
  List<CraftShop> areaShops = const [];
  List<MapPoi> areaEmergency = const [];

  /// Centre and zoom the area lists were computed for.
  LatLng? viewCenter;
  double viewZoom = 13;

  /// False until the first viewport has been reported.
  bool viewportReady = false;
  int _viewSeq = 0;

  bool get clustered => viewZoom < clusterZoom;

  /// Town nearest to the map centre (names the "near …" headers).
  MapTown? get areaTown => nearestTown(viewCenter ?? me);

  MapTown? nearestTown(LatLng p, {bool withShops = false}) {
    MapTown? best;
    var bestKm = double.infinity;
    for (final t in towns) {
      if (withShops && !shops.any((s) => s.townId == t.id)) continue;
      final d = distanceKm(p, LatLng(t.lat, t.lng));
      if (d < bestKm) {
        bestKm = d;
        best = t;
      }
    }
    return best;
  }

  /// Km from the current map centre.
  double kmFromCenter(double lat, double lng) =>
      distanceKm(viewCenter ?? me, LatLng(lat, lng));

  /// Called (debounced) by the map whenever its camera settles. Queries the
  /// repository for what is in view and notifies listeners.
  Future<void> updateViewport(
    LatLngBounds bounds,
    LatLng center,
    double zoom,
  ) async {
    final seq = ++_viewSeq;
    final halfDiagonal = distanceKm(bounds.southWest, bounds.northEast) / 2;
    final tiny = halfDiagonal < minAreaRadiusKm;
    final results = await Future.wait<List<Object>>([
      tiny
          ? repository.shopsNear(center, minAreaRadiusKm)
          : repository.shopsInBounds(bounds),
      tiny
          ? repository.emergencyNear(center, minAreaRadiusKm)
          : repository.emergencyInBounds(bounds),
    ]);
    if (_disposed || seq != _viewSeq) return;
    double km(double lat, double lng) => distanceKm(center, LatLng(lat, lng));
    areaShops = [...results[0].cast<CraftShop>()]
      ..sort((a, b) => km(a.lat, a.lng).compareTo(km(b.lat, b.lng)));
    areaEmergency = [...results[1].cast<MapPoi>()]
      ..sort((a, b) => km(a.lat, a.lng).compareTo(km(b.lat, b.lng)));
    viewCenter = center;
    viewZoom = zoom;
    viewportReady = true;
    notifyListeners();
  }

  /// Flies to the town with shops nearest to the map centre (empty state).
  void showNearestShops() {
    final town = nearestTown(viewCenter ?? me, withShops: true);
    if (town != null) focusTown(town.id);
  }

  /// Flies to the town nearest to the map centre that has emergency points.
  void showNearestEmergency() {
    final c = viewCenter ?? me;
    MapPoi? best;
    for (final p in emergencyPois) {
      if (best == null ||
          distanceKm(c, LatLng(p.lat, p.lng)) <
              distanceKm(c, LatLng(best.lat, best.lng))) {
        best = p;
      }
    }
    if (best == null) return;
    final town = nearestTown(LatLng(best.lat, best.lng));
    if (town != null) focusTown(town.id);
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    weather.removeListener(_onWeather);
    weather.dispose();
    super.dispose();
  }
}
