import 'package:flutter_test/flutter_test.dart';
import 'package:shufflemaster/shared/deck/faro_shuffle.dart';

void main() {
  group('faroShuffle', () {
    test('interleaves an out-shuffle with the first half first', () {
      expect(faroShuffle([0, 1, 2, 3], isInShuffle: false), [0, 2, 1, 3]);
    });

    test('interleaves an in-shuffle with the second half first', () {
      expect(faroShuffle([0, 1, 2, 3], isInShuffle: true), [2, 0, 3, 1]);
    });

    test('rejects an odd number of cards', () {
      expect(
        () => faroShuffle([0, 1, 2], isInShuffle: false),
        throwsArgumentError,
      );
    });
  });

  group('repeatedFaroShuffle', () {
    test('returns an eight-card deck after three out-shuffles', () {
      final cards = List.generate(8, (index) => index);

      expect(repeatedFaroShuffle(cards, isInShuffle: false, count: 3), cards);
    });

    test('rejects a negative shuffle count', () {
      expect(
        () => repeatedFaroShuffle([0, 1, 2, 3], isInShuffle: false, count: -1),
        throwsArgumentError,
      );
    });
  });
}
