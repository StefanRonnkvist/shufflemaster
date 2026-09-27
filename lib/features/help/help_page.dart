import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _sections = [
    (
      icon: Icons.style_outlined,
      title: 'Card Backs',
      description:
          'Choose one of 10 card-back designs. Your selection is used by the '
          'Faro Challenge and Black Jack tabs and is remembered when you '
          'reopen the app.',
    ),
    (
      icon: Icons.view_carousel_outlined,
      title: 'Card Deck',
      description:
          'Browse all 52 cards in a standard deck, grouped by suit for quick '
          'reference.',
    ),
    (
      icon: Icons.shuffle,
      title: 'Out-Faro Shuffle',
      description:
          'Perform perfect out-Faro shuffles, where the original top card '
          'stays on top. Use Shuffle to advance one step, Auto Increment to '
          'advance once per second, and Reset to restore the deck. A '
          '52-card deck returns to its original order after 8 out-shuffles.',
    ),
    (
      icon: Icons.swap_vert,
      title: 'In-Faro Shuffle',
      description:
          'Perform perfect in-Faro shuffles, where the first card from the '
          'lower half moves to the top. Use the same manual, automatic, and '
          'reset controls to follow the 52-shuffle cycle.',
    ),
    (
      icon: Icons.pin_outlined,
      title: 'Binary Shuffle',
      description:
          'Enter a value from 0 to 51 to represent a six-bit Faro sequence. '
          'The circles show which place values are ignored and whether each '
          'processed bit applies an Out (0) or In (1) shuffle. Select Emulate '
          'to watch the original top card move through the sequence; 0 '
          'ignores every place and leaves the deck unchanged.',
    ),
    (
      icon: Icons.layers_outlined,
      title: 'Faro Challenge',
      description:
          'Choose Out (1-8), In (1-52), or a Binary shuffle sequence, then '
          'predict where a card will land. Positions run from 1 at the left '
          'to 52 at the right. Tap any face-down position to reveal or hide '
          'its card. Changing a setting hides every revealed card and builds '
          'the new deck order.',
    ),
    (
      icon: Icons.casino_outlined,
      title: 'Black Jack',
      description:
          'Choose In (1-52), Out (1-8), or Binary (1-51), then Deal to five '
          'players and the dealer. Take each highlighted hand in order with '
          'Hit or Stand. A bust or 21 ends that turn automatically. After all '
          'players finish, the dealer hits on 17 or less unless every player '
          'busted, then non-busted hands show Win, Lose, or Push. Continue '
          'deals from the remaining deck when at least 12 cards remain; '
          'Shuffle rebuilds the selected order. The game and settings are '
          'saved locally and restored after restart.',
    ),
    (
      icon: Icons.info_outline,
      title: 'Information',
      description:
          'Use Contact to send your name, email, question, and the displayed '
          'app diagnostics to the developer. Inquiries downloads submissions '
          'for this app and displays their app, version, subject, message, and '
          'date fields without names or email addresses. Both views require '
          'an internet connection.',
    ),
    (
      icon: Icons.help_outline,
      title: 'Help',
      description: 'Review the purpose and controls of every tab in the app.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _sections.length + 1,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shuffle Master Help',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap a tab to open it, swipe between pages, or scroll the '
                    'top tab bar horizontally to reach hidden tabs.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final section = _sections[index - 1];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            leading: Icon(section.icon, color: colors.primary),
            title: Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(section.description),
            ),
          );
        },
      ),
    );
  }
}
