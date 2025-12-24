import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/battle_manager.dart';
import '../game/core/hero_entity.dart';
import '../game/core/projectile_entity.dart';
import '../game/core/item_data.dart';
import 'hud/mg_battle_hud.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late BattleManager _battleManager;

  @override
  void initState() {
    super.initState();
    _battleManager = BattleManager();
  }

  @override
  void dispose() {
    _battleManager.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _battleManager,
      child: Consumer<BattleManager>(
        builder: (context, manager, child) {
          // Calculate player and enemy HP totals for HUD
          final playerHeroes =
              manager.heroes.where((h) => h.isPlayer && !h.isDead);
          final enemyHeroes =
              manager.heroes.where((h) => !h.isPlayer && !h.isDead);

          final playerHp = playerHeroes.fold<int>(
            0,
            (sum, h) => sum + h.currentHp.toInt(),
          );
          final playerMaxHp = playerHeroes.fold<int>(
            0,
            (sum, h) => sum + h.data.stats.maxHp.toInt(),
          );
          final enemyHp = enemyHeroes.fold<int>(
            0,
            (sum, h) => sum + h.currentHp.toInt(),
          );
          final enemyMaxHp = enemyHeroes.fold<int>(
            0,
            (sum, h) => sum + h.data.stats.maxHp.toInt(),
          );

          return Scaffold(
            backgroundColor: const Color(0xFF222831),
            body: Stack(
              children: [
                // Main Content
                Column(
                  children: [
                    // AppBar replacement (safe area handled by MGBattleHud)
                    const SizedBox(height: 100), // Space for HUD
                    // Game Content
                    Expanded(
                      child: manager.state == BattleState.ended
                          ? _buildGameOverScreen(manager)
                          : _buildGameContent(manager),
                    ),
                  ],
                ),
                // MG Battle HUD Overlay
                MGBattleHud(
                  gold: manager.gold,
                  wave: manager.currentRound,
                  maxWave: manager.maxRounds,
                  playerHp: playerHp,
                  playerMaxHp: playerMaxHp > 0 ? playerMaxHp : 100,
                  enemyHp: enemyHp,
                  enemyMaxHp: enemyMaxHp > 0 ? enemyMaxHp : 100,
                  battleSpeed: 1.0,
                  onPause: manager.state == BattleState.battle
                      ? () {
                          // Pause functionality if needed
                        }
                      : null,
                  onSpeedChange: null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameContent(BattleManager manager) {
    return Column(
      children: [
        // Info Bar (simplified - main info in HUD)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          color: Colors.black45,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "State: ${manager.state.name.toUpperCase()}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (manager.state == BattleState.preparation)
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: manager.gold >= 2 ? manager.rerollShop : null,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Reroll (2g)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: manager.startBattle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("START BATTLE"),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // SHOP & SYNERGY UI (Only in Prep)
        if (manager.state == BattleState.preparation)
          Container(
            height: 120,
            color: const Color(0xFF303a52),
            child: Row(
              children: [
                // Synergy List
                Container(
                  width: 140,
                  padding: const EdgeInsets.all(8),
                  color: Colors.black12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Active Synergies:",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: ListView.builder(
                          itemCount: manager.activeSynergies.length,
                          itemBuilder: (context, index) {
                            final syn = manager.activeSynergies[index];
                            return Text(
                              "${syn.data.name} (${syn.count}): ${syn.data.thresholds[syn.activeThreshold]}",
                              style: TextStyle(
                                color: syn.count >= syn.activeThreshold
                                    ? Colors.greenAccent
                                    : Colors.white54,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Shop Items
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    itemCount: manager.shop.length,
                    itemBuilder: (context, index) {
                      final heroData = manager.shop[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => manager.buyUnit(heroData),
                          child: Container(
                            width: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFF404b69),
                              border: Border.all(
                                color: manager.gold >= 3
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  heroData.heroClass.name[0] == 'a'
                                      ? Icons.arrow_outward
                                      : Icons.shield,
                                  color: Colors.white70,
                                ),
                                Text(
                                  heroData.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Cost: 3g",
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        // Battle Grid
        Expanded(
          child: Center(
            child: _buildBattleField(manager, context),
          ),
        ),

        // Bench Area
        Container(
          height: 100,
          color: Colors.brown[900],
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const RotatedBox(
                quarterTurns: 3,
                child: Text(
                  "INVENTORY",
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
              const SizedBox(width: 10),
              // Inventory UI
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: manager.inventory.length,
                  itemBuilder: (context, index) {
                    final item = manager.inventory[index];
                    return Draggable<ItemData>(
                      data: item,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shield, color: Colors.black),
                        ),
                      ),
                      child: Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          border: Border.all(color: Colors.amber),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield, color: Colors.amber),
                      ),
                    );
                  },
                ),
              ),
              // Separator
              Container(
                width: 2,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              // Bench List
              const RotatedBox(
                quarterTurns: 3,
                child: Text(
                  "BAG",
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
              Expanded(
                child: DragTarget<HeroEntity>(
                  onWillAcceptWithDetails: (details) => details.data.row != -1,
                  onAcceptWithDetails: (details) =>
                      manager.recallUnit(details.data),
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      color: candidateData.isNotEmpty
                          ? Colors.white10
                          : Colors.transparent,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: manager.bench.length,
                        itemBuilder: (context, index) {
                          final hero = manager.bench[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _buildDraggableUnit(
                              hero,
                              80,
                              manager.state == BattleState.preparation,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              // SELL TARGET
              DragTarget<HeroEntity>(
                onWillAcceptWithDetails: (details) =>
                    manager.state == BattleState.preparation,
                onAcceptWithDetails: (details) {
                  manager.sellHero(details.data);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: 80,
                    color: candidateData.isNotEmpty
                        ? Colors.red.withOpacity(0.5)
                        : Colors.red.withOpacity(0.2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete, color: Colors.white),
                        Text(
                          candidateData.isNotEmpty ? "+2g" : "SELL",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBattleField(BattleManager manager, BuildContext context) {
    bool isPrep = manager.state == BattleState.preparation;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate cell size
        int rows = manager.grid.rows;
        int cols = manager.grid.cols;

        double cellW = constraints.maxWidth / cols;
        double cellH = constraints.maxHeight / rows;
        double cellSize = (cellW < cellH ? cellW : cellH) * 0.95;

        return SizedBox(
          width: cellSize * cols,
          height: cellSize * rows,
          child: Stack(
            children: [
              // 1. Grid Background & DragTargets
              for (int r = 0; r < rows; r++)
                for (int c = 0; c < cols; c++)
                  Positioned(
                    left: c * cellSize,
                    top: r * cellSize,
                    child: DragTarget<HeroEntity>(
                      onWillAcceptWithDetails: (details) => isPrep,
                      onAcceptWithDetails: (details) {
                        final data = details.data;
                        if (data.row == -1) {
                          manager.deployUnit(data, r, c);
                        } else {
                          manager.moveUnitOnGrid(data, r, c);
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white10),
                            color: candidateData.isNotEmpty
                                ? Colors.green.withValues(alpha: 0.3)
                                : ((r + c) % 2 == 0
                                      ? Colors.white10
                                      : Colors.transparent),
                          ),
                        );
                      },
                    ),
                  ),

              // 2. Units on Grid
              for (var hero in manager.heroes)
                if (!hero.isDead)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: hero.col * cellSize,
                    top: hero.row * cellSize,
                    child: _buildDraggableUnit(hero, cellSize, isPrep),
                  ),

              // 3. Projectiles
              for (var proj in manager.projectiles)
                Positioned(
                  left: proj.x * cellSize + cellSize * 0.25, // Center offset
                  top: proj.y * cellSize + cellSize * 0.25,
                  child: Transform.rotate(
                    angle: 0, // Calculate angle if needed
                    child: Icon(
                      proj.type == ProjectileType.fireball
                          ? Icons.local_fire_department
                          : Icons.arrow_right_alt,
                      color: proj.type == ProjectileType.fireball
                          ? Colors.orange
                          : Colors.white,
                      size: cellSize * 0.5,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableUnit(HeroEntity hero, double size, bool isPrep) {
    Widget unitVisual = _buildUnitVisual(hero, size);

    // Wrap to accept Items
    return DragTarget<ItemData>(
      onWillAcceptWithDetails: (details) => isPrep && hero.equipment.length < 3,
      onAcceptWithDetails: (details) {
        Provider.of<BattleManager>(
          context,
          listen: false,
        ).equipItem(hero, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return Draggable<HeroEntity>(
          data: hero,
          feedback: Opacity(opacity: 0.7, child: unitVisual),
          childWhenDragging: Opacity(opacity: 0.3, child: unitVisual),
          // Disable dragging if not prep or dead (though dead check usually before)
          maxSimultaneousDrags: isPrep ? 1 : 0,
          child: Container(
            decoration: BoxDecoration(
              border: candidateData.isNotEmpty
                  ? Border.all(color: Colors.amber, width: 2)
                  : null,
            ),
            child: unitVisual,
          ),
        );
      },
    );
  }

  Widget _buildUnitVisual(HeroEntity hero, double size) {
    bool isHit =
        DateTime.now().millisecondsSinceEpoch - hero.lastDamageTick <
        200; // Flash for 200ms
    Color color = isHit
        ? Colors.white
        : (hero.isPlayer ? Colors.blue : Colors.red);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sprite placeholder
          Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              hero.data.heroClass.name[0] == 'a'
                  ? Icons.arrow_outward
                  : Icons.shield,
              size: size * 0.3,
              color: Colors.white,
            ),
          ),

          // HP Bar
          Container(
            width: size * 0.8,
            height: 4,
            margin: const EdgeInsets.only(top: 2),
            child: LinearProgressIndicator(
              value: hero.currentHp / hero.data.stats.maxHp,
              backgroundColor: Colors.black54,
              color: Colors.green,
            ),
          ),
          // Mana Bar (New)
          if (hero.maxMana > 0)
            Container(
              width: size * 0.8,
              height: 2, // Thinner than HP
              margin: const EdgeInsets.only(top: 1),
              child: LinearProgressIndicator(
                value: hero.currentMana / hero.maxMana,
                backgroundColor: Colors.black54,
                color: Colors.blueAccent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen(BattleManager manager) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            manager.playerWon == true ? "VICTORY" : "DEFEAT",
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          if (manager.playerWon == true &&
              manager.currentRound < manager.maxRounds)
            ElevatedButton(
              onPressed: () {
                manager.nextWave(); // Proceed
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text("NEXT WAVE", style: TextStyle(fontSize: 20)),
            )
          else
            ElevatedButton(
              onPressed: () {
                // Restart Game (Reload)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const BattleScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: Text(
                manager.playerWon == true ? "PLAY AGAIN" : "TRY AGAIN",
                style: const TextStyle(fontSize: 20),
              ),
            ),
        ],
      ),
    );
  }
}
