import 'dart:async';

import 'package:explore_arunachal/data/tribe_lens_service.dart';
import 'package:explore_arunachal/screens/traveller/know_locals_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

class _FakeClient implements TribeLensClient {
  _FakeClient(this.answer);
  final Completer<String> answer;

  @override
  Future<String> fetchResult(String url) => answer.future;

  @override
  Widget buildHost() => const SizedBox(width: 1, height: 1);
}

void main() {
  late Completer<String> answer;
  final photo = img.encodeJpg(img.Image(width: 40, height: 30));

  setUp(() {
    answer = Completer<String>();
    KnowLocalsScreen.debugPickImage = (_) async => photo;
    KnowLocalsScreen.debugTribeLens = TribeLensService(
      clientFactory: () => _FakeClient(answer),
    );
  });
  tearDown(() {
    KnowLocalsScreen.debugPickImage = null;
    KnowLocalsScreen.debugTribeLens = null;
  });

  Future<void> pickPhoto(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: KnowLocalsScreen())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('AI camera search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    // compute() runs the compression on a real isolate.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Lets the compression isolate and the fake answer finish, then lets
  /// the sheet close (its scan animation never settles while it is open).
  Future<void> finish(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Identifying tribe…').evaluate().isEmpty) break;
    }
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  bool chipSelected(WidgetTester tester, String name) => tester
      .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, name))
      .selected;

  testWidgets('camera search selects the tribe TribeLens returns', (
    tester,
  ) async {
    await pickPhoto(tester);
    expect(find.text('Identifying tribe…'), findsOneWidget);

    answer.complete('khampti');
    await finish(tester);

    expect(find.text('Identifying tribe…'), findsNothing);
    expect(find.text('Looks like Khamti attire'), findsOneWidget);
    expect(chipSelected(tester, 'Khamti'), isTrue);
  });

  testWidgets('unknown answer keeps the selection and says so', (
    tester,
  ) async {
    await pickPhoto(tester);
    answer.complete('Error: invalid image data');
    await finish(tester);

    expect(
      find.text("Couldn't recognise the tribe. Try another photo."),
      findsOneWidget,
    );
    expect(chipSelected(tester, 'Monpa'), isTrue);
  });
}
