import 'hero_data.dart';
import 'item_data.dart';

class HeroEntity {
  final String instanceId;
  final HeroData data;
  final bool isPlayer; // True if player unit, False if enemy

  // Runtime State
  int currentHp;
  int row;
  int col;

  // Synergy Bonuses
  int bonusAttack = 0;
  int bonusDefense = 0;
  double bonusAttackSpeedPercent = 0.0;

  double attackCooldownTimer = 0.0;
  bool lootProcessed = false;
  bool isDead = false;

  int _lastDamageTick = 0; // For visual flash
  int get lastDamageTick => _lastDamageTick;

  // Mana System
  double currentMana = 0.0;
  double get maxMana => 100.0; // Fixed for now

  // Equipment
  List<ItemData> equipment = [];

  void equip(ItemData item) {
    if (equipment.length < 3) {
      equipment.add(item);
    }
  }

  int get derivedAttack {
    int itemBonus = equipment.fold(0, (sum, item) => sum + item.stats.attack);
    return data.stats.attack + bonusAttack + itemBonus;
  }

  int get derivedDefense {
    int itemBonus = equipment.fold(0, (sum, item) => sum + item.stats.defense);
    return data.stats.defense + bonusDefense + itemBonus;
  }

  double get derivedAttackSpeed {
    double itemBonus = equipment.fold(
      0.0,
      (sum, item) => sum + item.stats.attackSpeed,
    );
    return data.stats.attackSpeed * (1 + bonusAttackSpeedPercent + itemBonus);
  }

  HeroEntity({
    required this.instanceId,
    required this.data,
    required this.isPlayer,
    required this.row,
    required this.col,
  }) : currentHp = data.stats.maxHp;

  void takeDamage(int amount) {
    if (isDead) return;

    int actualDamage = (amount - derivedDefense).clamp(0, amount);
    if (actualDamage > 0) {
      currentHp -= actualDamage;
      _lastDamageTick = DateTime.now().millisecondsSinceEpoch;
    }

    if (currentHp <= 0) {
      currentHp = 0;
      isDead = true;
    }
  }

  void update(double dt) {
    if (isDead) return;

    if (attackCooldownTimer > 0) {
      attackCooldownTimer -= dt;
    }
  }

  bool canAttack() {
    return !isDead && attackCooldownTimer <= 0;
  }

  void resetAttackCooldown() {
    attackCooldownTimer = 0.0;
    _lastDamageTick = 0;
    currentMana = 0.0;
  }
}
