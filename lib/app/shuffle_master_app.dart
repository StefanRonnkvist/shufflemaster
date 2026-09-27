import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/cards/card_back.dart';
import 'home_tabs_page.dart';
import 'splash_screen.dart';

class ShuffleMasterApp extends StatefulWidget {
  const ShuffleMasterApp({super.key});

  @override
  State<ShuffleMasterApp> createState() => _ShuffleMasterAppState();
}

class _ShuffleMasterAppState extends State<ShuffleMasterApp> {
  static const _selectedCardBackKey = 'selected_card_back';

  final _preferences = SharedPreferencesAsync();
  int _selectedCardBackIndex = 0;
  bool _selectionChanged = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedCardBack();
  }

  /// Restores the selected design while enforcing the minimum splash duration.
  ///
  /// A selection made before loading completes takes precedence over the saved
  /// value, and an unknown saved name falls back to the first design.
  Future<void> _loadSelectedCardBack() async {
    final results = await Future.wait([
      _preferences.getString(_selectedCardBackKey),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]);
    final savedName = results.first as String?;
    final savedIndex = cardBackDesigns.indexWhere(
      (cardBack) => cardBack.name == savedName,
    );

    if (mounted) {
      setState(() {
        if (!_selectionChanged && savedIndex != -1) {
          _selectedCardBackIndex = savedIndex;
        }
        _isInitializing = false;
      });
    }
  }

  /// Applies [index] immediately and persists the design by its stable name.
  Future<void> _selectCardBack(int index) async {
    setState(() {
      _selectionChanged = true;
      _selectedCardBackIndex = index;
    });
    await _preferences.setString(
      _selectedCardBackKey,
      cardBackDesigns[index].name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _isInitializing
            ? const SplashScreen()
            : HomeTabsPage(
                selectedCardBackIndex: _selectedCardBackIndex,
                onCardBackSelected: _selectCardBack,
              ),
      ),
    );
  }
}
