/// Returns a new list containing one perfect Faro shuffle of [cards].
///
/// An in-shuffle starts each interleaved pair with a card from the second
/// half. An out-shuffle starts with the first half, preserving the original
/// top and bottom cards. The input list is not modified.
///
/// Throws an [ArgumentError] when [cards] contains an odd number of items.
List<T> faroShuffle<T>(List<T> cards, {required bool isInShuffle}) {
  if (cards.length.isOdd) {
    throw ArgumentError.value(
      cards.length,
      'cards.length',
      'A Faro shuffle requires an even number of cards.',
    );
  }

  final midpoint = cards.length ~/ 2;
  final firstHalf = cards.sublist(0, midpoint);
  final secondHalf = cards.sublist(midpoint);

  return [
    for (var index = 0; index < midpoint; index++) ...[
      if (isInShuffle) secondHalf[index] else firstHalf[index],
      if (isInShuffle) firstHalf[index] else secondHalf[index],
    ],
  ];
}

/// Applies the selected Faro shuffle to [cards] exactly [count] times.
///
/// A count of zero returns a copy in the original order. The input list is
/// never modified. Throws an [ArgumentError] when [count] is negative or when
/// a shuffle is requested for an odd-length list.
List<T> repeatedFaroShuffle<T>(
  List<T> cards, {
  required bool isInShuffle,
  required int count,
}) {
  if (count < 0) {
    throw ArgumentError.value(count, 'count', 'Count cannot be negative.');
  }

  var shuffledCards = List<T>.of(cards);
  for (var shuffle = 0; shuffle < count; shuffle++) {
    shuffledCards = faroShuffle(shuffledCards, isInShuffle: isInShuffle);
  }
  return shuffledCards;
}
