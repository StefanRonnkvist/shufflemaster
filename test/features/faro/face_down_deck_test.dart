import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shufflemaster/features/faro/face_down_deck.dart';
import 'package:shufflemaster/shared/cards/card_back.dart';

void main() {
  testWidgets('binary mode replaces count field with binary selectors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FaceDownDeck(cardBack: cardBackDesigns.first, patternIndex: 0),
        ),
      ),
    );

    expect(find.byType(TextFormField), findsOneWidget);

    await tester.tap(find.text('Binary'));
    await tester.pump();

    expect(find.byType(TextFormField), findsNothing);
    expect(
      find.byKey(const ValueKey('binary-shuffle-selector-32')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('binary-shuffle-selector-32')));
    await tester.pump();

    final selector = tester.widget<Semantics>(
      find.byKey(const ValueKey('binary-shuffle-selector-32')),
    );
    expect(selector.properties.selected, isTrue);
    expect(tester.takeException(), isNull);
  });
}
