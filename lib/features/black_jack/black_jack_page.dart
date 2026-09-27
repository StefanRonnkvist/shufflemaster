import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playing_cards/playing_cards.dart';

import '../../shared/cards/card_back.dart';
import '../../shared/deck/faro_shuffle.dart';
import 'black_jack_state.dart';

class BlackJackPage extends StatefulWidget {
  const BlackJackPage({
    required this.cardBack,
    required this.patternIndex,
    this.stateStore,
    super.key,
  });

  final CardBackDesign cardBack;
  final int patternIndex;
  final BlackJackStateStore? stateStore;

  @override
  State<BlackJackPage> createState() => _BlackJackPageState();
}

class _BlackJackPageState extends State<BlackJackPage> {
  static const _selectorHeight = 40.0;
  static const _hitDebounce = Duration(milliseconds: 300);

  static const _spacing = 12.0;
  static const maximumValues = {'In': 52, 'Out': 8, 'Binary': 51};

  final _standardDeck = standardFiftyTwoCardDeck();
  late final BlackJackStateStore _stateStore;
  Future<void> _pendingSave = Future.value();
  String selectedMode = 'In';
  final valueControllers = {
    'In': TextEditingController(text: '1'),
    'Out': TextEditingController(text: '1'),
    'Binary': TextEditingController(text: '1'),
  };
  List<PlayingCard>? dealtCards;
  final dealerHand = <PlayingCard>[];
  final playerHands = <int, List<PlayingCard>>{};
  final playerActions = <int, String>{};
  final lastHitTimes = <int, DateTime>{};
  int nextCardIndex = 12;
  int? activePlayer;
  bool dealerTurnComplete = false;
  bool isRestoring = true;

  @override
  void initState() {
    super.initState();
    _stateStore = widget.stateStore ?? SharedPreferencesBlackJackStateStore();
    _restoreState();
  }

  /// Restores a valid snapshot, or leaves a fresh game when none is available.
  ///
  /// Invalid snapshots are removed. Storage failures are intentionally ignored
  /// so they do not prevent the game from becoming usable.
  Future<void> _restoreState() async {
    BlackJackState? savedState;
    try {
      final encoded = await _stateStore.read();
      if (encoded != null) {
        savedState = BlackJackState.decode(encoded);
      }
    } on FormatException {
      await _removeInvalidState();
    } on Exception {
      // Start a new game when storage is temporarily unavailable.
    }

    if (!mounted) {
      return;
    }

    final state = savedState;
    setState(() {
      if (state != null) {
        selectedMode = state.selectedMode;
        for (final entry in state.shuffleValues.entries) {
          valueControllers[entry.key]!.text = entry.value;
        }
        dealtCards = state.deckCardIndexes
            ?.map((index) => _standardDeck[index])
            .toList();
        dealerHand
          ..clear()
          ..addAll(
            state.dealerCardIndexes.map((index) => _standardDeck[index]),
          );
        playerHands
          ..clear()
          ..addEntries(
            state.playerCardIndexes.entries.map(
              (entry) => MapEntry(
                entry.key,
                entry.value.map((index) => _standardDeck[index]).toList(),
              ),
            ),
          );
        playerActions
          ..clear()
          ..addAll(state.playerActions);
        nextCardIndex = state.nextCardIndex;
        activePlayer = state.activePlayer;
        dealerTurnComplete = state.dealerTurnComplete;
      }
      isRestoring = false;
    });
  }

  /// Removes a corrupt snapshot without surfacing storage errors to the game.
  Future<void> _removeInvalidState() async {
    try {
      await _stateStore.remove();
    } on Exception {
      // A storage failure should not prevent starting a new game.
    }
  }

  /// Queues a snapshot after earlier writes to preserve mutation order.
  ///
  /// Saves are skipped during restoration and while any shuffle value is
  /// invalid.
  void _schedulePersistence() {
    if (isRestoring || !_hasValidShuffleValues) {
      return;
    }

    final encoded = _createSavedState().encode();
    _pendingSave = _pendingSave.then((_) => _saveState(encoded));
  }

  /// Whether every mode has a numeric shuffle value in its supported range.
  bool get _hasValidShuffleValues => valueControllers.entries.every((entry) {
    final value = int.tryParse(entry.value.text);
    return value != null && value >= 1 && value <= maximumValues[entry.key]!;
  });

  /// Writes [encoded], allowing play to continue if storage is unavailable.
  Future<void> _saveState(String encoded) async {
    try {
      await _stateStore.write(encoded);
    } on Exception {
      // Keep the game usable when persistence is temporarily unavailable.
    }
  }

  /// Captures the current controls, deck, hands, actions, and turn progress.
  BlackJackState _createSavedState() {
    return BlackJackState(
      selectedMode: selectedMode,
      shuffleValues: valueControllers.map(
        (mode, controller) => MapEntry(mode, controller.text),
      ),
      deckCardIndexes: dealtCards?.map(_cardIndex).toList(),
      dealerCardIndexes: dealerHand.map(_cardIndex).toList(),
      playerCardIndexes: playerHands.map(
        (player, cards) => MapEntry(player, cards.map(_cardIndex).toList()),
      ),
      playerActions: Map.of(playerActions),
      nextCardIndex: nextCardIndex,
      activePlayer: activePlayer,
      dealerTurnComplete: dealerTurnComplete,
    );
  }

  /// Maps [card] to its stable zero-based position in the standard deck.
  int _cardIndex(PlayingCard card) {
    return _standardDeck.indexWhere(
      (candidate) =>
          candidate.suit == card.suit && candidate.value == card.value,
    );
  }

  /// Deals the next round-robin batch of two cards to five players and dealer.
  ///
  /// The configured deck is created lazily. The method does nothing when fewer
  /// than twelve cards remain and advances past players dealt an initial 21.
  void deal() {
    FocusScope.of(context).unfocus();
    setState(() {
      var cards = dealtCards;
      if (cards == null) {
        cards = _orderedDeck();
        dealtCards = cards;
        nextCardIndex = 0;
      }

      if (cards.length - nextCardIndex < 12) {
        return;
      }

      final firstCardIndex = nextCardIndex;
      dealerHand
        ..clear()
        ..addAll([cards[firstCardIndex + 5], cards[firstCardIndex + 11]]);
      playerHands
        ..clear()
        ..addEntries(
          List.generate(
            5,
            (index) => MapEntry(index + 1, [
              cards![firstCardIndex + index],
              cards[firstCardIndex + index + 6],
            ]),
          ),
        );
      playerActions.clear();
      lastHitTimes.clear();
      nextCardIndex = firstCardIndex + 12;
      activePlayer = 1;
      dealerTurnComplete = false;
      _advancePastPlayersWith21();
      _playDealerIfReady();
    });
    _schedulePersistence();
  }

  /// Rebuilds the configured deck and clears all current round progress.
  void shuffle() {
    FocusScope.of(context).unfocus();
    setState(() {
      dealtCards = _orderedDeck();
      dealerHand.clear();
      playerHands.clear();
      playerActions.clear();
      lastHitTimes.clear();
      nextCardIndex = 0;
      activePlayer = null;
      dealerTurnComplete = false;
    });
    _schedulePersistence();
  }

  /// Returns a standard deck after applying the selected shuffle sequence.
  ///
  /// In and Out modes repeat one Faro variant. Binary mode processes the six
  /// place values from 32 to 1, using set bits for in-shuffles and clear bits
  /// within the selected range for out-shuffles.
  List<PlayingCard> _orderedDeck() {
    var cards = standardFiftyTwoCardDeck();
    final value = int.tryParse(valueControllers[selectedMode]!.text) ?? 1;

    if (selectedMode == 'Binary') {
      for (final placeValue in const [32, 16, 8, 4, 2, 1]) {
        if (placeValue <= value) {
          cards = faroShuffle(cards, isInShuffle: value & placeValue != 0);
        }
      }
    } else {
      for (var shuffle = 0; shuffle < value; shuffle++) {
        cards = faroShuffle(cards, isInShuffle: selectedMode == 'In');
      }
    }

    return cards;
  }

  /// Applies [action] only when [player] currently owns the turn.
  void selectPlayerAction(int player, String action) {
    if (player != activePlayer) {
      return;
    }

    if (action == 'Hit') {
      hit(player);
      return;
    }

    setState(() {
      playerActions[player] = action;
      _advanceTurn(player);
    });
    _schedulePersistence();
  }

  /// Deals one card to the active player, with rapid duplicate taps ignored.
  ///
  /// A bust or total of 21 completes the player's turn automatically.
  void hit(int player) {
    final cards = dealtCards;
    if (player != activePlayer ||
        cards == null ||
        nextCardIndex >= cards.length) {
      return;
    }

    final now = DateTime.now();
    final lastHit = lastHitTimes[player];
    if (lastHit != null && now.difference(lastHit) < _hitDebounce) {
      return;
    }

    setState(() {
      lastHitTimes[player] = now;
      final hand = playerHands[player]!;
      hand.add(cards[nextCardIndex++]);
      final isBust = _handTotal(hand).hard > 21;
      final turnComplete = isBust || _bestTotal(hand) == 21;
      playerActions[player] = turnComplete ? 'Stay' : 'Hit';
      if (turnComplete) {
        _advanceTurn(player);
      }
    });
    _schedulePersistence();
  }

  /// Advances to the next player, then starts dealer play when all are done.
  void _advanceTurn(int player) {
    activePlayer = player < 5 ? player + 1 : null;
    _advancePastPlayersWith21();
    _playDealerIfReady();
  }

  /// Marks consecutive players with 21 as stayed without requiring input.
  void _advancePastPlayersWith21() {
    while (activePlayer != null &&
        _bestTotal(playerHands[activePlayer]!) == 21) {
      playerActions[activePlayer!] = 'Stay';
      activePlayer = activePlayer! < 5 ? activePlayer! + 1 : null;
    }
  }

  /// Completes the dealer hand after every player has stayed.
  ///
  /// The dealer draws while the best total is 17 or less, unless every player
  /// is bust, then warns when fewer than twelve cards remain for another round.
  void _playDealerIfReady() {
    final cards = dealtCards;
    if (cards == null || dealerTurnComplete || !_allPlayersStayed) {
      return;
    }

    if (!_allPlayersBust) {
      while (nextCardIndex < cards.length && _bestTotal(dealerHand) <= 17) {
        dealerHand.add(cards[nextCardIndex++]);
      }
    }
    dealerTurnComplete = true;
    if (!_hasCardsForRound) {
      _showDeckEmptyDialog();
    }
  }

  bool get _hasCardsForRound =>
      dealtCards == null || dealtCards!.length - nextCardIndex >= 12;

  void _showDeckEmptyDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          content: const Text(
            'Deck does not have any more cards\n\nPlease Shuffle Deck',
            style: TextStyle(color: Color(0xFF222222)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8F1D24),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  bool get _allPlayersStayed =>
      playerActions.length == 5 &&
      playerActions.values.every((action) => action == 'Stay');

  bool get _allPlayersBust =>
      playerHands.length == 5 &&
      playerHands.values.every((hand) => _handTotal(hand).hard > 21);

  @override
  void dispose() {
    for (final controller in valueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isRestoring) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnCount = switch (constraints.maxWidth) {
            >= 900 => 5,
            >= 560 => 3,
            _ => 2,
          };
          final rowCount = (5 / columnCount).ceil();
          final availableTableHeight =
              constraints.maxHeight - _selectorHeight - _spacing;
          final dealerHeight = math.min(150.0, availableTableHeight * 0.28);
          final playerHeight =
              (availableTableHeight - dealerHeight - _spacing * rowCount) /
              rowCount;
          final playerWidth =
              (constraints.maxWidth - 24 - _spacing * (columnCount - 1)) /
              columnCount;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SizedBox(
                  height: _selectorHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'In', label: Text('In')),
                            ButtonSegment(value: 'Out', label: Text('Out')),
                            ButtonSegment(
                              value: 'Binary',
                              label: Text('Binary'),
                            ),
                          ],
                          selected: {selectedMode},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) {
                            setState(() => selectedMode = selection.first);
                            _schedulePersistence();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 128,
                        child: TextField(
                          controller: valueControllers[selectedMode],
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _RangeTextInputFormatter(
                              maximum: maximumValues[selectedMode]!,
                            ),
                          ],
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText:
                                '$selectedMode 1-${maximumValues[selectedMode]}',
                            labelStyle: const TextStyle(color: Colors.white70),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          onChanged: (_) => _schedulePersistence(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed:
                            dealtCards == null ||
                                ((dealerTurnComplete || activePlayer == null) &&
                                    _hasCardsForRound)
                            ? deal
                            : null,
                        child: Text(dealtCards == null ? 'Deal' : 'Continue'),
                      ),
                      if (dealtCards != null) ...[
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: shuffle,
                          child: const Text('Shuffle'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: _spacing),
                SizedBox(
                  height: dealerHeight,
                  child: _DealerSpot(
                    cards: dealerHand,
                    revealHand: dealerTurnComplete,
                    cardBack: widget.cardBack,
                    patternIndex: widget.patternIndex,
                  ),
                ),
                const SizedBox(height: _spacing),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: _spacing,
                      runSpacing: _spacing,
                      children: [
                        for (var player = 1; player <= 5; player++)
                          SizedBox(
                            width: playerWidth,
                            height: playerHeight,
                            child: _PlayerSpot(
                              playerNumber: player,
                              cards:
                                  playerHands[player] ?? const <PlayingCard>[],
                              selectedAction: playerActions[player],
                              isActive: activePlayer == player,
                              dealerTotal: dealerTurnComplete
                                  ? _bestTotal(dealerHand)
                                  : null,
                              onActionSelected: (action) =>
                                  selectPlayerAction(player, action),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Returns the hard total and, when an ace exists, the total with one ace high.
({int hard, int? soft}) _handTotal(List<PlayingCard> cards) {
  var hard = 0;
  var hasAce = false;

  for (final card in cards) {
    hard += switch (card.value) {
      CardValue.two => 2,
      CardValue.three => 3,
      CardValue.four => 4,
      CardValue.five => 5,
      CardValue.six => 6,
      CardValue.seven => 7,
      CardValue.eight => 8,
      CardValue.nine => 9,
      CardValue.ten ||
      CardValue.jack ||
      CardValue.queen ||
      CardValue.king => 10,
      CardValue.ace => 1,
      CardValue.joker_1 || CardValue.joker_2 => 0,
    };
    hasAce = hasAce || card.value == CardValue.ace;
  }

  return (hard: hard, soft: hasAce ? hard + 10 : null);
}

/// Returns the highest available hand total that does not exceed 21.
int _bestTotal(List<PlayingCard> cards) {
  final total = _handTotal(cards);
  return total.soft != null && total.soft! <= 21 ? total.soft! : total.hard;
}

class _RangeTextInputFormatter extends TextInputFormatter {
  _RangeTextInputFormatter({required this.maximum});

  final int maximum;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final value = int.tryParse(newValue.text);
    if (value == null || value < 1 || value > maximum) {
      return oldValue;
    }

    return newValue;
  }
}

class _DealerSpot extends StatelessWidget {
  const _DealerSpot({
    required this.cards,
    required this.revealHand,
    required this.cardBack,
    required this.patternIndex,
  });

  final List<PlayingCard> cards;
  final bool revealHand;
  final CardBackDesign cardBack;
  final int patternIndex;

  @override
  Widget build(BuildContext context) {
    final totalLabel = revealHand ? _totalLabel(cards) : 'TOTAL --';

    return Semantics(
      label: 'Dealer hand, $totalLabel',
      child: _ScaledSpot(
        designWidth: 190,
        designHeight: 145,
        child: Column(
          children: [
            const _SpotLabel('DEALER'),
            const SizedBox(height: 4),
            _FannedCards(
              cards: cards,
              hideSecondCard: cards.length > 1 && !revealHand,
              cardBack: cardBack,
              patternIndex: patternIndex,
            ),
            const SizedBox(height: 4),
            Text(
              totalLabel,
              style: TextStyle(
                color: revealHand && _handTotal(cards).hard > 21
                    ? Colors.amberAccent
                    : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerSpot extends StatelessWidget {
  const _PlayerSpot({
    required this.playerNumber,
    required this.cards,
    required this.selectedAction,
    required this.isActive,
    required this.dealerTotal,
    required this.onActionSelected,
  });

  final int playerNumber;
  final List<PlayingCard> cards;
  final String? selectedAction;
  final bool isActive;
  final int? dealerTotal;
  final ValueChanged<String> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final total = _handTotal(cards);
    final isBust = total.hard > 21;
    final totalLabel = dealerTotal == null || isBust
        ? _totalLabel(cards)
        : _resultLabel(
            playerTotal: _bestTotal(cards),
            dealerTotal: dealerTotal!,
          );

    return Semantics(
      label: 'Player $playerNumber, $totalLabel, with Hit and Stand controls',
      child: _ScaledSpot(
        designWidth: 176,
        designHeight: 218,
        child: Column(
          children: [
            _SpotLabel('PLAYER $playerNumber'),
            const SizedBox(height: 4),
            Text(
              totalLabel,
              style: TextStyle(
                color: isBust ? Colors.amberAccent : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            _FannedCards(cards: cards),
            const SizedBox(height: 10),
            _HitStayPosition(
              selectedAction: selectedAction,
              isEnabled: isActive,
              onActionSelected: onActionSelected,
            ),
          ],
        ),
      ),
    );
  }
}

String _resultLabel({required int playerTotal, required int dealerTotal}) {
  if (dealerTotal > 21 || playerTotal > dealerTotal) {
    return 'Win';
  }
  if (playerTotal < dealerTotal) {
    return 'Lose';
  }
  return 'Push';
}

class _FannedCards extends StatelessWidget {
  const _FannedCards({
    required this.cards,
    this.hideSecondCard = false,
    this.cardBack,
    this.patternIndex = 0,
  });

  static const _width = 166.0;
  static const _height = 90.0;
  static const _cardWidth = 64.0;

  final List<PlayingCard> cards;
  final bool hideSecondCard;
  final CardBackDesign? cardBack;
  final int patternIndex;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox(
        width: _width,
        height: _height,
        child: Center(child: _CardOutline()),
      );
    }

    final offset = cards.length == 1
        ? 0.0
        : math.min(28.0, (_width - _cardWidth) / (cards.length - 1));
    final handWidth = _cardWidth + offset * (cards.length - 1);
    final start = (_width - handWidth) / 2;
    final center = (cards.length - 1) / 2;

    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < cards.length; index++)
            Positioned(
              left: start + offset * index,
              child: Transform.rotate(
                angle: (index - center) * 0.045,
                alignment: Alignment.bottomCenter,
                child: _CardOutline(
                  card: cards[index],
                  faceDown: hideSecondCard && index == 1,
                  cardBack: cardBack,
                  patternIndex: patternIndex,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _totalLabel(List<PlayingCard> cards) {
  if (cards.isEmpty) {
    return 'TOTAL --';
  }

  if (_isBlackJack(cards)) {
    return 'Black Jack';
  }

  final total = _handTotal(cards);
  final isBust = total.hard > 21;
  return total.soft == null
      ? '${isBust ? 'BUST' : 'TOTAL'} ${total.hard}'
      : '${isBust ? 'BUST  /  ' : ''}HARD ${total.hard}  /  SOFT ${total.soft}';
}

/// Whether [cards] is a two-card hand containing an ace and a ten-value card.
bool _isBlackJack(List<PlayingCard> cards) {
  if (cards.length != 2 || !cards.any((card) => card.value == CardValue.ace)) {
    return false;
  }

  return cards.any(
    (card) =>
        card.value == CardValue.ten ||
        card.value == CardValue.jack ||
        card.value == CardValue.queen ||
        card.value == CardValue.king,
  );
}

class _ScaledSpot extends StatelessWidget {
  const _ScaledSpot({
    required this.designWidth,
    required this.designHeight,
    required this.child,
  });

  final double designWidth;
  final double designHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(width: designWidth, height: designHeight, child: child),
      ),
    );
  }
}

class _SpotLabel extends StatelessWidget {
  const _SpotLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}

class _CardOutline extends StatelessWidget {
  const _CardOutline({
    this.card,
    this.faceDown = false,
    this.cardBack,
    this.patternIndex = 0,
  });

  final PlayingCard? card;
  final bool faceDown;
  final CardBackDesign? cardBack;
  final int patternIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 90,
      padding: card != null && faceDown ? const EdgeInsets.all(4) : null,
      decoration: BoxDecoration(
        color: card != null ? Colors.white : null,
        border: Border.all(color: Colors.white70, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: card == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: faceDown
                  ? CustomPaint(
                      painter: CardBackPainter(
                        color: cardBack!.color,
                        accent: cardBack!.accent,
                        patternIndex: patternIndex,
                      ),
                    )
                  : PlayingCardView(card: card!),
            ),
    );
  }
}

class _HitStayPosition extends StatelessWidget {
  const _HitStayPosition({
    required this.selectedAction,
    required this.isEnabled,
    required this.onActionSelected,
  });

  final String? selectedAction;
  final bool isEnabled;
  final ValueChanged<String> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final hasStayed = selectedAction == 'Stay';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PlayerActionButton(
          label: 'Hit',
          isSelected: selectedAction == 'Hit',
          onPressed: !isEnabled || hasStayed
              ? null
              : () => onActionSelected('Hit'),
        ),
        const SizedBox(width: 8),
        _PlayerActionButton(
          label: 'Stand',
          isSelected: hasStayed,
          onPressed: !isEnabled || hasStayed
              ? null
              : () => onActionSelected('Stay'),
        ),
      ],
    );
  }
}

class _PlayerActionButton extends StatelessWidget {
  const _PlayerActionButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.white24 : Colors.transparent,
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
