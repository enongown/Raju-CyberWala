import 'package:explore_arunachal/data/mock_data.dart';
import 'package:explore_arunachal/data/trip_calculator.dart';
import 'package:explore_arunachal/screens/traveller/know_locals_screen.dart';
import 'package:explore_arunachal/screens/traveller/stays_screen.dart';
import 'package:explore_arunachal/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('month ranges wrap around the year', () {
    expect(monthRanges([12, 1, 2, 7, 8]), 'Jul–Aug, Dec–Feb');
    expect(monthRanges([3, 4, 5, 9, 10]), 'Mar–May, Sep–Oct');
  });

  test('rupee formatting uses Indian grouping', () {
    expect(formatRupees(950), '₹950');
    expect(formatRupees(123456), '₹1,23,456');
  });

  test('trip estimate for the Tawang circuit is sensible', () {
    final est = TripCalculator.estimate(
      hub: MockData.hubById('tezpur'),
      places: ['bomdila', 'dirang', 'tawang'].map(MockData.placeById).toList(),
      travellers: 2,
      mode: TransportMode.taxi,
      comfort: Comfort.budget,
      foreigner: false,
    );
    expect(est.legs.length, 4);
    expect(est.totalKm, 155 + 42 + 140 + 320);
    expect(est.days, greaterThan(5));
    expect(est.totalHigh, greaterThan(est.totalLow));
  });

  test('stay totals include nights and the service fee', () {
    final s = MockData.stays.first;
    expect(s.totalFor(2), s.pricePerNight * 2 + s.serviceFee);
  });

  testWidgets('welcome screen shows Host and Traveller halves', (tester) async {
    await pumpScreen(tester, const WelcomeScreen());
    expect(find.text('Host'), findsOneWidget);
    expect(find.text('Traveller'), findsOneWidget);
    expect(find.text('Explore Arunachal'), findsOneWidget);
  });

  testWidgets('stays: total price toggle and guides segment', (tester) async {
    await pumpScreen(tester, const StaysScreen());
    final first = MockData.stays.first;
    expect(find.text(first.name), findsOneWidget);
    expect(find.text('Display total price'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.textContaining('total · 2 nights'), findsWidgets);

    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();
    final g = MockData.guides.first;
    expect(find.text('${g.name} (${g.tribe})'), findsOneWidget);
  });

  testWidgets('know the locals filters by tribe', (tester) async {
    await pumpScreen(tester, const KnowLocalsScreen());
    expect(find.text('Tashi Delek'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Adi'));
    await tester.pumpAndSettle();
    expect(find.text('Tashi Delek'), findsNothing);
    expect(find.text('Adi phrases'), findsOneWidget);
  });
}

// Widget tests for the redesigned traveller UI. They use a plain
// MaterialApp (no bundled-font theme) to stay fast and offline.

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.binding.setSurfaceSize(const Size(412, 915));
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: screen)));
  await tester.pumpAndSettle();
}
