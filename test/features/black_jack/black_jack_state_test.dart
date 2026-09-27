import 'package:flutter_test/flutter_test.dart';
import 'package:shufflemaster/features/black_jack/black_jack_state.dart';

void main() {
  test('round-trips a complete game snapshot', () {
    final state = BlackJackState(
      selectedMode: 'Binary',
      shuffleValues: const {'In': '3', 'Out': '2', 'Binary': '37'},
      deckCardIndexes: List.generate(52, (index) => 51 - index),
      dealerCardIndexes: const [5, 11, 18],
      playerCardIndexes: const {
        1: [0, 6, 12],
        2: [1, 7],
      },
      playerActions: const {1: 'Stay', 2: 'Hit'},
      nextCardIndex: 19,
      activePlayer: 2,
      dealerTurnComplete: false,
    );

    final restored = BlackJackState.decode(state.encode());

    expect(restored.selectedMode, state.selectedMode);
    expect(restored.shuffleValues, state.shuffleValues);
    expect(restored.deckCardIndexes, state.deckCardIndexes);
    expect(restored.dealerCardIndexes, state.dealerCardIndexes);
    expect(restored.playerCardIndexes, state.playerCardIndexes);
    expect(restored.playerActions, state.playerActions);
    expect(restored.nextCardIndex, state.nextCardIndex);
    expect(restored.activePlayer, state.activePlayer);
    expect(restored.dealerTurnComplete, state.dealerTurnComplete);
  });

  test('rejects an unsupported snapshot version', () {
    expect(
      () => BlackJackState.decode('{"version":99}'),
      throwsFormatException,
    );
  });

  test('rejects a deck with duplicate card indexes', () {
    final state = BlackJackState(
      selectedMode: 'In',
      shuffleValues: const {'In': '1', 'Out': '1', 'Binary': '1'},
      deckCardIndexes: List.filled(52, 0),
      dealerCardIndexes: const [],
      playerCardIndexes: const {},
      playerActions: const {},
      nextCardIndex: 0,
      activePlayer: null,
      dealerTurnComplete: false,
    );

    expect(() => BlackJackState.decode(state.encode()), throwsFormatException);
  });

  test('rejects shuffle values outside the supported range', () {
    const state = BlackJackState(
      selectedMode: 'Out',
      shuffleValues: {'In': '1', 'Out': '9', 'Binary': '1'},
      deckCardIndexes: null,
      dealerCardIndexes: [],
      playerCardIndexes: {},
      playerActions: {},
      nextCardIndex: 0,
      activePlayer: null,
      dealerTurnComplete: false,
    );

    expect(() => BlackJackState.decode(state.encode()), throwsFormatException);
  });

  test('rejects an active player without a saved hand', () {
    final state = BlackJackState(
      selectedMode: 'In',
      shuffleValues: const {'In': '1', 'Out': '1', 'Binary': '1'},
      deckCardIndexes: List.generate(52, (index) => index),
      dealerCardIndexes: const [5, 11],
      playerCardIndexes: const {},
      playerActions: const {},
      nextCardIndex: 12,
      activePlayer: 1,
      dealerTurnComplete: false,
    );

    expect(() => BlackJackState.decode(state.encode()), throwsFormatException);
  });
}
