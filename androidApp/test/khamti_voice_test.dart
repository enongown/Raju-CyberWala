import 'dart:io';

import 'package:explore_arunachal/data/mock_data.dart';
import 'package:explore_arunachal/screens/traveller/know_locals_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Khamti tribe has 6 voice phrases with bundled assets', () {
    final tribe = MockData.tribes.firstWhere((t) => t.name == 'Khamti');
    final lang = MockData.phraseLanguages.firstWhere(
      (l) => l.name == tribe.phraseLanguage,
    );
    final voice = lang.phrases.where((p) => p.hasAudio).toList();
    expect(voice, hasLength(6));
    expect(voice.map((p) => p.english), [
      'Hello',
      'Is the road open?',
      'Can I click a picture?',
      'Where is the homestay?',
      'How much is this?',
      'Can I have some water?',
    ]);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/audio/khamti/'));
    for (final p in voice) {
      expect(p.audioAsset, startsWith('assets/audio/khamti/'));
      final f = File(p.audioAsset!);
      expect(f.existsSync(), isTrue, reason: p.audioAsset);
      expect(f.lengthSync(), greaterThan(10000));
    }
  });

  testWidgets('Khamti shows the phrases with voice list', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: KnowLocalsScreen())),
    );
    await tester.pumpAndSettle();
    // Monpa (no recordings) has no voice section.
    expect(find.text('Phrases with voice'), findsNothing);
    expect(find.byType(VoicePlayButton), findsNothing);

    final chip = find.widgetWithText(ChoiceChip, 'Khamti');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.text('Phrases with voice'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Can I have some water?'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Listen in Khamti'), findsWidgets);
    expect(find.byType(VoicePlayButton), findsWidgets);
  });
}
