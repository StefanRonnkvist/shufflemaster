import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';

import '../../shared/deck/faro_shuffle.dart';
import '../../shared/widgets/animated_shuffle_deck.dart';

class VerticalGroupedCardDeck extends StatefulWidget {
  const VerticalGroupedCardDeck({this.secondHalfFirst = false, super.key});

  final bool secondHalfFirst;

  @override
  State<VerticalGroupedCardDeck> createState() =>
      _VerticalGroupedCardDeckState();
}

class _VerticalGroupedCardDeckState extends State<VerticalGroupedCardDeck> {
  late List<PlayingCard> cards;
  int shuffleCount = 0;
  String? shuffleMessage;
  bool isAutoIncrementing = false;
  int autoIncrementRun = 0;

  @override
  void initState() {
    super.initState();
    cards = standardFiftyTwoCardDeck();
  }

  /// Applies one configured Faro shuffle and updates its cycle description.
  ///
  /// The counter returns to zero when the deck reaches its initial order.
  void shuffle() {
    final shuffledCards = faroShuffle(
      cards,
      isInShuffle: widget.secondHalfFirst,
    );

    setState(() {
      cards = shuffledCards;
      shuffleCount = _isInitialOrder(shuffledCards) ? 0 : shuffleCount + 1;
      shuffleMessage =
          widget.secondHalfFirst && shuffleCount >= 1 && shuffleCount <= 25
          ? 'The deck begins to separate. Noticeable clusters of original order are broken apart.'
          : widget.secondHalfFirst && shuffleCount == 26
          ? 'At the halfway point, the deck reaches a state of maximum apparent randomness. To a human observer, the deck appears thoroughly mixed.'
          : widget.secondHalfFirst && shuffleCount >= 27 && shuffleCount <= 50
          ? 'The mathematical symmetry begins to reverse the visual chaos. Cards rapidly realign into predictable intervals.'
          : widget.secondHalfFirst && shuffleCount == 51
          ? 'The inversion is complete. The deck instantly snaps back into its precise, original order.'
          : switch (shuffleCount) {
              0 => 'The inversion is complete. The deck instantly snaps back into its precise, original order.',
              >= 1 && <= 3 => 'The deck begins to separate. Noticeable clusters of original order are broken apart.',
              4 => 'At the halfway point, the deck reaches a state of maximum apparent randomness. To a human observer, the deck appears thoroughly mixed.',
              >= 5 && <= 7 => 'The mathematical symmetry begins to reverse the visual chaos. Cards rapidly realign into predictable intervals.',
              _ => 'Shuffles: $shuffleCount',
            };
    });
  }

  /// Starts or stops one-second automatic shuffles.
  ///
  /// Each run has an identifier so a stopped or superseded loop cannot resume
  /// after its pending delay. A run also stops when the deck completes a cycle.
  Future<void> toggleAutoIncrement() async {
    if (isAutoIncrementing) {
      setState(() {
        isAutoIncrementing = false;
        autoIncrementRun++;
      });
      return;
    }

    final currentRun = ++autoIncrementRun;
    setState(() => isAutoIncrementing = true);

    while (mounted && isAutoIncrementing && autoIncrementRun == currentRun) {
      shuffle();
      if (shuffleCount == 0) {
        setState(() => isAutoIncrementing = false);
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  /// Whether [shuffledCards] matches the standard deck by suit and value.
  bool _isInitialOrder(List<PlayingCard> shuffledCards) {
    final initialCards = standardFiftyTwoCardDeck();

    return List.generate(
      initialCards.length,
      (index) =>
          shuffledCards[index].suit == initialCards[index].suit &&
          shuffledCards[index].value == initialCards[index].value,
    ).every((matches) => matches);
  }

  /// Restores the standard deck and invalidates any automatic shuffle loop.
  void reset() {
    setState(() {
      isAutoIncrementing = false;
      autoIncrementRun++;
      cards = standardFiftyTwoCardDeck();
      shuffleCount = 0;
      shuffleMessage = null;
    });
  }

  @override
  void dispose() {
    autoIncrementRun++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                'Shuffles: $shuffleCount',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: isAutoIncrementing ? null : shuffle,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Shuffle'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: toggleAutoIncrement,
                    icon: Icon(
                      isAutoIncrementing ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(
                      isAutoIncrementing
                          ? 'Stop Auto Increment'
                          : 'Auto Increment',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: reset,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              AnimatedShuffleDeck(cards: cards),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: const Text(
                    'A faro shuffle is a precise card shuffle where you split '
                    'the deck into two equal halves (26–26) and then interweave '
                    'the cards perfectly, one from each half in alternating '
                    'order.\n\n'
                    'Key idea\n'
                    'The cards zip together in a perfect sequence — no '
                    'randomness.\n\n'
                    'Two variants:\n\n'
                    'Out‑shuffle: top and bottom cards stay in place. Eight '
                    'perfect out‑shuffles return a 52-card deck to its original '
                    'order.\n\n'
                    'In‑shuffle: top card moves to second position; full cycle '
                    'takes 52 shuffles.',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (shuffleMessage case final message?) ...[
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 640),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4CC),
                      border: Border.all(color: const Color(0xFFD49A00)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2A2108),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
