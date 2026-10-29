import 'dart:math' as math;

import 'mock_data.dart';
import 'models.dart';

enum TransportMode { shared, taxi }

enum Comfort { budget, comfort }

class RouteLeg {
  const RouteLeg(this.from, this.to, this.leg);
  final String from;
  final String to;
  final TravelLeg leg;
}

class TripEstimate {
  const TripEstimate({
    required this.legs,
    required this.totalKm,
    required this.totalHours,
    required this.days,
    required this.stayLow,
    required this.stayHigh,
    required this.foodLow,
    required this.foodHigh,
    required this.transportLow,
    required this.transportHigh,
    required this.permitLow,
    required this.permitHigh,
  });

  final List<RouteLeg> legs;
  final int totalKm;
  final double totalHours;
  final int days;
  final int stayLow, stayHigh;
  final int foodLow, foodHigh;
  final int transportLow, transportHigh;
  final int permitLow, permitHigh;

  int get totalLow => stayLow + foodLow + transportLow + permitLow;
  int get totalHigh => stayHigh + foodHigh + transportHigh + permitHigh;
  bool get hasEstimatedLegs => legs.any((l) => l.leg.estimated);
}

/// Approximate trip maths for offline planning. All rates are rough fair-price
/// guides, not quotes.
abstract final class TripCalculator {
  /// Average driving hours per day on hill roads.
  static const drivingHoursPerDay = 7.0;

  static double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  static double straightKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) => _haversineKm(lat1, lng1, lat2, lng2);

  /// Hill roads are roughly 1.8× the straight-line distance at ~28 km/h.
  static TravelLeg _estimate(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final km = (_haversineKm(lat1, lng1, lat2, lng2) * 1.8).round();
    final hours = (km / 28 * 2).round() / 2;
    return TravelLeg(km, hours, estimated: true);
  }

  static TravelLeg hubToPlace(Hub hub, Place place) =>
      place.fromHubs[hub.id] ??
      _estimate(hub.lat, hub.lng, place.lat, place.lng);

  static TravelLeg placeToPlace(Place a, Place b) =>
      MockData.placeLegs['${a.id}|${b.id}'] ??
      MockData.placeLegs['${b.id}|${a.id}'] ??
      _estimate(a.lat, a.lng, b.lat, b.lng);

  static TripEstimate estimate({
    required Hub hub,
    required List<Place> places,
    required int travellers,
    required TransportMode mode,
    required Comfort comfort,
    required bool foreigner,
  }) {
    final ordered = [...places]
      ..sort((a, b) => a.routeOrder.compareTo(b.routeOrder));
    final legs = <RouteLeg>[];
    if (ordered.isNotEmpty) {
      legs.add(
        RouteLeg(hub.name, ordered.first.name, hubToPlace(hub, ordered.first)),
      );
      for (var i = 0; i < ordered.length - 1; i++) {
        legs.add(
          RouteLeg(
            ordered[i].name,
            ordered[i + 1].name,
            placeToPlace(ordered[i], ordered[i + 1]),
          ),
        );
      }
      legs.add(
        RouteLeg(ordered.last.name, hub.name, hubToPlace(hub, ordered.last)),
      );
    }

    final totalKm = legs.fold<int>(0, (s, l) => s + l.leg.km);
    final totalHours = legs.fold<double>(0, (s, l) => s + l.leg.hours);
    final stayDays = ordered.fold<int>(0, (s, p) => s + p.suggestedDays);
    final travelDays = (totalHours / drivingHoursPerDay).ceil();
    final days = ordered.isEmpty ? 0 : math.max(1, stayDays + travelDays);
    final nights = math.max(0, days - 1);

    // Rooms: two travellers per room.
    final rooms = (travellers / 2).ceil();
    final (roomLow, roomHigh) = switch (comfort) {
      Comfort.budget => (1200, 2000),
      Comfort.comfort => (2200, 4000),
    };
    final (foodPpLow, foodPpHigh) = switch (comfort) {
      Comfort.budget => (450, 700),
      Comfort.comfort => (800, 1300),
    };

    late int transportLow, transportHigh;
    switch (mode) {
      case TransportMode.shared:
        // Shared Sumo / bus, per person per km.
        transportLow = (totalKm * 2.5 * travellers).round();
        transportHigh = (totalKm * 3.5 * travellers).round();
      case TransportMode.taxi:
        // Reserved hill taxi, per vehicle (up to 4–5 people) per km.
        final vehicles = (travellers / 4).ceil();
        transportLow = (totalKm * 20 * vehicles).round();
        transportHigh = (totalKm * 28 * vehicles).round();
    }

    // Permits: ILP fee is small; PAP for foreigners varies widely.
    final permitLow = ordered.isEmpty ? 0 : (foreigner ? 0 : 100 * travellers);
    final permitHigh = ordered.isEmpty ? 0 : (foreigner ? 0 : 400 * travellers);

    return TripEstimate(
      legs: legs,
      totalKm: totalKm,
      totalHours: totalHours,
      days: days,
      stayLow: nights * rooms * roomLow,
      stayHigh: nights * rooms * roomHigh,
      foodLow: days * travellers * foodPpLow,
      foodHigh: days * travellers * foodPpHigh,
      transportLow: transportLow,
      transportHigh: transportHigh,
      permitLow: permitLow,
      permitHigh: permitHigh,
    );
  }
}

String formatRupees(int value) {
  final s = value.toString();
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹${parts.join(',')},$last3';
}

String formatHours(double h) {
  if (h < 1) return '${(h * 60).round()} min';
  final whole = h.floor();
  final half = h - whole >= 0.5;
  return half ? '$whole½ h' : '$whole h';
}

const monthShort = [
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

/// Compresses month lists into ranges, e.g. [3,4,5,9,10] -> "Mar–May, Sep–Oct".
/// Handles winter ranges that wrap around the year, e.g. Dec–Feb.
String monthRanges(List<int> months) {
  if (months.isEmpty) return '—';
  final sorted = months.toSet().toList()..sort();
  final groups = <List<int>>[];
  for (final m in sorted) {
    if (groups.isNotEmpty && groups.last.last == m - 1) {
      groups.last.add(m);
    } else {
      groups.add([m]);
    }
  }
  if (groups.length > 1 && groups.first.first == 1 && groups.last.last == 12) {
    final first = groups.removeAt(0);
    groups.last.addAll(first);
  }
  // Start listing from the group that begins latest in a "wrapping" sense so
  // Dec–Feb reads naturally; otherwise keep calendar order.
  return groups
      .map(
        (g) => g.length == 1
            ? monthShort[g.first - 1]
            : '${monthShort[g.first - 1]}–${monthShort[g.last - 1]}',
      )
      .join(', ');
}
