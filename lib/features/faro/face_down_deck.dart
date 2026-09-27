import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playing_cards/playing_cards.dart';

import '../../shared/cards/card_back.dart';
import '../../shared/deck/faro_shuffle.dart';
import '../../shared/widgets/binary_shuffle_selectors.dart';

enum _FaroMode { out, inShuffle, binary }

class FaceDownDeck extends StatefulWidget {
  const FaceDownDeck({
    required this.cardBack,
    required this.patternIndex,
    super.key,
  });

  final CardBackDesign cardBack;
  final int patternIndex;

  @override
  State<FaceDownDeck> createState() => _FaceDownDeckState();
}

class _FaceDownDeckState extends State<FaceDownDeck> {
  final faceUpCards = <int>{};
  final shuffleCountController = TextEditingController(text: '1');
  _FaroMode faroMode = _FaroMode.out;
  int shuffleCount = 1;
  int binaryValue = 1;

  @override
  void dispose() {
    shuffleCountController.dispose();
    super.dispose();
  }

  /// Changes the shuffle mode and clears all revealed cards.
  ///
  /// Numeric counts are clamped to the selected Faro cycle: 1-8 for an
  /// out-shuffle and 1-52 for an in-shuffle.
  void setFaroMode(_FaroMode value) {
    final enteredCount = int.tryParse(shuffleCountController.text) ?? 1;
    final maximum = value == _FaroMode.inShuffle ? 52 : 8;

    setState(() {
      faroMode = value;
      if (value != _FaroMode.binary) {
        shuffleCount = enteredCount.clamp(1, maximum);
        shuffleCountController.text = '$shuffleCount';
      }
      faceUpCards.clear();
    });
  }

  /// Accepts an in-range Faro count and clears cards revealed for the old deck.
  void updateShuffleCount(String value) {
    final parsedValue = int.tryParse(value);
    final maximum = faroMode == _FaroMode.inShuffle ? 52 : 8;

    if (parsedValue != null && parsedValue >= 1 && parsedValue <= maximum) {
      setState(() {
        shuffleCount = parsedValue;
        faceUpCards.clear();
      });
    }
  }

  /// Builds a fresh standard deck in the order selected by the controls.
  ///
  /// Faro modes repeat one shuffle type. Binary mode treats each selected bit
  /// as an in-shuffle and each unselected processed place as an out-shuffle.
  List<PlayingCard> shuffledCards() {
    if (faroMode != _FaroMode.binary) {
      return repeatedFaroShuffle(
        standardFiftyTwoCardDeck(),
        isInShuffle: faroMode == _FaroMode.inShuffle,
        count: shuffleCount,
      );
    }

    var cards = standardFiftyTwoCardDeck();
    for (final placeValue in binaryShufflePlaceValues) {
      if (placeValue <= binaryValue) {
        cards = faroShuffle(cards, isInShuffle: binaryValue & placeValue != 0);
      }
    }
    return cards;
  }

  /// Toggles whether the card at [index] is shown face up.
  void toggleCard(int index) {
    setState(() {
      if (!faceUpCards.remove(index)) {
        faceUpCards.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const cardWidth = 110.0;
    const cardHeight = cardWidth / playingCardAspectRatio;
    final cards = shuffledCards();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 24;
        final cardOffset = (availableWidth - cardWidth) / (cards.length - 1);
        final cardOrder = [
          for (var index = 0; index < cards.length; index++)
            if (!faceUpCards.contains(index)) index,
          for (var index = 0; index < cards.length; index++)
            if (faceUpCards.contains(index)) index,
        ];

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Faro Shuffle',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    Semantics(
                      label: 'Faro Shuffle',
                      value: switch (faroMode) {
                        _FaroMode.out => 'Out',
                        _FaroMode.inShuffle => 'In',
                        _FaroMode.binary => 'Binary',
                      },
                      child: RadioGroup<_FaroMode>(
                        groupValue: faroMode,
                        onChanged: (value) {
                          if (value != null) setFaroMode(value);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => setFaroMode(_FaroMode.out),
                              borderRadius: BorderRadius.circular(4),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<_FaroMode>(value: _FaroMode.out),
                                  Text('Out'),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => setFaroMode(_FaroMode.inShuffle),
                              borderRadius: BorderRadius.circular(4),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<_FaroMode>(value: _FaroMode.inShuffle),
                                  Text('In'),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => setFaroMode(_FaroMode.binary),
                              borderRadius: BorderRadius.circular(4),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<_FaroMode>(value: _FaroMode.binary),
                                  Text('Binary'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (faroMode == _FaroMode.binary)
                      SizedBox(
                        width: math.min(availableWidth, 444),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: BinaryShuffleSelectors(
                            value: binaryValue,
                            onChanged: (value) {
                              setState(() {
                                binaryValue = value;
                                faceUpCards.clear();
                              });
                            },
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: 88,
                        child: TextFormField(
                          controller: shuffleCountController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Count',
                            helperText: faroMode == _FaroMode.inShuffle
                                ? '1-52'
                                : '1-8',
                            filled: true,
                            fillColor: Colors.white,
                            labelStyle: const TextStyle(
                              color: Color(0xFF333333),
                            ),
                            helperStyle: const TextStyle(color: Colors.white70),
                            border: const OutlineInputBorder(),
                          ),
                          style: const TextStyle(color: Color(0xFF222222)),
                          validator: (value) {
                            final parsedValue = int.tryParse(value ?? '');
                            final maximum = faroMode == _FaroMode.inShuffle
                                ? 52
                                : 8;
                            if (parsedValue == null ||
                                parsedValue < 1 ||
                                parsedValue > maximum) {
                              return 'Use 1-$maximum';
                            }
                            return null;
                          },
                          onChanged: updateShuffleCount,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.cardBack.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: availableWidth,
                  height: cardHeight + 20,
                  child: Stack(
                    children: [
                      for (final index in cardOrder)
                        Positioned(
                          left: cardOffset * index,
                          top: faceUpCards.contains(index) ? 0 : 20,
                          width: cardWidth,
                          height: cardHeight,
                          child: _FlippableCard(
                            cardNumber: index + 1,
                            card: cards[index],
                            color: widget.cardBack.color,
                            accent: widget.cardBack.accent,
                            patternIndex: widget.patternIndex,
                            isFaceUp: faceUpCards.contains(index),
                            onTap: () => toggleCard(index),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Choose whether you want to perform an ',
                        ),
                        TextSpan(
                          text: 'in‑faro',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' or '),
                        TextSpan(
                          text: 'out‑faro',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ', or select a '),
                        TextSpan(
                          text: 'binary sequence',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              ' shuffle.\n'
                              'After selecting the type, set the count or binary In/Out sequence you will apply.\n'
                              'Pick any card in the deck and track its position through each shuffle.\n'
                              'Once you finish the chosen number of shuffles, determine whether the card ends up in the predicted location.\n'
                              'Use this process to test and strengthen your memory of faro shuffle permutations.',
                        ),
                      ],
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FlippableCard extends StatelessWidget {
  const _FlippableCard({
    required this.cardNumber,
    required this.card,
    required this.color,
    required this.accent,
    required this.patternIndex,
    required this.isFaceUp,
    required this.onTap,
  });

  final int cardNumber;
  final PlayingCard card;
  final Color color;
  final Color accent;
  final int patternIndex;
  final bool isFaceUp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isFaceUp,
      label: 'Card $cardNumber, ${isFaceUp ? 'face up' : 'face down'}',
      child: Tooltip(
        message: 'Position $cardNumber of 52',
        waitDuration: const Duration(milliseconds: 200),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: isFaceUp ? math.pi : 0),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOutCubic,
              builder: (context, angle, child) {
                final showFace = angle >= math.pi / 2;
                final visibleAngle = showFace ? angle - math.pi : angle;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateY(visibleAngle),
                  child: showFace
                      ? PlayingCardView(card: card)
                      : _CardBack(
                          color: color,
                          accent: accent,
                          patternIndex: patternIndex,
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({
    required this.color,
    required this.accent,
    required this.patternIndex,
  });

  final Color color;
  final Color accent;
  final int patternIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCECECE)),
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 3,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: CustomPaint(
          painter: CardBackPainter(
            color: color,
            accent: accent,
            patternIndex: patternIndex,
          ),
        ),
      ),
    );
  }
}
