import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'mock_data.dart';
import 'models.dart';

/// Minimal, safe access to Firebase. Nothing here throws: when Firebase is
/// not initialised, offline with an empty cache, or the data is malformed,
/// callers get the bundled mock data instead.
///
/// Screens still read [MockData] directly; this is the seam for moving them
/// to Firestore later.
abstract final class AppFirebaseService {
  static bool _ready = false;

  /// True once `Firebase.initializeApp` has succeeded in `main`.
  static bool get isFirebaseReady => _ready;

  /// Called by `main` after a successful `Firebase.initializeApp`.
  static void markReady() => _ready = true;

  /// Name of the Firestore collection holding places.
  static const placesCollection = 'places';

  /// Fetches places from Firestore's `places` collection, falling back to
  /// [MockData.places] if Firebase isn't ready, the query fails, or the
  /// collection is empty. Documents missing fields are filled from the mock
  /// place with the same id; unknown documents that can't be parsed are
  /// skipped.
  static Future<List<Place>> fetchPlaces() async {
    if (!_ready) return MockData.places;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(placesCollection)
          .get()
          .timeout(const Duration(seconds: 8));
      final places = <Place>[];
      for (final doc in snap.docs) {
        final place = _placeFromDoc(doc.id, doc.data());
        if (place != null) places.add(place);
      }
      if (places.isEmpty) return MockData.places;
      places.sort((a, b) => a.routeOrder.compareTo(b.routeOrder));
      return places;
    } catch (e) {
      debugPrint('fetchPlaces: using mock data ($e)');
      return MockData.places;
    }
  }

  static Place? _placeFromDoc(String id, Map<String, dynamic> d) {
    try {
      final mock = MockData.places.where((p) => p.id == id).firstOrNull;
      T pick<T>(String key, T? fallback) {
        final v = d[key];
        if (v is T) return v;
        if (fallback != null) return fallback;
        throw FormatException('missing $key');
      }

      List<int>? months(String key) =>
          (d[key] as List?)?.map((e) => (e as num).toInt()).toList();

      Map<String, TravelLeg>? legs() {
        final raw = d['fromHubs'];
        if (raw is! Map) return null;
        return raw.map((hub, leg) {
          final m = leg as Map;
          return MapEntry(
            hub as String,
            TravelLeg(
              (m['km'] as num).toInt(),
              (m['hours'] as num).toDouble(),
              estimated: m['estimated'] == true,
            ),
          );
        });
      }

      return Place(
        id: id,
        name: pick<String>('name', mock?.name),
        district: pick<String>('district', mock?.district),
        tagline: pick<String>('tagline', mock?.tagline),
        description: pick<String>('description', mock?.description),
        altitudeM:
            (d['altitudeM'] as num?)?.toInt() ??
            pick<int>('altitudeM', mock?.altitudeM),
        lat: (d['lat'] as num?)?.toDouble() ?? pick<double>('lat', mock?.lat),
        lng: (d['lng'] as num?)?.toDouble() ?? pick<double>('lng', mock?.lng),
        bestMonths:
            months('bestMonths') ??
            pick<List<int>>('bestMonths', mock?.bestMonths),
        riskyMonths:
            months('riskyMonths') ??
            pick<List<int>>('riskyMonths', mock?.riskyMonths),
        seasonNote: pick<String>('seasonNote', mock?.seasonNote),
        riskNote: pick<String>('riskNote', mock?.riskNote),
        fromHubs:
            legs() ?? pick<Map<String, TravelLeg>>('fromHubs', mock?.fromHubs),
        suggestedDays:
            (d['suggestedDays'] as num?)?.toInt() ??
            pick<int>('suggestedDays', mock?.suggestedDays),
        routeOrder:
            (d['routeOrder'] as num?)?.toInt() ??
            pick<int>('routeOrder', mock?.routeOrder),
        howToReach: pick<String>('howToReach', mock?.howToReach),
      );
    } catch (e) {
      debugPrint('fetchPlaces: skipping place "$id" ($e)');
      return null;
    }
  }
}
