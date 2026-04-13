import 'dart:math';
import '../core/hero_data.dart';

/// Shop Item - represents a hero available for purchase
class ShopItem {
  final String id;
  final String name;
  final int cost;
  final HeroData? heroData; // Associated hero data if this is a hero
  final HeroClass? heroClass;
  final HeroElement? element;

  ShopItem({
    required this.id,
    required this.name,
    required this.cost,
    this.heroData,
    this.heroClass,
    this.element,
  });

  /// Create a ShopItem from HeroData
  factory ShopItem.fromHero(HeroData hero) {
    // BALANCE FIX: Hero costs based on tier (50-150 gold range)
    // - Lower stats (under 60 attack): 50 gold
    // - Medium stats (60-100 attack): 75-100 gold
    // - High stats (100+ attack): 125-150 gold
    int cost;
    if (hero.stats.attack < 60) {
      cost = 50;
    } else if (hero.stats.attack < 100) {
      cost = 75;
    } else {
      cost = 100;
    }

    // Tanks and supports cost more due to utility
    if (hero.heroClass == HeroClass.tank || hero.heroClass == HeroClass.support) {
      cost += 25;
    }

    return ShopItem(
      id: hero.id,
      name: hero.name,
      cost: cost,
      heroData: hero,
      heroClass: hero.heroClass,
      element: hero.element,
    );
  }

  @override
  String toString() => 'ShopItem($name, $cost gold)';
}

/// Shop Manager for MG-0006 Auto-Battler
/// Manages hero shop, rerolls, and player inventory (bench/field)
class ShopManager {
  // Available hero pool for random selection
  static const List<HeroData> _heroPool = initialHeroes;

  // Current shop offerings (5 heroes at a time)
  final List<ShopItem> _currentShop = [];

  // Player inventory
  final List<ShopItem> _bench = []; // Player's bench (up to 8 heroes)
  final List<ShopItem> _field = []; // Player's field (up to 5 heroes)

  // Shop state
  int _gold = 100;
  int _rerollCost = 2;
  final Random _random = Random();

  // Constants
  static const int maxBenchSize = 8;
  static const int maxFieldSize = 5;
  static const int shopSize = 5;

  /// Initialize ShopManager with starting gold and initial shop
  ShopManager({int startingGold = 100}) : _gold = startingGold {
    initialize();
  }

  /// Get current shop items
  List<ShopItem> get currentShop => List.unmodifiable(_currentShop);

  /// Get items in player's bench
  List<ShopItem> get bench => List.unmodifiable(_bench);

  /// Get items in player's field
  List<ShopItem> get field => List.unmodifiable(_field);

  /// Get current gold
  int get gold => _gold;

  /// Get reroll cost
  int get rerollCost => _rerollCost;

  /// Initialize shop with first batch of heroes
  void initialize() {
    _refreshShop();
  }

  /// Refresh shop with new random heroes
  /// BALANCE FIX: Reroll cost is 2 gold (affordable but not spamable)
  void refreshShop() {
    if (_gold < _rerollCost) {
      return; // Can't afford reroll
    }
    _gold -= _rerollCost;
    _refreshShop();
  }

  /// Internal: Refresh the shop with random heroes
  void _refreshShop() {
    _currentShop.clear();

    // Pick 5 random heroes from the pool
    final availableHeroes = List<HeroData>.from(_heroPool);
    availableHeroes.shuffle(_random);

    for (int i = 0; i < shopSize && i < availableHeroes.length; i++) {
      _currentShop.add(ShopItem.fromHero(availableHeroes[i]));
    }
  }

  /// Buy a hero from the shop
  /// Returns true if purchase successful
  bool buyHero(int shopIndex) {
    if (shopIndex < 0 || shopIndex >= _currentShop.length) {
      return false;
    }

    final item = _currentShop[shopIndex];

    if (_gold < item.cost) {
      return false; // Can't afford
    }

    if (_bench.length >= maxBenchSize) {
      return false; // Bench full
    }

    // Complete purchase
    _gold -= item.cost;
    final purchasedItem = _currentShop.removeAt(shopIndex);
    _bench.add(purchasedItem);

    return true;
  }

  /// Move hero from bench to field
  bool moveToField(int benchIndex) {
    if (benchIndex < 0 || benchIndex >= _bench.length) {
      return false;
    }

    if (_field.length >= maxFieldSize) {
      return false; // Field full
    }

    final item = _bench.removeAt(benchIndex);
    _field.add(item);
    return true;
  }

  /// Move hero from field to bench
  bool moveToBench(int fieldIndex) {
    if (fieldIndex < 0 || fieldIndex >= _field.length) {
      return false;
    }

    if (_bench.length >= maxBenchSize) {
      return false; // Bench full
    }

    final item = _field.removeAt(fieldIndex);
    _bench.add(item);
    return true;
  }

  /// Sell a hero from bench (get 50% of value back)
  bool sellHero(int benchIndex) {
    if (benchIndex < 0 || benchIndex >= _bench.length) {
      return false;
    }

    final item = _bench.removeAt(benchIndex);
    final sellValue = (item.cost / 2).floor();
    _gold += sellValue;
    return true;
  }

  /// Add gold (e.g., from round rewards)
  void addGold(int amount) {
    _gold += amount;
  }

  /// Get total team power (sum of all heroes on field)
  int getTeamPower() {
    return _field.fold(0, (sum, item) {
      if (item.heroData != null) {
        return sum + item.heroData!.stats.attack + item.heroData!.stats.maxHp ~/ 10;
      }
      return sum;
    });
  }

  /// Get team composition by class
  Map<HeroClass, int> getTeamComposition() {
    final composition = <HeroClass, int>{};
    for (final item in _field) {
      if (item.heroClass != null) {
        composition[item.heroClass!] = (composition[item.heroClass!] ?? 0) + 1;
      }
    }
    return composition;
  }

  /// Get team composition by element
  Map<HeroElement, int> getTeamElements() {
    final elements = <HeroElement, int>{};
    for (final item in _field) {
      if (item.element != null) {
        elements[item.element!] = (elements[item.element!] ?? 0) + 1;
      }
    }
    return elements;
  }

  /// Clear all data (for new run)
  void clear() {
    _currentShop.clear();
    _bench.clear();
    _field.clear();
    _gold = 100;
    _refreshShop();
  }

  /// Get shop state for save/load
  Map<String, dynamic> toJson() {
    return {
      'gold': _gold,
      'rerollCost': _rerollCost,
      'bench': _bench.map((item) => item.id).toList(),
      'field': _field.map((item) => item.id).toList(),
    };
  }

  /// Load shop state
  void loadFromJson(Map<String, dynamic> json) {
    _gold = json['gold'] as int? ?? 100;
    _rerollCost = json['rerollCost'] as int? ?? 2;

    _bench.clear();
    _field.clear();

    final benchIds = json['bench'] as List<dynamic>? ?? [];
    final fieldIds = json['field'] as List<dynamic>? ?? [];

    for (final id in benchIds) {
      final hero = _heroPool.where((h) => h.id == id.toString()).firstOrNull;
      if (hero != null) {
        _bench.add(ShopItem.fromHero(hero));
      }
    }

    for (final id in fieldIds) {
      final hero = _heroPool.where((h) => h.id == id.toString()).firstOrNull;
      if (hero != null) {
        _field.add(ShopItem.fromHero(hero));
      }
    }

    _refreshShop();
  }
}
