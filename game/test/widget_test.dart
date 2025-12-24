import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:get_it/get_it.dart';
import 'package:game/main.dart';
import 'package:game/game/logic/meta_manager.dart';
import 'package:game/game/logic/shop_manager.dart';
// Just in case, or remove

void main() {
  setUp(() {
    GetIt.I.reset();
    GetIt.I.registerSingleton<ShopManager>(ShopManager());
    GetIt.I.registerSingleton<MetaManager>(MetaManager());
  });

  tearDown(() {
    GetIt.I.reset();
  });

  testWidgets('Lobby Flow: Buy and Battle', (WidgetTester tester) async {
    // Register here to be sure
    if (!GetIt.I.isRegistered<ShopManager>()) {
      GetIt.I.registerSingleton<ShopManager>(ShopManager());
    }

    await tester.pumpWidget(const ArenaApp());

    // Check Shop UI
    expect(find.text('Preparation Phase'), findsOneWidget);
    expect(find.textContaining('Gold:'), findsOneWidget);

    // Find a shop card by cost (assuming at least one hero costs 1-3 G and shop is populated)
    // The shop has 5 items.
    // Try finding "1 G" or "2 G".
    // The shop has 5 items.
    // Use first card cost to find widget.
    final firstCardCost = '${GetIt.I<ShopManager>().currentShop.first.cost} G';
    await tester.tap(find.text(firstCardCost).first);
    await tester.pump();

    // Check Bench Logic
    expect(GetIt.I<ShopManager>().bench.isNotEmpty, true);

    // Tap to deploy
    // Since we created custom widgets, finding them via text is easiest
    final heroName = GetIt.I<ShopManager>().bench.first.name;
    await tester.tap(find.text(heroName).first);
    await tester.pump();

    // Should be in field
    expect(GetIt.I<ShopManager>().field.isNotEmpty, true);

    // BATTLE
    // Text changed to FIND MATCH
    await tester.tap(find.text('FIND MATCH'));
    await tester.pump(); // Don't pumpAndSettle, game loop might run forever
    await tester.pump(const Duration(milliseconds: 500));

    // Should be in Game
    expect(find.byType(GameWidget), findsOneWidget);
  });
}
