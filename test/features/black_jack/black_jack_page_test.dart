import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shufflemaster/features/black_jack/black_jack_page.dart';
import 'package:shufflemaster/features/black_jack/black_jack_state.dart';
import 'package:shufflemaster/shared/cards/card_back.dart';

void main() {
  Widget buildPage(BlackJackStateStore stateStore) {
    return MaterialApp(
      home: Scaffold(
        body: BlackJackPage(
          cardBack: cardBackDesigns.first,
          patternIndex: 0,
          stateStore: stateStore,
        ),
      ),
    );
  }

  testWidgets('restores shuffle controls, played cards, and scores', (
    tester,
  ) async {
    final savedState = BlackJackState(
      selectedMode: 'Binary',
      shuffleValues: const {'In': '3', 'Out': '2', 'Binary': '37'},
      deckCardIndexes: List.generate(52, (index) => index),
      dealerCardIndexes: const [5, 11],
      playerCardIndexes: const {
        1: [0, 6],
        2: [1, 7],
        3: [2, 8],
        4: [3, 9],
        5: [4, 10],
      },
      playerActions: const {1: 'Stay'},
      nextCardIndex: 12,
      activePlayer: 2,
      dealerTurnComplete: false,
    );
    final stateStore = _MemoryBlackJackStateStore(savedState.encode());

    await tester.pumpWidget(buildPage(stateStore));
    await tester.pumpAndSettle();

    final valueField = tester.widget<TextField>(find.byType(TextField));
    expect(valueField.controller!.text, '37');
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('TOTAL'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('persists shuffle settings and dealt cards', (tester) async {
    final stateStore = _MemoryBlackJackStateStore();

    await tester.pumpWidget(buildPage(stateStore));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Out'));
    await tester.enterText(find.byType(TextField), '2');
    await tester.tap(find.text('Deal'));
    await tester.pumpAndSettle();

    final encoded = await stateStore.read();
    final savedState = BlackJackState.decode(encoded!);
    expect(savedState.selectedMode, 'Out');
    expect(savedState.shuffleValues['Out'], '2');
    expect(savedState.deckCardIndexes, hasLength(52));
    expect(savedState.playerCardIndexes, hasLength(5));
    expect(savedState.nextCardIndex, 12);
    expect(savedState.activePlayer, isNotNull);
  });

  testWidgets('remains usable when persisted state cannot be read', (
    tester,
  ) async {
    final stateStore = _MemoryBlackJackStateStore()..failReads = true;

    await tester.pumpWidget(buildPage(stateStore));
    await tester.pumpAndSettle();

    expect(find.text('Deal'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

class _MemoryBlackJackStateStore implements BlackJackStateStore {
  _MemoryBlackJackStateStore([this.value]);

  String? value;
  bool failReads = false;

  @override
  Future<String?> read() async {
    if (failReads) {
      throw Exception('Storage unavailable');
    }
    return value;
  }

  @override
  Future<void> remove() async => value = null;

  @override
  Future<void> write(String value) async => this.value = value;
}
