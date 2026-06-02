import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mg_common_game/systems/gacha/gacha_manager.dart';
import 'package:mg_common_game/systems/gacha/gacha_pool.dart';
import '../core/hero_data.dart';
import '../core/skill_data.dart';

/// Soul Stone rarity tier for summoning
enum SoulStoneRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Summon result with hero and rarity
class SoulStoneSummonResult {
  final HeroData hero;
  final SoulStoneRarity rarity;
  final int pityCounter;

  const SoulStoneSummonResult({
    required this.hero,
    required this.rarity,
    required this.pityCounter,
  });

  @override
  String toString() => 'SoulStoneSummonResult(${hero.name}, $rarity, pity: $pityCounter)';
}

/// Soul stone summoning configuration
class SoulStoneSummonConfig {
  final SoulStoneRarity rarity;
  final int cost;
  final double baseRate;
  final int pityThreshold;

  const SoulStoneSummonConfig({
    required this.rarity,
    required this.cost,
    required this.baseRate,
    required this.pityThreshold,
  });
}

/// Soul Stone Summoning Manager for MG-0006 Hero Auto Battle
/// Manages soul stone currency, hero summoning with pity system
class SoulStoneSummonManager extends ChangeNotifier {
  // Currency
  int _soulStones = 500;

  // Pity counters
  int _legendaryPity = 0;
  int _epicPity = 0;
  int _rarePity = 0;

  // Summon statistics
  int _totalSummons = 0;
  final Map<SoulStoneRarity, int> _rarityCounts = {
    SoulStoneRarity.common: 0,
    SoulStoneRarity.rare: 0,
    SoulStoneRarity.epic: 0,
    SoulStoneRarity.legendary: 0,
  };

  // Summon configurations
  static const Map<SoulStoneRarity, SoulStoneSummonConfig> _configs = {
    SoulStoneRarity.legendary: SoulStoneSummonConfig(
      rarity: SoulStoneRarity.legendary,
      cost: 300,
      baseRate: 0.02, // 2% base rate
      pityThreshold: 50, // Guaranteed within 50 pulls
    ),
    SoulStoneRarity.epic: SoulStoneSummonConfig(
      rarity: SoulStoneRarity.epic,
      cost: 100,
      baseRate: 0.10, // 10% base rate
      pityThreshold: 20, // Guaranteed within 20 pulls
    ),
    SoulStoneRarity.rare: SoulStoneSummonConfig(
      rarity: SoulStoneRarity.rare,
      cost: 50,
      baseRate: 0.30, // 30% base rate
      pityThreshold: 10, // Guaranteed within 10 pulls
    ),
    SoulStoneRarity.common: SoulStoneSummonConfig(
      rarity: SoulStoneRarity.common,
      cost: 20,
      baseRate: 1.0, // 100% fallback
      pityThreshold: 1, // Always available
    ),
  };

  // Hero pool by rarity
  static const Map<SoulStoneRarity, List<HeroData>> _heroPool = {
    SoulStoneRarity.legendary: [
      // Top-tier heroes with highest stats
      HeroData(
        id: 'legend_001',
        name: 'Celestial Warrior',
        heroClass: HeroClass.warrior,
        element: HeroElement.wind,
        stats: HeroStats(
          maxHp: 2500,
          attack: 150,
          defense: 40,
          attackSpeed: 1.0,
          range: 1,
          moveSpeed: 250,
        ),
        assetPath: 'heroes/celestial_warrior.png',
        skill: SkillType.none,
      ),
      HeroData(
        id: 'legend_002',
        name: 'Void Mage',
        heroClass: HeroClass.mage,
        element: HeroElement.water,
        stats: HeroStats(
          maxHp: 1800,
          attack: 160,
          defense: 10,
          attackSpeed: 0.9,
          range: 3,
          moveSpeed: 200,
        ),
        assetPath: 'heroes/void_mage.png',
        skill: SkillType.none,
      ),
    ],
    SoulStoneRarity.epic: [
      HeroData(
        id: 'epic_001',
        name: 'Frost Knight',
        heroClass: HeroClass.warrior,
        element: HeroElement.water,
        stats: HeroStats(
          maxHp: 2000,
          attack: 110,
          defense: 30,
          attackSpeed: 0.85,
          range: 1,
          moveSpeed: 210,
        ),
        assetPath: 'heroes/frost_knight.png',
        skill: SkillType.none,
      ),
      HeroData(
        id: 'epic_002',
        name: 'Flame Archer',
        heroClass: HeroClass.archer,
        element: HeroElement.fire,
        stats: HeroStats(
          maxHp: 1600,
          attack: 120,
          defense: 8,
          attackSpeed: 1.3,
          range: 4,
          moveSpeed: 240,
        ),
        assetPath: 'heroes/flame_archer.png',
        skill: SkillType.none,
      ),
      HeroData(
        id: 'epic_003',
        name: 'Earth Guardian',
        heroClass: HeroClass.tank,
        element: HeroElement.earth,
        stats: HeroStats(
          maxHp: 2800,
          attack: 80,
          defense: 50,
          attackSpeed: 0.6,
          range: 1,
          moveSpeed: 160,
        ),
        assetPath: 'heroes/earth_guardian.png',
        skill: SkillType.none,
      ),
      HeroData(
        id: 'epic_004',
        name: 'Wind Dancer',
        heroClass: HeroClass.assassin,
        element: HeroElement.wind,
        stats: HeroStats(
          maxHp: 1500,
          attack: 130,
          defense: 5,
          attackSpeed: 1.9,
          range: 1,
          moveSpeed: 310,
        ),
        assetPath: 'heroes/wind_dancer.png',
        skill: SkillType.none,
      ),
    ],
    SoulStoneRarity.rare: [
      HeroData(
        id: 'rare_001',
        name: 'Iron Soldier',
        heroClass: HeroClass.tank,
        element: HeroElement.fire,
        stats: HeroStats(
          maxHp: 2200,
          attack: 60,
          defense: 35,
          attackSpeed: 0.7,
          range: 1,
          moveSpeed: 190,
        ),
        assetPath: 'heroes/iron_soldier.png',
        skill: SkillType.none,
      ),
      HeroData(
        id: 'rare_002',
        name: 'Swift Hunter',
        heroClass: HeroClass.archer,
        element: HeroElement.wind,
        stats: HeroStats(
          maxHp: 1400,
          attack: 90,
          defense: 6,
          attackSpeed: 1.4,
          range: 4,
          moveSpeed: 260,
        ),
        assetPath: 'heroes/swift_hunter.png',
        skill: SkillType.none,
      ),
      HeroData(
        id: 'rare_003',
        name: 'Water Priest',
        heroClass: HeroClass.support,
        element: HeroElement.water,
        stats: HeroStats(
          maxHp: 1600,
          attack: 50,
          defense: 12,
          attackSpeed: 1.1,
          range: 3,
          moveSpeed: 210,
        ),
        assetPath: 'heroes/water_priest.png',
        skill: SkillType.none,
      ),
      HeroData(
        id: 'rare_004',
        name: 'Light Disciple',
        heroClass: HeroClass.mage,
        element: HeroElement.wind,
        stats: HeroStats(
          maxHp: 1300,
          attack: 85,
          defense: 8,
          attackSpeed: 0.85,
          range: 3,
          moveSpeed: 200,
        ),
        assetPath: 'heroes/light_disciple.png',
        skill: SkillType.none,
      ),
      HeroData(
        id: 'rare_005',
        name: 'Dark Rogue',
        heroClass: HeroClass.assassin,
        element: HeroElement.water,
        stats: HeroStats(
          maxHp: 1200,
          attack: 95,
          defense: 4,
          attackSpeed: 1.7,
          range: 1,
          moveSpeed: 290,
        ),
        assetPath: 'heroes/dark_rogue.png',
        skill: SkillType.none,
      ),
    ],
    SoulStoneRarity.common: [
      HeroData(
        id: 'common_001',
        name: 'Militia',
        heroClass: HeroClass.warrior,
        element: HeroElement.fire,
        stats: HeroStats(
          maxHp: 1000,
          attack: 40,
          defense: 15,
          attackSpeed: 0.8,
          range: 1,
          moveSpeed: 200,
        ),
        assetPath: 'heroes/militia.png',
        skill: SkillType.none,
      ),
      HeroData(
        id: 'common_002',
        name: 'Peasant',
        heroClass: HeroClass.support,
        element: HeroElement.water,
        stats: HeroStats(
          maxHp: 900,
          attack: 30,
          defense: 10,
          attackSpeed: 1.0,
          range: 3,
          moveSpeed: 190,
        ),
        assetPath: 'heroes/peasant.png',
        skill: SkillType.none,
      ),
      HeroData(
        id: 'common_003',
        name: 'Scout',
        heroClass: HeroClass.archer,
        element: HeroElement.wind,
        stats: HeroStats(
          maxHp: 800,
          attack: 50,
          defense: 5,
          attackSpeed: 1.3,
          range: 4,
          moveSpeed: 250,
        ),
        assetPath: 'heroes/scout.png',
        skill: SkillType.none,
      ),
      HeroData(
        id: 'common_004',
        name: 'Acolyte',
        heroClass: HeroClass.mage,
        element: HeroElement.wind,
        stats: HeroStats(
          maxHp: 850,
          attack: 45,
          defense: 8,
          attackSpeed: 0.9,
          range: 3,
          moveSpeed: 200,
        ),
        assetPath: 'heroes/acolyte.png',
        skill: SkillType.none,
      ),
      HeroData(
        id: 'common_005',
        name: 'Thug',
        heroClass: HeroClass.assassin,
        element: HeroElement.water,
        stats: HeroStats(
          maxHp: 750,
          attack: 55,
          defense: 3,
          attackSpeed: 1.6,
          range: 1,
          moveSpeed: 280,
        ),
        assetPath: 'heroes/thug.png',
        skill: SkillType.none,
      ),
      HeroData(
        id: 'common_006',
        name: 'Guard',
        heroClass: HeroClass.tank,
        element: HeroElement.earth,
        stats: HeroStats(
          maxHp: 1200,
          attack: 35,
          defense: 25,
          attackSpeed: 0.6,
          range: 1,
          moveSpeed: 170,
        ),
        assetPath: 'heroes/guard.png',
        skill: SkillType.none,
      ),
    ],
  };

  final Random _random = Random();

  /// Get current soul stone balance
  int get soulStones => _soulStones;

  /// Get legendary pity counter
  int get legendaryPity => _legendaryPity;

  /// Get epic pity counter
  int get epicPity => _epicPity;

  /// Get rare pity counter
  int get rarePity => _rarePity;

  /// Get total summons
  int get totalSummons => _totalSummons;

  /// Get rarity counts
  Map<SoulStoneRarity, int> get rarityCounts => Map.unmodifiable(_rarityCounts);

  /// Calculate pity-influenced rate for a rarity
  double _getPityAdjustedRate(SoulStoneRarity rarity) {
    final config = _configs[rarity]!;
    final baseRate = config.baseRate;

    switch (rarity) {
      case SoulStoneRarity.legendary:
        // Soft pity starts at 40 pulls (2x rate increase per pull)
        if (_legendaryPity >= 40) {
          final softPityBonus = (_legendaryPity - 39) * 0.02;
          return (baseRate + softPityBonus).clamp(0.0, 1.0);
        }
        return baseRate;

      case SoulStoneRarity.epic:
        // Soft pity starts at 15 pulls (5x rate increase per pull)
        if (_epicPity >= 15) {
          final softPityBonus = (_epicPity - 14) * 0.05;
          return (baseRate + softPityBonus).clamp(0.0, 1.0);
        }
        return baseRate;

      case SoulStoneRarity.rare:
        // Soft pity starts at 7 pulls (10x rate increase per pull)
        if (_rarePity >= 7) {
          final softPityBonus = (_rarePity - 6) * 0.10;
          return (baseRate + softPityBonus).clamp(0.0, 1.0);
        }
        return baseRate;

      case SoulStoneRarity.common:
        return 1.0; // Always available
    }
  }

  /// Determine summoned rarity based on pity and rates
  SoulStoneRarity _determineRarity() {
    // Check hard pity thresholds
    if (_legendaryPity >= _configs[SoulStoneRarity.legendary]!.pityThreshold - 1) {
      return SoulStoneRarity.legendary;
    }
    if (_epicPity >= _configs[SoulStoneRarity.epic]!.pityThreshold - 1) {
      return SoulStoneRarity.epic;
    }
    if (_rarePity >= _configs[SoulStoneRarity.rare]!.pityThreshold - 1) {
      return SoulStoneRarity.rare;
    }

    // Roll for rarity (check from highest to lowest)
    final legendaryRate = _getPityAdjustedRate(SoulStoneRarity.legendary);
    if (_random.nextDouble() < legendaryRate) {
      return SoulStoneRarity.legendary;
    }

    final epicRate = _getPityAdjustedRate(SoulStoneRarity.epic);
    if (_random.nextDouble() < epicRate) {
      return SoulStoneRarity.epic;
    }

    final rareRate = _getPityAdjustedRate(SoulStoneRarity.rare);
    if (_random.nextDouble() < rareRate) {
      return SoulStoneRarity.rare;
    }

    return SoulStoneRarity.common;
  }

  /// Select a random hero from the specified rarity pool
  HeroData _selectHero(SoulStoneRarity rarity) {
    final pool = _heroPool[rarity] ?? [];
    if (pool.isEmpty) {
      // Fallback to common pool
      return _heroPool[SoulStoneRarity.common]!.first;
    }
    return pool[_random.nextInt(pool.length)];
  }

  /// Perform a single summon
  /// Returns null if player doesn't have enough soul stones
  SoulStoneSummonResult? summonSingle() {
    final cost = _configs[SoulStoneRarity.rare]!.cost; // Base cost on rare summon

    if (_soulStones < cost) {
      return null;
    }

    // Deduct cost
    _soulStones -= cost;

    // Determine rarity
    final rarity = _determineRarity();

    // Update pity counters
    _legendaryPity++;
    _epicPity++;
    _rarePity++;

    // Reset pity counters for achieved rarities and higher
    switch (rarity) {
      case SoulStoneRarity.legendary:
        _legendaryPity = 0;
        _epicPity = 0;
        _rarePity = 0;
        break;
      case SoulStoneRarity.epic:
        _epicPity = 0;
        _rarePity = 0;
        break;
      case SoulStoneRarity.rare:
        _rarePity = 0;
        break;
      case SoulStoneRarity.common:
        // No reset
        break;
    }

    // Select hero
    final hero = _selectHero(rarity);

    // Update statistics
    _totalSummons++;
    _rarityCounts[rarity] = (_rarityCounts[rarity] ?? 0) + 1;

    // Determine current pity counter for result
    int currentPity;
    switch (rarity) {
      case SoulStoneRarity.legendary:
        currentPity = _legendaryPity;
        break;
      case SoulStoneRarity.epic:
        currentPity = _epicPity;
        break;
      case SoulStoneRarity.rare:
        currentPity = _rarePity;
        break;
      case SoulStoneRarity.common:
        currentPity = 0;
        break;
    }

    notifyListeners();

    return SoulStoneSummonResult(
      hero: hero,
      rarity: rarity,
      pityCounter: currentPity,
    );
  }

  /// Perform 10x summon
  /// Returns empty list if player doesn't have enough soul stones
  List<SoulStoneSummonResult> summonTen() {
    final cost = _configs[SoulStoneRarity.rare]!.cost * 10;

    if (_soulStones < cost) {
      return [];
    }

    final results = <SoulStoneSummonResult>[];
    for (int i = 0; i < 10; i++) {
      final result = summonSingle();
      if (result != null) {
        results.add(result);
      }
    }

    return results;
  }

  /// Add soul stones to balance
  void addSoulStones(int amount) {
    _soulStones += amount;
    notifyListeners();
  }

  /// Get summon cost for a single pull
  int get singleSummonCost => _configs[SoulStoneRarity.rare]!.cost;

  /// Get summon cost for 10x pull
  int get tenSummonCost => _configs[SoulStoneRarity.rare]!.cost * 10;

  /// Get pulls until pity for each rarity
  Map<SoulStoneRarity, int> get pullsUntilPity {
    return {
      SoulStoneRarity.legendary: _configs[SoulStoneRarity.legendary]!.pityThreshold - _legendaryPity,
      SoulStoneRarity.epic: _configs[SoulStoneRarity.epic]!.pityThreshold - _epicPity,
      SoulStoneRarity.rare: _configs[SoulStoneRarity.rare]!.pityThreshold - _rarePity,
    };
  }

  /// Get summon statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalSummons': _totalSummons,
      'legendaryCount': _rarityCounts[SoulStoneRarity.legendary] ?? 0,
      'epicCount': _rarityCounts[SoulStoneRarity.epic] ?? 0,
      'rareCount': _rarityCounts[SoulStoneRarity.rare] ?? 0,
      'commonCount': _rarityCounts[SoulStoneRarity.common] ?? 0,
      'legendaryPity': _legendaryPity,
      'epicPity': _epicPity,
      'rarePity': _rarePity,
      'soulStones': _soulStones,
    };
  }

  /// Reset pity counters (for testing or special events)
  void resetPity() {
    _legendaryPity = 0;
    _epicPity = 0;
    _rarePity = 0;
    notifyListeners();
  }

  /// Get manager state for save/load
  Map<String, dynamic> toJson() {
    return {
      'soulStones': _soulStones,
      'legendaryPity': _legendaryPity,
      'epicPity': _epicPity,
      'rarePity': _rarePity,
      'totalSummons': _totalSummons,
      'rarityCounts': {
        'common': _rarityCounts[SoulStoneRarity.common],
        'rare': _rarityCounts[SoulStoneRarity.rare],
        'epic': _rarityCounts[SoulStoneRarity.epic],
        'legendary': _rarityCounts[SoulStoneRarity.legendary],
      },
    };
  }

  /// Load manager state
  void loadFromJson(Map<String, dynamic> json) {
    _soulStones = json['soulStones'] as int? ?? 500;
    _legendaryPity = json['legendaryPity'] as int? ?? 0;
    _epicPity = json['epicPity'] as int? ?? 0;
    _rarePity = json['rarePity'] as int? ?? 0;
    _totalSummons = json['totalSummons'] as int? ?? 0;

    final counts = json['rarityCounts'] as Map<String, dynamic>? ?? {};
    _rarityCounts[SoulStoneRarity.common] = counts['common'] as int? ?? 0;
    _rarityCounts[SoulStoneRarity.rare] = counts['rare'] as int? ?? 0;
    _rarityCounts[SoulStoneRarity.epic] = counts['epic'] as int? ?? 0;
    _rarityCounts[SoulStoneRarity.legendary] = counts['legendary'] as int? ?? 0;

    notifyListeners();
  }
}
