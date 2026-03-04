import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';
import 'package:mg_common_game/core/audio/audio_manager.dart';
import 'package:mg_common_game/core/ui/theme/mg_colors.dart';
import 'game/auto_combat_manager.dart';
import 'game/team_manager.dart';
import 'game/progression_manager.dart';
import 'ui/main_menu_screen.dart';

// ============================================================
// Hero Auto Battle — MG-0006
// Genre: RPG · Auto Battler · Year 1 Core
// Phase 1 Week 3: Mechanic Enhancement
//
// Core loop: Build Team → Deploy → Auto-Battle → Upgrade → Progress
// Subsystems: Auto-combat tuning, Team synergies, Progression, Prestige
// ============================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeSystems();
  runApp(const CardBattleApp());
}

// ============================================================
// System Initialization — DI registration in dependency order
// ============================================================

/// Initialize all DI-registered systems in correct dependency order.
/// mg_common_game systems first, then game-specific managers.
Future<void> _initializeSystems() async {
  final di = GetIt.I;

  // ── mg_common_game core systems ──────────────────────────
  if (!di.isRegistered<GoldManager>()) {
    di.registerSingleton<GoldManager>(GoldManager());
  }

  if (!di.isRegistered<AudioManager>()) {
    final audioManager = AudioManager();
    di.registerSingleton<AudioManager>(audioManager);
    audioManager.initialize();
  }

  if (!di.isRegistered<UpgradeManager>()) {
    final upgrades = UpgradeManager();
    di.registerSingleton<UpgradeManager>(upgrades);
    _registerUpgrades(upgrades);
    await upgrades.loadUpgrades();
  }

  // ── Game-specific managers ───────────────────────────────
  if (!di.isRegistered<AutoCombatManager>()) {
    di.registerSingleton<AutoCombatManager>(AutoCombatManager());
  }

  if (!di.isRegistered<TeamManager>()) {
    di.registerSingleton<TeamManager>(TeamManager());
  }

  if (!di.isRegistered<ProgressionManager>()) {
    di.registerSingleton<ProgressionManager>(ProgressionManager());
  }

  // Apply saved upgrade effects to managers
  _applyUpgradeEffects();
}

// ============================================================
// Upgrade Registration — 8 auto-battler upgrades
// Categories: auto-combat (4), team (2), progression (2)
// ============================================================

/// Upgrade category groupings for UI display.
const Map<String, List<String>> upgradeCategories = {
  'Auto-Combat': [
    AutoCombatManager.kBattleSpeed,
    AutoCombatManager.kAutoSkillChance,
    AutoCombatManager.kAiIntelligence,
    AutoCombatManager.kDamageMultiplier,
  ],
  'Team': [
    TeamManager.kTeamSize,
    TeamManager.kSynergyBonus,
  ],
  'Progression': [
    ProgressionManager.kXpMultiplier,
    ProgressionManager.kPrestigePoints,
  ],
};

/// Category display icons for the upgrade browser.
const Map<String, IconData> upgradeCategoryIcons = {
  'Auto-Combat': Icons.flash_on,
  'Team': Icons.groups,
  'Progression': Icons.trending_up,
};

void _registerUpgrades(UpgradeManager manager) {
  // ── Auto-combat upgrades (4) ──────────────────────────────

  manager.registerUpgrade(Upgrade(
    id: AutoCombatManager.kBattleSpeed,
    name: 'Battle Tempo',
    description: 'Increase battle speed by 15% per level.',
    maxLevel: 10,
    baseCost: 100,
    costMultiplier: 1.5,
    valuePerLevel: 0.15,
  ));

  manager.registerUpgrade(Upgrade(
    id: AutoCombatManager.kAutoSkillChance,
    name: 'Skill Instinct',
    description: 'Heroes gain 8% auto-cast chance per level.',
    maxLevel: 10,
    baseCost: 150,
    costMultiplier: 1.6,
    valuePerLevel: 0.08,
  ));

  manager.registerUpgrade(Upgrade(
    id: AutoCombatManager.kAiIntelligence,
    name: 'Tactical Mind',
    description: 'Improve AI targeting intelligence.',
    maxLevel: 5,
    baseCost: 200,
    costMultiplier: 1.8,
    valuePerLevel: 1.0,
  ));

  manager.registerUpgrade(Upgrade(
    id: AutoCombatManager.kDamageMultiplier,
    name: 'War Drums',
    description: 'Boost all hero damage by 10% per level.',
    maxLevel: 15,
    baseCost: 120,
    costMultiplier: 1.45,
    valuePerLevel: 0.10,
  ));

  // ── Team upgrades (2) ─────────────────────────────────────

  manager.registerUpgrade(Upgrade(
    id: TeamManager.kTeamSize,
    name: 'Army Expansion',
    description: 'Deploy one additional hero per level.',
    maxLevel: 4,
    baseCost: 300,
    costMultiplier: 2.0,
    valuePerLevel: 1.0,
  ));

  manager.registerUpgrade(Upgrade(
    id: TeamManager.kSynergyBonus,
    name: 'Bond of Heroes',
    description: 'Strengthen synergy effects by 12% per level.',
    maxLevel: 8,
    baseCost: 180,
    costMultiplier: 1.5,
    valuePerLevel: 0.12,
  ));

  // ── Progression upgrades (2) ──────────────────────────────

  manager.registerUpgrade(Upgrade(
    id: ProgressionManager.kXpMultiplier,
    name: 'Battle Wisdom',
    description: 'Increase XP gained from battles by 15% per level.',
    maxLevel: 10,
    baseCost: 80,
    costMultiplier: 1.4,
    valuePerLevel: 0.15,
  ));

  manager.registerUpgrade(Upgrade(
    id: ProgressionManager.kPrestigePoints,
    name: 'Legacy of Champions',
    description: 'Earn additional prestige points per reset.',
    maxLevel: 5,
    baseCost: 500,
    costMultiplier: 2.5,
    valuePerLevel: 1.0,
  ));
}

/// Refresh all game-specific managers so they re-read upgrade values.
void _applyUpgradeEffects() {
  GetIt.I<AutoCombatManager>().refresh();
  GetIt.I<TeamManager>().refresh();
  GetIt.I<ProgressionManager>().refresh();
}

// ============================================================
// App Root — MultiProvider wraps all game state
// ============================================================

class CardBattleApp extends StatelessWidget {
  const CardBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: GetIt.I<UpgradeManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<AutoCombatManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<TeamManager>()),
        ChangeNotifierProvider.value(value: GetIt.I<ProgressionManager>()),
      ],
      child: MaterialApp(
        title: 'Hero Auto Battle',
        theme: _buildTheme(),
        home: const MainMenuScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/upgrades': (_) => const UpgradeScreen(),
        },
      ),
    );
  }

  /// Year 1 dark theme with warm gold accents for RPG atmosphere.
  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: MGColors.year1Accent,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: MGColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: MGColors.backgroundDark,
      ),
      cardTheme: CardThemeData(
        color: MGColors.cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Upgrade Screen — full-screen upgrade browser with gold display
// ============================================================

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero Upgrades'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: MGColors.gold, size: 20),
                const SizedBox(width: 4),
                StreamBuilder<int>(
                  stream: GetIt.I<GoldManager>().onGoldChanged,
                  initialData: GetIt.I<GoldManager>().currentGold,
                  builder: (context, snapshot) {
                    return Text(
                      '${snapshot.data ?? 0}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: const UpgradeListPanel(),
    );
  }
}

// ============================================================
// Upgrade List Panel — categorized upgrade browser with purchase
// ============================================================

class UpgradeListPanel extends StatelessWidget {
  const UpgradeListPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final upgradeManager = context.watch<UpgradeManager>();
    final categories = upgradeCategories.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final icon = upgradeCategoryIcons[category.key] ?? Icons.star;
        return _buildCategorySection(
          context, category.key, icon, category.value, upgradeManager,
        );
      },
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    IconData icon,
    List<String> upgradeIds,
    UpgradeManager upgradeManager,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: MGColors.year1Accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MGColors.textHighEmphasis,
                ),
              ),
            ],
          ),
        ),
        // ── Upgrade tiles ──
        ...upgradeIds.map((id) {
          final upgrade = upgradeManager.getUpgrade(id);
          if (upgrade == null) return const SizedBox.shrink();
          return _UpgradeItemTile(upgrade: upgrade);
        }),
        const Divider(height: 1, color: MGColors.border),
      ],
    );
  }
}

// ============================================================
// Upgrade Item Tile — individual upgrade row with purchase button
// ============================================================

class _UpgradeItemTile extends StatelessWidget {
  final Upgrade upgrade;

  const _UpgradeItemTile({required this.upgrade});

  @override
  Widget build(BuildContext context) {
    final goldManager = GetIt.I<GoldManager>();
    final upgradeManager = context.read<UpgradeManager>();
    final isMaxLevel = upgrade.currentLevel >= upgrade.maxLevel;
    final canAfford = !isMaxLevel &&
        upgradeManager.canAfford(upgrade.id, goldManager.currentGold);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ── Level indicator ──
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isMaxLevel
                    ? MGColors.year1Primary.withAlpha(51)
                    : MGColors.surfaceDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isMaxLevel ? MGColors.year1Primary : MGColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  '${upgrade.currentLevel}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isMaxLevel
                        ? MGColors.year1Primary
                        : MGColors.textHighEmphasis,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // ── Name, description, and level progress ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    upgrade.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MGColors.textHighEmphasis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    upgrade.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MGColors.textMediumEmphasis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lv ${upgrade.currentLevel}/${upgrade.maxLevel}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: MGColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ── Purchase button or MAX chip ──
            if (isMaxLevel)
              const Chip(
                label: Text('MAX', style: TextStyle(fontSize: 12)),
                backgroundColor: MGColors.surfaceDark,
                side: BorderSide(color: MGColors.year1Primary),
              )
            else
              ElevatedButton(
                onPressed: canAfford
                    ? () {
                        upgradeManager.purchaseUpgrade(
                          upgrade.id,
                          () => goldManager.currentGold,
                          (cost) => goldManager.trySpendGold(cost),
                        );
                        _applyUpgradeEffects();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      size: 14,
                      color: MGColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text('${upgrade.costForNextLevel}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
