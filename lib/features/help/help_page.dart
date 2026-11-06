import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _sections = [
    (
      icon: Icons.style_outlined,
      title: 'Card Backs',
      description:
          'Choose one of 10 card-back designs: Crimson Lattice, Midnight Star, '
          'Emerald Crown, Black Diamond, Royal Sun, Violet Constellation, '
          'Ocean Chevron, Burgundy Orbit, Silver Mosaic, and Teal Current. '
          'Your selection is used by the Faro Challenge and Black Jack tabs '
          'and is remembered when you reopen the app.',
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
          'A perfect out-Faro interlaces the two equal halves while keeping '
          'the original top and bottom cards in place. Tap Shuffle for one '
          'step, Auto Increment to shuffle once per second, or Reset to restore '
          'the original deck. Auto Increment stops at the end of the cycle; '
          'the counter returns to 0 when the deck returns to its original '
          'order after eight out-shuffles. ',
    ),
    (
      icon: Icons.swap_vert,
      title: 'In-Faro Shuffle',
      description:
          'A perfect in-Faro interlaces the halves starting with the lower '
          'half, moving the original top card to position 2. Tap Shuffle for '
          'one step, Auto Increment to shuffle once per second, or Reset to '
          'restore the original deck. The 52-step cycle stops automatically '
          'and describes its stages: early separation, maximum apparent '
          'randomness at shuffle 26, then realignment and a snap back at 51.',
    ),
    (
      icon: Icons.pin_outlined,
      title: 'Binary Shuffle',
      description:
          'Enter a value from 0 to 51 to represent a six-bit Faro sequence '
          'using place values 32, 16, 8, 4, 2, and 1. The circles show which '
          'places are ignored and whether each processed bit applies an Out '
          'shuffle (0) or an In shuffle (1); unused higher places are ignored. '
          'Select Emulate to watch the deck and original top card move through '
          'the sequence. A value of 0 ignores every place and leaves the deck unchanged.',
    ),
    (
      icon: Icons.layers_outlined,
      title: 'Faro Challenge',
      description:
          'Choose Out (1-8), In (1-52), or Binary, then predict where a card '
          'will land in the resulting deck. Positions are numbered 1 to 52. '
          'Tap any face-down card to reveal it, and tap again to hide it. '
          'Changing the shuffle mode, count, or binary sequence hides all '
          'revealed cards and recalculates the deck order.',
    ),
    (
      icon: Icons.casino_outlined,
      title: 'Black Jack',
      description:
          'Choose In (1-52), Out (1-8), or Binary (1-51), set its value, and '
          'tap Deal to give two cards to each of five players and the dealer. '
          'Play the highlighted hand with Hit or Stand; a bust or 21 ends the '
          'turn automatically. After all players finish, the dealer hits on '
          '17 or less unless every player busted. Non-busted hands are marked '
          'Win, Lose, or Push. Continue deals a new round when at least 12 '
          'cards remain; Shuffle rebuilds the selected order and clears the '
          'round. Game progress and settings are saved on this device and restored '
          'after restart.',
    ),
    (
      icon: Icons.info_outline,
      title: 'Information',
      description:
          'Contact requires your name, return email, and question, and sends '
          'those details with app diagnostics to the developer over the '
          'internet. Inquiries loads online submissions for this app and '
          'displays app, version, series, content, and date/time details; '
          'names and email addresses are not displayed. Both views require an '
          'internet connection.',
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
                    'top tab bar horizontally to reach hidden tabs. The bar '
                    'scrolls when all nine tabs do not fit, such as in a narrow '
                    'window or with large text sizes. The Information tab has '
                    'online Contact and Inquiries views; you need an internet connection '
                    'to use them.',
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
