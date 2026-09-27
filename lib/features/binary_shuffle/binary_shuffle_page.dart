import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:playing_cards/playing_cards.dart';

import '../../shared/deck/faro_shuffle.dart';
import '../../shared/widgets/animated_shuffle_deck.dart';
import '../../shared/widgets/binary_shuffle_selectors.dart';

class BinaryShufflePage extends StatefulWidget {
  const BinaryShufflePage({super.key});

  @override
  State<BinaryShufflePage> createState() => _BinaryShufflePageState();
}

class _BinaryShufflePageState extends State<BinaryShufflePage> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  late List<PlayingCard> cards;
  late PlayingCard firstCard;
  int enteredValue = 0;
  int? processingValue;
  bool isEmulating = false;

  @override
  void initState() {
    super.initState();
    cards = standardFiftyTwoCardDeck();
    firstCard = cards.first;
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = switch (constraints.maxWidth) {
          < 600 => _buildPhoneLayout(),
          < 1024 => _buildTabletLayout(),
          _ => _buildDesktopLayout(),
        };

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
              PointerDeviceKind.trackpad,
            },
          ),
          child: content,
        );
      },
    );
  }

  Widget _buildPhoneLayout() {
    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              children: [
                _buildValueField(width: 120),
                const SizedBox(height: 24),
                Scrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ..._buildSpacedPlaces(12),
                        const SizedBox(width: 12),
                        _buildEmulateButton(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                _buildSplitDeck(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildValueField(width: 120),
              const SizedBox(height: 32),
              Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._buildSpacedPlaces(16),
                      const SizedBox(width: 16),
                      _buildEmulateButton(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildSplitDeck(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 44),
        child: Column(
          children: [
            Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    _buildValueField(width: 96),
                    const SizedBox(width: 32),
                    ..._buildSpacedPlaces(16),
                    const SizedBox(width: 16),
                    _buildEmulateButton(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildSplitDeck(),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitDeck() {
    return Column(
      children: [
        AnimatedShuffleDeck(
          cards: cards,
          liftedCard: firstCard,
          isCardLifted: isEmulating,
        ),
        const SizedBox(height: 20),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        'A binary faro shuffle represents perfect faro '
                        'shuffles using bits, where ',
                  ),
                  TextSpan(
                    text: '0 means an out-shuffle',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: '1 means an in-shuffle',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        '. Each bit in the sequence tells you which '
                        'permutation to apply, and because these shuffles are '
                        'mathematically precise, you can track exactly how '
                        'any card moves through the deck. When you choose a '
                        'number of binary faro shuffles, the ',
                  ),
                  TextSpan(
                    text: "first card's position is updated after each shuffle",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        ' according to the permutation: an out-shuffle keeps '
                        'it on top, while an in-shuffle moves it to position '
                        '2, and further shuffles continue moving it according '
                        'to the binary sequence. This makes binary encoding a '
                        'compact way to predict card trajectories and analyze '
                        'how many shuffles place a card in a specific location.',
                  ),
                ],
              ),
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmulateButton() {
    return FilledButton.icon(
      onPressed: isEmulating ? null : _emulate,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Emulate'),
    );
  }

  Future<void> _emulate() async {
    const placeValues = [32, 16, 8, 4, 2, 1];

    setState(() {
      cards = standardFiftyTwoCardDeck();
      processingValue = null;
      isEmulating = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 800));

    for (final value in placeValues) {
      if (!mounted) return;
      final isIgnored = enteredValue == 0 || value > enteredValue;
      final isInShuffle = enteredValue & value != 0;

      setState(() {
        processingValue = value;
        if (!isIgnored) {
          cards = faroShuffle(cards, isInShuffle: isInShuffle);
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
    }

    if (!mounted) return;
    setState(() {
      processingValue = null;
      isEmulating = false;
    });
  }

  Widget _buildValueField({required double width}) {
    return SizedBox(
      width: width,
      child: TextField(
        enabled: !isEmulating,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
          TextInputFormatter.withFunction((oldValue, newValue) {
            if (newValue.text.isEmpty) return newValue;
            final value = int.tryParse(newValue.text);
            return value != null && value <= 51 ? newValue : oldValue;
          }),
        ],
        onChanged: (text) {
          setState(() => enteredValue = int.tryParse(text) ?? 0);
        },
        decoration: const InputDecoration(
          labelText: 'Value',
          helperText: '0-51',
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Color(0xFF333333)),
          helperStyle: TextStyle(color: Colors.white70),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(color: Color(0xFF222222)),
      ),
    );
  }

  List<Widget> _buildSpacedPlaces(double spacing) {
    return [
      BinaryShuffleSelectors(
        value: enteredValue,
        processingValue: processingValue,
        spacing: spacing,
      ),
    ];
  }
}
