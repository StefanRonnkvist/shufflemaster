import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shufflemaster/app/home_tabs_page.dart';

void main() {
  Future<void> pumpHomeTabs(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeTabsPage(
          selectedCardBackIndex: 0,
          onCardBackSelected: (_) {},
        ),
      ),
    );
  }

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  testWidgets('fills wide tab bar and scrolls when space is limited', (
    tester,
  ) async {
    await pumpHomeTabs(tester, const Size(2400, 900));

    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isFalse);

    await pumpHomeTabs(tester, const Size(400, 800));

    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue);
    expect(tester.takeException(), isNull);
  });
}
