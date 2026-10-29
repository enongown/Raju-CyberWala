import 'package:explore_arunachal/data/mock_data.dart';
import 'package:explore_arunachal/data/poi_repository.dart';
import 'package:explore_arunachal/data/weather_repository.dart';
import 'package:explore_arunachal/screens/traveller/explore_screen.dart';
import 'package:explore_arunachal/widgets/explore_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _km = Distance();

double kmBetween(double aLat, double aLng, double bLat, double bLng) =>
    _km.as(LengthUnit.Meter, LatLng(aLat, aLng), LatLng(bLat, bLng)) / 1000;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Placeholder craft coordinates', () {
    test('are deterministic for the same id', () {
      final a = MockPoiRepository.placeholderOffset('x@ziro', 27.5, 93.8);
      final b = MockPoiRepository.placeholderOffset('x@ziro', 27.5, 93.8);
      expect(a, b);
      expect(
        MockPoiRepository.stableSeed('apatani-shawl@ziro'),
        MockPoiRepository.stableSeed('apatani-shawl@ziro'),
      );
      expect(MockPoiRepository.stableSeed('a'), 0xe40c292c); // FNV-1a("a")
      final c = MockPoiRepository.placeholderOffset('y@ziro', 27.5, 93.8);
      expect(c, isNot(a));
    });

    test('rebuilding the shops gives the same positions', () async {
      final first = await const MockPoiRepository().crafts();
      final again = [
        for (final s in first)
          MockPoiRepository.shopFor(
            s.craft,
            MockPoiRepository.townById(s.townId)!,
          ),
      ];
      for (final (i, s) in first.indexed) {
        expect(again[i].lat, s.lat);
        expect(again[i].lng, s.lng);
      }
    });

    test('every shop is 0.5–3 km from its town', () async {
      final shops = await const MockPoiRepository().crafts();
      expect(shops, isNotEmpty);
      for (final s in shops) {
        final town = MockPoiRepository.townById(s.townId)!;
        final d = kmBetween(town.lat, town.lng, s.lat, s.lng);
        expect(d, inInclusiveRange(0.49, 3.01), reason: s.id);
      }
      expect(shops.map((s) => s.id).toSet().length, shops.length);
      // Never straight north of the town (that is where its label sits).
      for (final s in shops) {
        final town = MockPoiRepository.townById(s.townId)!;
        final north = kmBetween(town.lat, town.lng, s.lat, town.lng);
        final total = kmBetween(town.lat, town.lng, s.lat, s.lng);
        if (s.lat > town.lat) {
          expect(north / total, lessThan(0.35), reason: s.id);
        }
      }
    });

    test('every craft has a shop, and town filtering works', () async {
      const repo = MockPoiRepository();
      final shops = await repo.crafts();
      for (final c in [...MockData.crafts, ...MockData.sampleShops]) {
        expect(shops.where((s) => s.craft.id == c.id), isNotEmpty);
      }
      final ziro = await repo.crafts(townId: 'ziro');
      expect(ziro, isNotEmpty);
      expect(ziro.every((s) => s.townId == 'ziro'), isTrue);
    });
  });

  test('every place has coordinates inside Arunachal Pradesh', () {
    for (final p in MockData.places) {
      expect(p.lat, inInclusiveRange(26.5, 29.5), reason: p.id);
      expect(p.lng, inInclusiveRange(91.5, 97.5), reason: p.id);
    }
  });

  group('Explore map', () {
    // Wide surface: the test font (Ahem) is much wider than Google Sans.
    Future<void> pumpExplore(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExploreScreen(weatherRepository: OfflineWeatherRepository()),
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
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    testWidgets('map keeps a 4:3 shape', (tester) async {
      await pumpExplore(tester);
      final size = tester.getSize(find.byType(ExploreMap));
      expect(size.width / size.height, closeTo(4 / 3, 0.01));
    });

    testWidgets('tapping a place focuses it on the map', (tester) async {
      await pumpExplore(tester);
      expect(find.byKey(const ValueKey('town-selected-ziro')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('mini-ziro-null')));
      await settle(tester);

      final label = find.byKey(const ValueKey('town-selected-ziro'));
      expect(label, findsOneWidget);
      final camera = MapCamera.of(tester.element(label));
      final ziro = MockData.placeById('ziro');
      expect(
        kmBetween(
          camera.center.latitude,
          camera.center.longitude,
          ziro.lat,
          ziro.lng,
        ),
        lessThan(5),
      );
      // Ziro's craft shops are pinned and listed (the list follows the
      // map area).
      final ziroShops = await const MockPoiRepository().crafts(townId: 'ziro');
      for (final s in ziroShops) {
        expect(find.byKey(ValueKey('shop-pin-${s.id}')), findsOneWidget);
        expect(find.byKey(ValueKey('shop-tile-${s.id}')), findsOneWidget);
      }
      expect(find.text('in Ziro'), findsNWidgets(ziroShops.length));
      expect(find.text('View details'), findsOneWidget);
    });

    testWidgets('tapping a guide focuses their base town', (tester) async {
      await pumpExplore(tester);
      final g = MockData.guides.first;
      await tester.tap(find.byKey(ValueKey('mini-${g.placeId}-${g.id}')));
      await settle(tester);
      expect(
        find.byKey(ValueKey('town-selected-${g.placeId}')),
        findsOneWidget,
      );
      expect(find.text('View guide'), findsOneWidget);
    });

    testWidgets('tapping a craft tile focuses its shop pin', (tester) async {
      await pumpExplore(tester);
      await tester.tap(find.byKey(const ValueKey('mini-ziro-null')));
      await settle(tester);
      final tile = find.byKey(const ValueKey('shop-tile-apatani-shawl@ziro'));
      await tester.ensureVisible(tile);
      await tester.pump();
      await tester.tap(tile);
      await settle(tester);
      expect(
        find.byKey(const ValueKey('shop-selected-apatani-shawl@ziro')),
        findsOneWidget,
      );
    });

    testWidgets('fullscreen opens and exits', (tester) async {
      await pumpExplore(tester);
      await tester.tap(find.byKey(const ValueKey('mini-ziro-null')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('map-fullscreen')));
      await settle(tester);
      expect(find.byType(ExploreMapFullscreen), findsOneWidget);
      // Selection carries over.
      expect(find.byKey(const ValueKey('town-selected-ziro')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('map-exit-fullscreen')));
      await settle(tester);
      expect(find.byType(ExploreMapFullscreen), findsNothing);
      expect(find.byKey(const ValueKey('map-fullscreen')), findsOneWidget);
      // The crafts list reflects the camera after returning.
      expect(find.text('Local crafts & shops near Ziro'), findsOneWidget);
    });
  });
}
