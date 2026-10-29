import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

import 'mock_data.dart';
import 'models.dart';

/// Data source for everything the Explore map pins: towns, craft shops and
/// points of interest.
///
/// TODO(api): Replace [MockPoiRepository] with a real implementation (e.g.
/// `ApiPoiRepository`) that calls the crafts/shops database API once it is
/// available, and pass it to `ExploreScreen(repository: ...)`. Only this
/// interface is used by the UI, so nothing else needs to change. The area
/// queries ([shopsInBounds], [shopsNear], [emergencyInBounds],
/// [emergencyNear]) map directly onto API endpoints that accept a bounding
/// box (`?bbox=south,west,north,east`) or a centre + radius
/// (`?lat=&lng=&radius_km=`); the Explore map calls them every time the
/// camera settles.
abstract class PoiRepository {
  /// Towns that can be focused on the map.
  Future<List<MapTown>> towns();

  /// Craft shops with coordinates. When [townId] is given, only shops in
  /// that town are returned.
  Future<List<CraftShop>> crafts({String? townId});

  /// Everyday points of interest around the user.
  Future<List<MapPoi>> nearbyPois();

  /// Hospitals, police, army posts and fire stations for emergency mode.
  Future<List<MapPoi>> emergencyPois();

  /// Craft shops inside [bounds] (the map's visible area).
  Future<List<CraftShop>> shopsInBounds(LatLngBounds bounds);

  /// Craft shops within [radiusKm] of [center].
  Future<List<CraftShop>> shopsNear(LatLng center, double radiusKm);

  /// Emergency points inside [bounds].
  Future<List<MapPoi>> emergencyInBounds(LatLngBounds bounds);

  /// Emergency points within [radiusKm] of [center].
  Future<List<MapPoi>> emergencyNear(LatLng center, double radiusKm);
}

/// Straight-line distance in km (haversine via latlong2).
double distanceKm(LatLng a, LatLng b) =>
    const Distance().as(LengthUnit.Meter, a, b) / 1000;

/// Whether ([lat], [lng]) is inside [b] (inclusive).
bool boundsContain(LatLngBounds b, double lat, double lng) =>
    lat >= b.south && lat <= b.north && lng >= b.west && lng <= b.east;

/// Bundled SAMPLE data (made up for the demo). Craft shops get PLACEHOLDER
/// coordinates: a stable pseudo-random point 0.5–3 km from the town centre
/// (never straight north, where the town label sits), seeded from the shop
/// id so pins never move between launches. Sample emergency points get the
/// same treatment at 0.3–2.5 km.
class MockPoiRepository implements PoiRepository {
  const MockPoiRepository();

  /// Every town on the map: all [MockData.places] plus craft-only towns.
  static final List<MapTown> allTowns = [
    for (final p in MockData.places)
      MapTown(id: p.id, name: p.name, lat: p.lat, lng: p.lng),
    ...MockData.extraCraftTowns,
  ];

  static MapTown? townById(String id) {
    for (final t in allTowns) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// All placeholder shops, built once: the classic [MockData.crafts] plus
  /// the per-town [MockData.sampleShops].
  static final List<CraftShop> allShops = [
    for (final c in [...MockData.crafts, ...MockData.sampleShops])
      for (final id in c.townIds)
        if (townById(id) case final town?) shopFor(c, town),
  ];

  /// Builds the placeholder shop for [craft] in [town].
  static CraftShop shopFor(Craft craft, MapTown town) {
    final id = '${craft.id}@${town.id}';
    final (lat, lng) = placeholderOffset(id, town.lat, town.lng);
    return CraftShop(
      id: id,
      craft: craft,
      townId: town.id,
      townName: town.name,
      lat: lat,
      lng: lng,
    );
  }

  /// Itanagar's original emergency points plus a sample set around every
  /// other town, built once.
  static final List<MapPoi> allEmergency = [
    ...MockData.emergencyPois,
    for (final e in MockData.sampleEmergency)
      if (townById(e.townId) case final town?) emergencyFor(e, town),
  ];

  /// Builds a placeholder emergency point 0.3–2.5 km from [town].
  static MapPoi emergencyFor(SampleEmergencySeed e, MapTown town) {
    final (lat, lng) = placeholderOffset(
      'sos:${e.townId}:${e.name}',
      town.lat,
      town.lng,
      minKm: 0.3,
      maxKm: 2.5,
    );
    return MapPoi(
      name: e.name,
      kind: e.kind,
      lat: lat,
      lng: lng,
      note: '${e.note} · sample number',
      phone: e.phone,
    );
  }

  /// Deterministic point [minKm]–[maxKm] (default 0.5–3 km) from
  /// ([lat], [lng]), seeded by [seedId].
  static (double, double) placeholderOffset(
    String seedId,
    double lat,
    double lng, {
    double minKm = 0.5,
    double maxKm = 3,
  }) {
    final r = math.Random(stableSeed(seedId));
    final km = minKm + r.nextDouble() * (maxKm - minKm);
    // Bearing 70°–290° (clockwise from north): keeps shops out of the
    // sector straight above the town, where its map label is drawn.
    final bearing = (70 + r.nextDouble() * 220) * math.pi / 180;
    const kmPerDegLat = 111.32;
    final kmPerDegLng = kmPerDegLat * math.cos(lat * math.pi / 180);
    return (
      lat + km * math.cos(bearing) / kmPerDegLat,
      lng + km * math.sin(bearing) / kmPerDegLng,
    );
  }

  /// FNV-1a hash of [s]: unlike [String.hashCode] it is the same on every
  /// platform and launch.
  static int stableSeed(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }

  @override
  Future<List<MapTown>> towns() async => allTowns;

  @override
  Future<List<CraftShop>> crafts({String? townId}) async => townId == null
      ? allShops
      : allShops.where((s) => s.townId == townId).toList();

  @override
  Future<List<MapPoi>> nearbyPois() async => MockData.nearbyPois;

  @override
  Future<List<MapPoi>> emergencyPois() async => allEmergency;

  @override
  Future<List<CraftShop>> shopsInBounds(LatLngBounds bounds) async => [
    for (final s in allShops)
      if (boundsContain(bounds, s.lat, s.lng)) s,
  ];

  @override
  Future<List<CraftShop>> shopsNear(LatLng center, double radiusKm) async => [
    for (final s in allShops)
      if (distanceKm(center, LatLng(s.lat, s.lng)) <= radiusKm) s,
  ];

  @override
  Future<List<MapPoi>> emergencyInBounds(LatLngBounds bounds) async => [
    for (final p in allEmergency)
      if (boundsContain(bounds, p.lat, p.lng)) p,
  ];

  @override
  Future<List<MapPoi>> emergencyNear(LatLng center, double radiusKm) async => [
    for (final p in allEmergency)
      if (distanceKm(center, LatLng(p.lat, p.lng)) <= radiusKm) p,
  ];
}
