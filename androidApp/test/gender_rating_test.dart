import 'package:explore_arunachal/data/mock_data.dart';
import 'package:explore_arunachal/data/models.dart';
import 'package:explore_arunachal/screens/traveller/stays_screen.dart';
import 'package:explore_arunachal/widgets/gender_rating.dart';
import 'package:explore_arunachal/widgets/listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RatingBreakdown rb(double avg, int count, int women, int men) =>
    RatingBreakdown(
      average: avg,
      count: count,
      womenCount: women,
      menCount: men,
    );

void main() {
  group('RatingBreakdown percentages', () {
    test('are based on raters who stated a gender', () {
      // 120 reviews, 100 stated a gender: 48 women, 52 men.
      final r = rb(4.2, 120, 48, 52);
      expect(r.statedCount, 100);
      expect(r.womenShare, closeTo(0.48, 1e-9));
      expect(r.menShare, closeTo(0.52, 1e-9));
      expect(r.womenPercent, 48);
      expect(r.menPercent, 52);
    });

    test('rounded percentages always add up to 100', () {
      final r = rb(4.5, 3, 1, 2); // 33.3% / 66.7%
      expect(r.womenPercent, 33);
      expect(r.menPercent, 67);
      expect(r.womenPercent + r.menPercent, 100);
    });

    test('semantics label reads naturally', () {
      expect(
        rb(4.2, 120, 48, 52).semanticsLabel,
        'Rated 4.2 by 120 people, 48 percent women, 52 percent men',
      );
    });
  });

  group('zero counts', () {
    test('no ratings at all', () {
      final r = rb(0, 0, 0, 0);
      expect(r.hasGenderData, isFalse);
      expect(r.womenShare, 0);
      expect(r.menShare, 0);
      expect(r.womenPercent, 0);
      expect(r.menPercent, 0);
      expect(r.isWomenRecommended, isFalse);
      expect(r.semanticsLabel, 'No ratings yet');
    });

    test('ratings but nobody stated a gender', () {
      final r = rb(4.9, 12, 0, 0);
      expect(r.womenPercent, 0);
      expect(r.menPercent, 0);
      expect(r.isWomenRecommended, isFalse);
      expect(r.semanticsLabel, contains('gender not stated'));
    });

    testWidgets('widgets render with zero counts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GenderRatingSummary(ratings: rb(0, 0, 0, 0)),
                GenderRatingCompact(ratings: rb(0, 0, 0, 0)),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('No ratings yet'), findsOneWidget);
    });
  });

  group('Women recommended rule', () {
    test('threshold constants', () {
      expect(RatingBreakdown.womenRecommendedShare, 0.60);
      expect(RatingBreakdown.womenRecommendedMinAverage, 4.0);
    });

    test('needs >= 60% women and >= 4.0 average', () {
      expect(rb(4.0, 10, 6, 4).isWomenRecommended, isTrue); // exactly 60%
      expect(rb(4.8, 100, 68, 32).isWomenRecommended, isTrue);
      expect(rb(4.8, 100, 59, 41).isWomenRecommended, isFalse); // 59%
      expect(rb(3.9, 100, 80, 20).isWomenRecommended, isFalse); // low avg
      expect(rb(4.8, 100, 30, 70).isWomenRecommended, isFalse);
    });

    test('mock data has women-majority, balanced and men-majority items', () {
      final all = [
        ...MockData.stays.map((s) => s.ratings),
        ...MockData.guides.map((g) => g.ratings),
        ...MockData.hosts.map((h) => h.ratings),
        ...MockData.crafts.map((c) => c.ratings),
      ];
      expect(all.where((r) => r.womenPercent >= 60), isNotEmpty);
      expect(all.where((r) => (r.womenPercent - 50).abs() <= 3), isNotEmpty);
      expect(all.where((r) => r.womenPercent <= 40), isNotEmpty);
      for (final r in all) {
        expect(r.statedCount, lessThanOrEqualTo(r.count));
      }
    });
  });

  testWidgets('summary exposes a semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenderRatingSummary(ratings: rb(4.2, 120, 48, 52)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        'Rated 4.2 by 120 people, 48 percent women, 52 percent men',
      ),
      findsOneWidget,
    );
    expect(find.text('48% women'), findsOneWidget);
    expect(find.text('52% men'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Women recommended filter on the Stays / Guides screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StaysScreen())),
    );
    await tester.pumpAndSettle();

    final recommended = MockData.stays
        .where((s) => s.ratings.isWomenRecommended)
        .toList();
    final notRecommended = MockData.stays.firstWhere(
      (s) => !s.ratings.isWomenRecommended,
    );
    expect(find.text(notRecommended.name), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Women recommended'));
    await tester.pumpAndSettle();
    expect(find.text(notRecommended.name), findsNothing);
    expect(
      find.byType(ListingCard, skipOffstage: false),
      findsNWidgets(recommended.length),
    );

    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();
    final guides = MockData.guides
        .where((g) => g.ratings.isWomenRecommended)
        .length;
    expect(
      find.byType(ListingCard, skipOffstage: false),
      findsNWidgets(guides),
    );
  });
}
