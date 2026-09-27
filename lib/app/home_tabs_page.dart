import 'package:flutter/material.dart';

import '../features/binary_shuffle/binary_shuffle_page.dart';
import '../features/black_jack/black_jack_page.dart';
import '../features/card_backs/card_back_selector.dart';
import '../features/deck/grouped_card_deck.dart';
import '../features/faro/face_down_deck.dart';
import '../features/faro/vertical_grouped_card_deck.dart';
import '../features/help/help_page.dart';
import '../features/information/information_page.dart';
import '../shared/card_table_surface.dart';
import '../shared/cards/card_back.dart';

class HomeTabsPage extends StatelessWidget {
  const HomeTabsPage({
    required this.selectedCardBackIndex,
    required this.onCardBackSelected,
    super.key,
  });

  static const _tabLabels = [
    'Card Backs',
    'Card Deck',
    'Out-Faro Shuffle',
    'In-Faro Shuffle',
    'Binary Shuffle',
    'Faro Challenge',
    'Black Jack',
    'Information',
    'Help',
  ];

  final int selectedCardBackIndex;
  final ValueChanged<int> onCardBackSelected;

  /// Whether all tabs would overflow [availableWidth] at equal widths.
  ///
  /// The estimate uses the widest localized label, active text scaling, and
  /// the same horizontal padding assigned to each tab.
  bool _shouldScrollTabs(BuildContext context, double availableWidth) {
    final textStyle =
        Theme.of(context).tabBarTheme.labelStyle ??
        Theme.of(context).textTheme.titleSmall ??
        const TextStyle(fontSize: 14);
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    var widestLabel = 0.0;

    for (final label in _tabLabels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      widestLabel = widestLabel < painter.width ? painter.width : widestLabel;
    }

    const horizontalLabelPadding = 32.0;
    return availableWidth <
        (widestLabel + horizontalLabelPadding) * _tabLabels.length;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabLabels.length,
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF8F1D24),
          flexibleSpace: const CustomPaint(
            painter: FeltTexturePainter(),
            child: SizedBox.expand(),
          ),
          title: const Text('Shuffle Master'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kTextTabBarHeight),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isScrollable = _shouldScrollTabs(
                  context,
                  constraints.maxWidth,
                );

                return TabBar(
                  isScrollable: isScrollable,
                  tabAlignment: isScrollable
                      ? TabAlignment.start
                      : TabAlignment.fill,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: [for (final label in _tabLabels) Tab(text: label)],
                );
              },
            ),
          ),
        ),
        body: TabBarView(
          children: [
            CardTableSurface(
              child: CardBackSelector(
                selectedIndex: selectedCardBackIndex,
                onSelected: onCardBackSelected,
              ),
            ),
            const CardTableSurface(child: GroupedCardDeck()),
            const CardTableSurface(child: VerticalGroupedCardDeck()),
            const CardTableSurface(
              child: VerticalGroupedCardDeck(secondHalfFirst: true),
            ),
            const CardTableSurface(child: BinaryShufflePage()),
            CardTableSurface(
              child: FaceDownDeck(
                cardBack: cardBackDesigns[selectedCardBackIndex],
                patternIndex: selectedCardBackIndex,
              ),
            ),
            CardTableSurface(
              child: BlackJackPage(
                cardBack: cardBackDesigns[selectedCardBackIndex],
                patternIndex: selectedCardBackIndex,
              ),
            ),
            const InformationPage(),
            const HelpPage(),
          ],
        ),
      ),
    );
  }
}
