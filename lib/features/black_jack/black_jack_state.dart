import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Storage contract for the serialized Black Jack game snapshot.
abstract interface class BlackJackStateStore {
  /// Returns the saved snapshot, or `null` when no game has been saved.
  Future<String?> read();

  /// Replaces the saved snapshot with [value].
  Future<void> write(String value);

  /// Deletes the saved snapshot.
  Future<void> remove();
}

/// Persists the Black Jack snapshot in asynchronous shared preferences.
class SharedPreferencesBlackJackStateStore implements BlackJackStateStore {
  SharedPreferencesBlackJackStateStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _stateKey = 'black_jack_state_v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(_stateKey);

  @override
  Future<void> write(String value) => _preferences.setString(_stateKey, value);

  @override
  Future<void> remove() => _preferences.remove(_stateKey);
}

class BlackJackState {
  const BlackJackState({
    required this.selectedMode,
    required this.shuffleValues,
    required this.deckCardIndexes,
    required this.dealerCardIndexes,
    required this.playerCardIndexes,
    required this.playerActions,
    required this.nextCardIndex,
    required this.activePlayer,
    required this.dealerTurnComplete,
  });

  static const version = 1;
  static const modes = {'In', 'Out', 'Binary'};
  static const maximumValues = {'In': 52, 'Out': 8, 'Binary': 51};

  final String selectedMode;
  final Map<String, String> shuffleValues;
  final List<int>? deckCardIndexes;
  final List<int> dealerCardIndexes;
  final Map<int, List<int>> playerCardIndexes;
  final Map<int, String> playerActions;
  final int nextCardIndex;
  final int? activePlayer;
  final bool dealerTurnComplete;

  /// Serializes this snapshot to the current versioned JSON representation.
  ///
  /// Validation is performed by [BlackJackState.decode] when the snapshot is
  /// restored rather than while it is encoded.
  String encode() => jsonEncode({
    'version': version,
    'selectedMode': selectedMode,
    'shuffleValues': shuffleValues,
    'deckCardIndexes': deckCardIndexes,
    'dealerCardIndexes': dealerCardIndexes,
    'playerCardIndexes': {
      for (final entry in playerCardIndexes.entries)
        '${entry.key}': entry.value,
    },
    'playerActions': {
      for (final entry in playerActions.entries) '${entry.key}': entry.value,
    },
    'nextCardIndex': nextCardIndex,
    'activePlayer': activePlayer,
    'dealerTurnComplete': dealerTurnComplete,
  });

  /// Parses and validates a versioned game snapshot from [source].
  ///
  /// Validation covers the shuffle mode and ranges, the complete unique deck,
  /// card indexes, player numbers and actions, and consistency between game
  /// progress and the saved hands. Throws [FormatException] for malformed or
  /// unsupported snapshots.
  factory BlackJackState.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> || decoded['version'] != version) {
      throw const FormatException('Unsupported Black Jack state.');
    }

    final selectedMode = decoded['selectedMode'];
    if (selectedMode is! String || !modes.contains(selectedMode)) {
      throw const FormatException('Invalid shuffle mode.');
    }

    final shuffleValues = _stringMap(decoded['shuffleValues']);
    if (shuffleValues.keys.toSet().difference(modes).isNotEmpty ||
        modes.difference(shuffleValues.keys.toSet()).isNotEmpty ||
        shuffleValues.entries.any((entry) {
          final value = int.tryParse(entry.value);
          return value == null ||
              value < 1 ||
              value > maximumValues[entry.key]!;
        })) {
      throw const FormatException('Invalid shuffle values.');
    }

    final deckCardIndexes = decoded['deckCardIndexes'] == null
        ? null
        : _cardIndexes(decoded['deckCardIndexes']);
    if (deckCardIndexes != null &&
        (deckCardIndexes.length != 52 ||
            deckCardIndexes.toSet().length != 52)) {
      throw const FormatException('Invalid saved deck.');
    }

    final nextCardIndex = decoded['nextCardIndex'];
    final activePlayer = decoded['activePlayer'];
    final dealerTurnComplete = decoded['dealerTurnComplete'];
    if (nextCardIndex is! int ||
        nextCardIndex < 0 ||
        nextCardIndex > 52 ||
        (activePlayer != null &&
            (activePlayer is! int || activePlayer < 1 || activePlayer > 5)) ||
        dealerTurnComplete is! bool) {
      throw const FormatException('Invalid game progress.');
    }

    final dealerCardIndexes = _cardIndexes(decoded['dealerCardIndexes']);
    final playerCardIndexes = _intListMap(decoded['playerCardIndexes']);
    final playerActions = _intStringMap(decoded['playerActions']);
    if (playerCardIndexes.keys.any((player) => player < 1 || player > 5) ||
        playerActions.keys.any((player) => player < 1 || player > 5) ||
        playerActions.keys.any(
          (player) => !playerCardIndexes.containsKey(player),
        ) ||
        playerActions.values.any(
          (action) => action != 'Hit' && action != 'Stay',
        ) ||
        (activePlayer != null &&
            !playerCardIndexes.containsKey(activePlayer)) ||
        (deckCardIndexes == null &&
            (dealerCardIndexes.isNotEmpty ||
                playerCardIndexes.isNotEmpty ||
                playerActions.isNotEmpty ||
                activePlayer != null ||
                dealerTurnComplete))) {
      throw const FormatException('Invalid player state.');
    }

    return BlackJackState(
      selectedMode: selectedMode,
      shuffleValues: shuffleValues,
      deckCardIndexes: deckCardIndexes,
      dealerCardIndexes: dealerCardIndexes,
      playerCardIndexes: playerCardIndexes,
      playerActions: playerActions,
      nextCardIndex: nextCardIndex,
      activePlayer: activePlayer as int?,
      dealerTurnComplete: dealerTurnComplete,
    );
  }
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map<String, dynamic> ||
      value.values.any((entry) => entry is! String)) {
    throw const FormatException('Expected string map.');
  }
  return value.map((key, value) => MapEntry(key, value as String));
}

List<int> _cardIndexes(Object? value) {
  if (value is! List ||
      value.any((entry) => entry is! int || entry < 0 || entry > 51)) {
    throw const FormatException('Invalid card indexes.');
  }
  return value.cast<int>();
}

Map<int, List<int>> _intListMap(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected player card map.');
  }
  return value.map((key, value) {
    final player = int.tryParse(key);
    if (player == null) {
      throw const FormatException('Invalid player number.');
    }
    return MapEntry(player, _cardIndexes(value));
  });
}

Map<int, String> _intStringMap(Object? value) {
  if (value is! Map<String, dynamic> ||
      value.values.any((entry) => entry is! String)) {
    throw const FormatException('Expected player action map.');
  }
  return value.map((key, value) {
    final player = int.tryParse(key);
    if (player == null) {
      throw const FormatException('Invalid player number.');
    }
    return MapEntry(player, value as String);
  });
}
