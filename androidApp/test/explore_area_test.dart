import 'dart:convert';

import 'package:explore_arunachal/data/mock_data.dart';
import 'package:explore_arunachal/data/models.dart';
import 'package:explore_arunachal/data/poi_repository.dart';
import 'package:explore_arunachal/data/town_guides.dart';
import 'package:explore_arunachal/data/weather_repository.dart';
import 'package:explore_arunachal/screens/traveller/explore_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository whose area queries never find anything (empty state).
class _EmptyAreaRepository extends MockPoiRepository {
  const _EmptyAreaRepository();

  @override
  Future<List<CraftShop>> shopsInBounds(LatLngBounds bounds) async => [];

  @override
  Future<List<CraftShop>> shopsNear(LatLng center, double radiusKm) async => [];
}

LatLngBounds _around(MapTown t, double deg) => LatLngBounds(
  LatLng(t.lat - deg, t.lng - deg),
  LatLng(t.lat + deg, t.lng + deg),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const repo = MockPoiRepository();
  final tawang = MockPoiRepository.townById('tawang')!;

  group('Area queries (sample data)', () {
    test('every searchable town has 3+ shops, 2+ emergency points and a '
        'guide', () async {
      final shops = await repo.crafts();
      final sos = await repo.emergencyPois();
      for (final t in MockPoiRepository.allTowns) {
        expect(
          shops.where((s) => s.townId == t.id).length,
          greaterThanOrEqualTo(3),
          reason: t.id,
        );
        expect(
          sos
              .where(
                (p) =>
                    distanceKm(LatLng(t.lat, t.lng), LatLng(p.lat, p.lng)) < 10,
              )
              .length,
          greaterThanOrEqualTo(2),
          reason: t.id,
        );
        expect(TownGuides.byId(t.id), isNotNull, reason: t.id);
      }
    });

    test('shopsInBounds returns only the shops inside the box', () async {
      final inBox = await repo.shopsInBounds(_around(tawang, 0.05));
      final tawangShops = await repo.crafts(townId: 'tawang');
      expect(
        inBox.map((s) => s.id).toSet(),
        tawangShops.map((s) => s.id).toSet(),
      );
      expect(tawangShops.length, inInclusiveRange(3, 8));
    });

    test('shopsNear filters by radius', () async {
      final c = LatLng(tawang.lat, tawang.lng);
      final near = await repo.shopsNear(c, 5);
      expect(near, isNotEmpty);
      expect(near.every((s) => s.townId == 'tawang'), isTrue);
      for (final s in near) {
        expect(distanceKm(c, LatLng(s.lat, s.lng)), lessThanOrEqualTo(5));
      }
      expect(await repo.shopsNear(c, 0.1), isEmpty);
    });

    test('emergency points are filtered by area', () async {
      final inBox = await repo.emergencyInBounds(_around(tawang, 0.05));
      final names = inBox.map((p) => p.name).toSet();
      expect(names, contains('Tawang District Hospital'));
      expect(names, contains('Tawang Police Station'));
      expect(names, isNot(contains('TRIHMS Hospital, Naharlagun')));
      expect(inBox.every((p) => p.kind.isEmergency), isTrue);
      final near = await repo.emergencyNear(LatLng(tawang.lat, tawang.lng), 3);
      expect(near.map((p) => p.name).toSet(), names);
      // Sample points sit 0.3–2.5 km from their town with fake numbers.
      for (final e in MockData.sampleEmergency) {
        final t = MockPoiRepository.townById(e.townId)!;
        final p = MockPoiRepository.emergencyFor(e, t);
        final d = distanceKm(LatLng(t.lat, t.lng), LatLng(p.lat, p.lng));
        expect(d, inInclusiveRange(0.29, 2.51), reason: e.name);
        expect(p.phone, startsWith('+91 90000 0'));
        expect(p.note, contains('sample'));
      }
    });
  });

  group('Weather fallback', () {
    test('no network and no cache gives the typical temperature', () async {
      final store = WeatherStore(repository: const OfflineWeatherRepository());
      await store.init(MockPoiRepository.allTowns);
      final w = store.forTown('changlang')!;
      expect(w.source, WeatherSource.typical);
      expect(
        w.tempC.round(),
        TownGuides.byId('changlang')!.typicalC(DateTime.now().month),
      );
      expect(store.noteFor(w), startsWith('typical for'));
    });

    test('offline uses the cached value with its age', () async {
      final at = DateTime.now().subtract(const Duration(hours: 3));
      SharedPreferences.setMockInitialValues({
        WeatherStore.cacheKey: jsonEncode({
          'tawang': {'t': 4.4, 'c': 71, 'at': at.millisecondsSinceEpoch},
        }),
      });
      final store = WeatherStore(repository: const OfflineWeatherRepository());
      await store.init(MockPoiRepository.allTowns);
      final w = store.forTown('tawang')!;
      expect(w.source, WeatherSource.cached);
      expect(w.short, '4°');
      expect(store.noteFor(w), 'updated 3h ago');
    });

    test('Open-Meteo request batches coordinates', () {
      final uri = OpenMeteoWeatherRepository.uriFor(
        MockPoiRepository.allTowns.take(2).toList(),
      );
      expect(uri.host, 'api.open-meteo.com');
      expect(uri.queryParameters['latitude']!.split(','), hasLength(2));
      expect(uri.queryParameters['current'], 'temperature_2m,weather_code');
    });
  });

  group('Explore search and area list', () {
    Future<void> pumpExplore(
      WidgetTester tester, {
      PoiRepository repository = const MockPoiRepository(),
    }) async {
      await tester.binding.setSurfaceSize(const Size(1000, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExploreScreen(
              repository: repository,
              weatherRepository: const OfflineWeatherRepository(),
            ),
          ),
        ),
      );
      // Map ready + 300 ms viewport debounce + list animations.
      await tester.pump(const Duration(seconds: 2));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    Future<void> search(WidgetTester tester, String q) async {
      await tester.enterText(find.byType(TextField), q);
      await tester.pump();
    }

    testWidgets('searching "tawang" focuses Tawang and lists only Tawang '
        'shops', (tester) async {
      await pumpExplore(tester);
      await search(tester, 'taw');
      expect(find.byKey(const ValueKey('search-suggestions')), findsOneWidget);
      await search(tester, 'tawang');
      await tester.tap(find.byKey(const ValueKey('suggest-town-tawang')));
      await settle(tester);

      final label = find.byKey(const ValueKey('town-selected-tawang'));
      expect(label, findsOneWidget);
      final cam = MapCamera.of(tester.element(label));
      expect(
        distanceKm(cam.center, LatLng(tawang.lat, tawang.lng)),
        lessThan(5),
      );
      expect(find.text('Local crafts & shops near Tawang'), findsOneWidget);
      final all = await repo.crafts();
      for (final s in all) {
        expect(
          find.byKey(ValueKey('shop-tile-${s.id}')),
          s.townId == 'tawang' ? findsOneWidget : findsNothing,
          reason: s.id,
        );
      }
    });

    testWidgets('enter picks the best match; no results is handled', (
      tester,
    ) async {
      await pumpExplore(tester);
      await search(tester, 'ZIR');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester);
      expect(find.byKey(const ValueKey('town-selected-ziro')), findsOneWidget);
      expect(find.text('Local crafts & shops near Ziro'), findsOneWidget);

      await search(tester, 'qqqxyz');
      expect(find.byKey(const ValueKey('search-no-results')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('search-clear')));
      await tester.pump();
      expect(find.byKey(const ValueKey('search-no-results')), findsNothing);
    });

    testWidgets('searching "changlang" opens the info card with a typical '
        'temperature', (tester) async {
      await pumpExplore(tester);
      await search(tester, 'changlang');
      await tester.tap(find.byKey(const ValueKey('suggest-town-changlang')));
      await settle(tester);
      final card = find.byKey(const ValueKey('town-info-card'));
      expect(card, findsOneWidget);
      final typical = TownGuides.byId('changlang')!
          .typicalC(DateTime.now().month);
      expect(
        find.descendant(of: card, matching: find.text('$typical°')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.textContaining('typical for')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.textContaining('Stilwell')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('temp-chip-changlang')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('town-info-close')));
      await settle(tester);
      expect(card, findsNothing);
    });

    testWidgets('a place card expands with its best season', (tester) async {
      await pumpExplore(tester);
      await tester.tap(find.byKey(const ValueKey('mini-tawang-null')));
      await settle(tester);
      final tawangCard = find.byKey(const ValueKey('mini-season-tawang'));
      expect(tawangCard, findsOneWidget);
      expect(
        find.descendant(
          of: tawangCard,
          matching: find.text('Tawang is best in winter'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tawangCard, matching: find.text('Best Nov–Feb')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('mini-ziro-null')));
      await settle(tester);
      expect(tawangCard, findsNothing);
      expect(
        find.text('Ziro is best in spring when the flowers bloom'),
        findsWidgets,
      );
    });

    testWidgets('empty area shows "Show nearest"', (tester) async {
      await pumpExplore(tester, repository: const _EmptyAreaRepository());
      await settle(tester);
      expect(find.text('No crafts or shops in this area yet'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('crafts-show-nearest')));
      await settle(tester);
      expect(
        find.byKey(const ValueKey('town-selected-itanagar')),
        findsOneWidget,
      );
    });

    testWidgets('emergency mode lists the help near the searched town', (
      tester,
    ) async {
      await pumpExplore(tester);
      await search(tester, 'tawang');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester);
      await tester.tap(find.text('Emergency mode'));
      await settle(tester);
      expect(find.text('Nearest help near Tawang'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('sos-Tawang District Hospital')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sos-TRIHMS Hospital, Naharlagun')),
        findsNothing,
      );
      // No shop pins in emergency mode.
      expect(
        find.byKey(const ValueKey('shop-pin-tawang-carpet@tawang')),
        findsNothing,
      );
    });
  });
}
