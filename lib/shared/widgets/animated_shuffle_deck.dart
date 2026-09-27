import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';

class AnimatedShuffleDeck extends StatelessWidget {
  const AnimatedShuffleDeck({
    required this.cards,
    this.liftedCard,
    this.isCardLifted = false,
    super.key,
  });

  final List<PlayingCard> cards;
  final PlayingCard? liftedCard;
  final bool isCardLifted;

  @override
  Widget build(BuildContext context) {
    const cardWidth = 110.0;
    const cardHeight = cardWidth / playingCardAspectRatio;
    const cardOffset = 38.0;
    const rowGap = 12.0;
    final liftHeight = liftedCard == null ? 0.0 : 16.0;
    final cardsPerRow = cards.length ~/ 2;
    final stackWidth = cardWidth + cardOffset * (cardsPerRow - 1);
    final stackHeight = cardHeight * 2 + rowGap + liftHeight;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Center(
            child: SizedBox(
              width: stackWidth,
              height: stackHeight,
              child: Stack(
                children: [
                  for (var index = 0; index < cards.length; index++)
                    AnimatedPositioned(
                      key: ValueKey((cards[index].suit, cards[index].value)),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOutCubic,
                      left: cardOffset * (index % cardsPerRow),
                      top:
                          (cardHeight + rowGap) * (index ~/ cardsPerRow) +
                          (isCardLifted &&
                                  cards[index].suit == liftedCard?.suit &&
                                  cards[index].value == liftedCard?.value
                              ? 0
                              : liftHeight),
                      width: cardWidth,
                      height: cardHeight,
                      child: PlayingCardView(card: cards[index]),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
