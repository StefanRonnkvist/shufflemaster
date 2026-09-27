import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';

class GroupedCardDeck extends StatelessWidget {
  const GroupedCardDeck({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = standardFiftyTwoCardDeck();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final suit in STANDARD_SUITS)
          SuitCardGroup(
            suit: suit,
            cards: cards.where((card) => card.suit == suit).toList(),
          ),
      ],
    );
  }
}

class SuitCardGroup extends StatelessWidget {
  const SuitCardGroup({required this.suit, required this.cards, super.key});

  final Suit suit;
  final List<PlayingCard> cards;

  @override
  Widget build(BuildContext context) {
    const cardWidth = 110.0;
    const cardHeight = cardWidth / playingCardAspectRatio;
    const cardOffset = 38.0;
    final stackWidth = cardWidth + cardOffset * (cards.length - 1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              suitLabel(suit),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isHorizontal = stackWidth <= constraints.maxWidth;
              final stackHeight = isHorizontal
                  ? cardHeight
                  : cardHeight + cardOffset * (cards.length - 1);

              return Center(
                child: SizedBox(
                  width: isHorizontal ? stackWidth : cardWidth,
                  height: stackHeight,
                  child: Stack(
                    children: [
                      for (var index = 0; index < cards.length; index++)
                        Positioned(
                          left: isHorizontal ? cardOffset * index : 0,
                          top: isHorizontal ? 0 : cardOffset * index,
                          width: cardWidth,
                          height: cardHeight,
                          child: PlayingCardView(card: cards[index]),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

String suitLabel(Suit suit) {
  return switch (suit) {
    Suit.spades => 'Spades',
    Suit.hearts => 'Hearts',
    Suit.diamonds => 'Diamonds',
    Suit.clubs => 'Clubs',
    Suit.joker => 'Jokers',
  };
}
