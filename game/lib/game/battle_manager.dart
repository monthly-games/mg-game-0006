import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'core/hero_data.dart';
import 'core/hero_entity.dart';
import 'core/battle_grid.dart';
import 'core/synergy_data.dart';
import 'core/wave_data.dart';
import 'core/projectile_entity.dart';
import 'core/skill_data.dart';
import 'core/item_data.dart';
import 'audio_manager.dart';

enum BattleState { preparation, battle, ended }

class BattleManager extends ChangeNotifier {
  BattleState _state = BattleState.preparation;
  BattleState get state => _state;

  final BattleGrid grid = BattleGrid();
  final List<HeroEntity> _allHeroes = [];

  final List<HeroEntity> _benchUnits = [];

  List<HeroEntity> get heroes => List.unmodifiable(_allHeroes);
  List<HeroEntity> get bench => List.unmodifiable(_benchUnits);

  // Economy
  int gold = 50;
  List<HeroData> shop = [];
  final Random _random = Random();

  // Time management
  double _battleTime = 0.0;
  Timer? _gameTimer;

  // Wave / Round
  int currentRoundIndex = 0;
  int get currentRound => currentRoundIndex + 1;
  int get maxRounds => initialWaves.length;

  // Win/Loss
  bool? playerWon;

  BattleManager() {
    _initializeTestBattle();
    _refreshShop(); // Free initial shop
  }

  void rerollShop() {
    if (gold < 2) return;
    gold -= 2;
    _refreshShop();
  }

  void _refreshShop() {
    shop = List.generate(5, (index) {
      return initialHeroes[_random.nextInt(initialHeroes.length)];
    });
    notifyListeners();
  }

  void buyUnit(HeroData data) {
    if (gold >= 3 && _state == BattleState.preparation) {
      // Flat cost 3 for MVP
      if (_benchUnits.length < 8) {
        // Max bench size
        gold -= 3;
        shop.remove(data); // Remove bought unit
        addToBench(data);
        AudioManager().playSfx('audio/sfx_buy.mp3');
        // Don't notify here, addToBench does it
      }
    }
  }

  void _initializeTestBattle() {
    // Add some test units to Bench
    addToBench(initialHeroes[0]); // Warrior
    addToBench(initialHeroes[1]); // Archer

    _loadWave(0);
  }

  void _loadWave(int index) {
    if (index >= initialWaves.length) {
      // Game Cleared? For MVP just loop last wave or stop
      index = initialWaves.length - 1;
    }
    currentRoundIndex = index;

    // Clear existing enemies
    final enemiesToRemove = _allHeroes.where((h) => !h.isPlayer).toList();
    for (var e in enemiesToRemove) {
      grid.clearCell(e.row, e.col);
      _allHeroes.remove(e);
    }
    projectiles.clear();

    // Spawn new enemies
    final wave = initialWaves[index];
    for (var enemy in wave.enemies) {
      addEnemyUnit(enemy.data, enemy.r, enemy.c, starLevel: enemy.starLevel);
    }

    notifyListeners();
  }

  void addToBench(HeroData data) {
    if (_state != BattleState.preparation) return;

    final id =
        "${data.id}_${DateTime.now().millisecondsSinceEpoch}_${_benchUnits.length}";
    // Bench units have -1 coordinates
    _benchUnits.add(
      HeroEntity(instanceId: id, data: data, isPlayer: true, row: -1, col: -1),
    );
    notifyListeners();
  }

  void addEnemyUnit(HeroData data, int r, int c, {int starLevel = 1}) {
    final id = "${data.id}_enemy_${DateTime.now().millisecondsSinceEpoch}";
    final hero = HeroEntity(
      instanceId: id,
      data: data,
      isPlayer: false,
      row: r,
      col: c,
    );
    // Apply Star Level Logic (Simple stat boost)
    if (starLevel > 1) {
      hero.bonusAttack = (data.stats.attack * 0.5 * (starLevel - 1)).round();
      hero.bonusDefense = (data.stats.defense * 0.5 * (starLevel - 1)).round();
      hero.currentHp = (data.stats.maxHp * (1 + 0.5 * (starLevel - 1))).round();
      // Note: hero.data.stats.maxHp is static base.
      // We should ideally have maxHp in entity or modify curHp to be > max?
      // For MVP, UI bar checks current/max. If current > max, bar might look weird.
      // Let's just keep HP standard but high Def/Atk for now to avoid UI rework or Entity refactor
      // Actually, let's just cheat and not boost HP for now, or just accept >100% bar.
      // Better: boost HP and ignore max constraint visual for now.
    }

    if (grid.getCell(r, c)?.isEmpty ?? false) {
      grid.placeUnit(r, c, id);
      _allHeroes.add(hero);
      _calculateSynergies(); // Update synergies
      notifyListeners();
    }
  }

  // Move from Bench to Grid
  void deployUnit(HeroEntity unit, int r, int c) {
    if (_state != BattleState.preparation) return;
    if (!grid.isValid(r, c)) return;

    // If target occupied, swap or return
    if (grid.getCell(r, c)?.isEmpty ?? false) {
      _benchUnits.remove(unit);
      unit.row = r;
      unit.col = c;
      grid.placeUnit(r, c, unit.instanceId);
      _allHeroes.add(unit);
      _calculateSynergies();
      notifyListeners();
    }
  }

  // Move from Grid to Bench
  void recallUnit(HeroEntity unit) {
    if (_state != BattleState.preparation) return;

    grid.clearCell(unit.row, unit.col);
    _allHeroes.remove(unit);

    unit.row = -1;
    unit.col = -1;
    _benchUnits.add(unit);
    _calculateSynergies();
    notifyListeners();
  }

  // Move on Grid
  void moveUnitOnGrid(HeroEntity unit, int r, int c) {
    if (_state != BattleState.preparation) return;

    if (grid.getCell(r, c)?.isEmpty ?? false) {
      grid.clearCell(unit.row, unit.col);
      unit.row = r;
      unit.col = c;
      grid.placeUnit(r, c, unit.instanceId);
      _calculateSynergies();
      notifyListeners();
    }
  }

  // Projectiles
  final List<ProjectileEntity> projectiles = [];

  // Inventory
  final List<ItemData> inventory = [
    allItems[0], // Sword
    allItems[1], // Armor
    allItems[2], // Bow
  ];

  void addItemToInventory(ItemData item) {
    if (inventory.length < 10) {
      inventory.add(item);
      notifyListeners();
    }
  }

  void equipItem(HeroEntity hero, ItemData item) {
    if (inventory.contains(item)) {
      // Check slots? For MVP unlimited or max 3
      if (hero.equipment.length < 3) {
        inventory.remove(item);
        hero.equip(item);
        notifyListeners();
      }
    }
  }

  // Synergies
  List<ActiveSynergy> activeSynergies = [];

  // --- Synergy Logic ---

  void _calculateSynergies() {
    activeSynergies.clear();

    // Count units by class (Player units only)
    final classCounts = <HeroClass, int>{};
    for (var hero in _allHeroes) {
      if (hero.isPlayer && !hero.isDead) {
        classCounts[hero.data.heroClass] =
            (classCounts[hero.data.heroClass] ?? 0) + 1;
      }
    }

    // Check thresholds
    for (var synergy in allSynergies) {
      HeroClass? targetClass;
      if (synergy.id == 'warrior') targetClass = HeroClass.warrior;
      if (synergy.id == 'archer') targetClass = HeroClass.archer;
      if (synergy.id == 'mage') targetClass = HeroClass.mage;

      if (targetClass != null) {
        int count = classCounts[targetClass] ?? 0;
        int highestThreshold = 0;
        for (var t in synergy.thresholds.keys) {
          if (count >= t && t > highestThreshold) {
            highestThreshold = t;
          }
        }

        if (highestThreshold > 0) {
          activeSynergies.add(ActiveSynergy(synergy, count, highestThreshold));
        }
      }
    }
    notifyListeners();
  }

  void _applyBattleStartBuffs() {
    _calculateSynergies();

    // Reset bonuses
    for (var h in _allHeroes) {
      h.bonusAttack = 0;
      h.bonusDefense = 0;
      h.bonusAttackSpeedPercent = 0.0;
    }

    for (var synergy in activeSynergies) {
      if (synergy.data.id == 'warrior') {
        int defBonus = synergy.activeThreshold >= 5 ? 50 : 20;
        for (var h in _allHeroes) {
          if (h.isPlayer && h.data.heroClass == HeroClass.warrior) {
            h.bonusDefense += defBonus;
          }
        }
      }
      if (synergy.data.id == 'archer') {
        double asBonus = synergy.activeThreshold >= 5 ? 0.6 : 0.25;
        for (var h in _allHeroes) {
          if (h.isPlayer && h.data.heroClass == HeroClass.archer) {
            h.bonusAttackSpeedPercent += asBonus;
            h.resetAttackCooldown(); // Refresh speed
          }
        }
      }
      if (synergy.data.id == 'mage') {
        int atkBonus = synergy.activeThreshold >= 5 ? 80 : 30;
        for (var h in _allHeroes) {
          if (h.isPlayer && h.data.heroClass == HeroClass.mage) {
            h.bonusAttack += atkBonus;
          }
        }
      }
    }
  }

  // --- Battle Logic ---

  void startBattle() {
    if (_state == BattleState.preparation) {
      _applyBattleStartBuffs(); // Apply Synergies
      _state = BattleState.battle;
      _battleTime = 0;

      // Reset cooldowns
      for (var h in _allHeroes) {
        h.resetAttackCooldown();
      }

      AudioManager().playBgm('audio/bgm_battle.mp3');

      _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        _update(0.1); // 100ms tick
      });

      notifyListeners();
    }
  }

  void _update(double dt) {
    if (_state != BattleState.battle) return;

    _battleTime += dt;
    bool stateChanged = false;

    // 0. Update Projectiles
    for (int i = projectiles.length - 1; i >= 0; i--) {
      projectiles[i].update(dt);
      if (projectiles[i].hasHit) {
        projectiles.removeAt(i);
        stateChanged = true; // Update UI for hit/removal
      }
    }

    // 1. Update Cooldowns & check for Death
    for (var hero in _allHeroes) {
      hero.update(dt);
      if (hero.isDead && hero.currentHp <= -999) {
        // Already processed death?
        // We need a flag 'isDeadProcessed'. Or just check if just died.
        // HeroEntity.isDead is true when HP <= 0.
        // Let's add 'processedDeath' field or just do it once.
        // Actually, BattleManager removes dead units cleanup?
        // No, we modify _allHeroes list?
        // Ideally we remove them?
        // For now, let's process loot if !isPlayer.
        // We need to ensure we only loot ONCE.
      }
    }

    // Better way: Check for dead units and remove them?
    // Or keep them as corpses?
    // Implementation Plan: Remove dead units from list after animation?
    // Current code keeps them in list but ignores them in target finding.

    // Let's look for *newly* dead units.
    // Hack: we don't have previous frame state.
    // Let's modify HeroEntity to have `bool lootDropped = false`?
    // Or just run `_handleLoot` inside `takeDamage`? No, logic separation.

    // Correct approach:
    // Iterate and Process Death
    for (var hero in _allHeroes) {
      if (hero.isDead && !hero.isPlayer && !hero.lootProcessed) {
        _handleLoot(hero);
        hero.lootProcessed = true;
      }
    }

    // 2. Action Phase (Attack or Move)
    for (var hero in _allHeroes) {
      if (hero.isDead) continue;

      // AI Logic: Find Target
      HeroEntity? target = _findBestTarget(hero);

      if (target != null) {
        double dist = _calculateDistance(hero, target);

        // Attack if in range
        if (dist <= hero.data.stats.range) {
          if (hero.canAttack()) {
            _performAttack(hero, target);
            stateChanged = true;
          }
        } else {
          // Move if not in range (Simple: 1 step per sec approx)
          // For MVP, move every 1 second of accumulated movement time?
          // Simplified: Logic tick movement rate check could be here
          // Let's just move 1 tile if we haven't attacked recently for smoothness
          // Or separate move timer. For MVP, move every 0.5s if unchecked
          if (_battleTime % 0.5 < 0.1) {
            // Hacky throttled movement
            _moveTowards(hero, target);
            stateChanged = true;
          }
        }
      }
    }

    // 3. Check Win Condition
    int playerCount = _allHeroes.where((h) => h.isPlayer && !h.isDead).length;
    // Check for Win
    bool enemiesAlive = _allHeroes.any((h) => !h.isPlayer && !h.isDead);
    if (!enemiesAlive) {
      _endBattle(true);
    } else {
      // Check for Loss
      bool playersAlive = _allHeroes.any((h) => h.isPlayer && !h.isDead);
      if (!playersAlive) {
        _endBattle(false);
      }
    }
  }

  void _handleLoot(HeroEntity enemy) {
    final rand = Random();
    // Basic: 10% chance
    // Boss/Elite (Star Level > 1): Higher chance
    double chance = 0.15;
    if (enemy.data.stats.maxHp > 1000) {
      chance = 1.0; // Boss check hack
    } else if (enemy.row == 2 && enemy.col == 4) {
      chance = 0.5; // Elite pos hack
    }

    if (rand.nextDouble() < chance) {
      // Drop!
      final item = allItems[rand.nextInt(allItems.length)];
      addItemToInventory(item);
      AudioManager().playSfx('audio/sfx_buy.mp3'); // Reuse coin sound
      debugPrint("LOOT! Dropped ${item.name}");
    }
  }

  HeroEntity? _findBestTarget(HeroEntity source) {
    HeroEntity? bestTarget;
    double bestScore = double.negativeInfinity;

    for (var target in _allHeroes) {
      if (target.isPlayer == source.isPlayer || target.isDead) continue;

      double score = 0;
      double distance = _calculateDistance(source, target);

      // Base: Prefer closer targets
      score -= distance;

      // Role Modifications
      if (source.data.heroClass == HeroClass.assassin) {
        // Assassins prefer furthest targets (Backline) or Low HP/Def
        // Let's implement Backline priority: Row difference?
        // Actually, in auto battlers, Assassins jump to back.
        // We can simulate this by heavily penalizing distance LESS, or inverting distance score?
        // Let's prioritize Lowest HP (Squishies)
        score -=
            (target.currentHp / target.data.stats.maxHp) *
            50; // heavily weight low HP %
        score += (20 - distance); // Prefer *furthest*? No, closest squishy?
        // "Jump to backline" usually implies ignoring front line.
        // Let's try: Score = Distance from *Opposite Edge*?
        // Simpler: Prioritize Lowest Defense (Mages/Archers)
        score -= target.derivedDefense * 2;
      } else if (source.data.heroClass == HeroClass.tank) {
        // Tanks just want to grab aggro, nearest is fine.
        // Maybe prioritize High Attack enemies to soak dmg?
        score += target.derivedAttack * 0.5;
      }

      if (score > bestScore) {
        bestScore = score;
        bestTarget = target;
      }
    }
    return bestTarget;
  }

  double _calculateDistance(HeroEntity a, HeroEntity b) {
    // Chebyshev distance for grid movement (or Euclidean?)
    // Using Manhattan for simplicity in grid logic
    return (a.row - b.row).abs() + (a.col - b.col).abs().toDouble();
  }

  void _tryCastSkill(HeroEntity caster, HeroEntity? target) {
    if (caster.data.skill == SkillType.none) return;

    final skill = skillRegistry[caster.data.skill];
    if (skill == null) return;

    caster.currentMana = 0; // Consume Mana

    // Skill Effects
    switch (skill.type) {
      case SkillType.powerStrike:
        if (target != null && !target.isDead) {
          int dmg = (caster.derivedAttack * skill.value).toInt();
          target.takeDamage(dmg);
          debugPrint(
            "${caster.data.name} casts ${skill.name} on ${target.data.name}!",
          );
          // Visual Effect?
        }
        break;
      case SkillType.rapidFire:
        if (target != null && !target.isDead) {
          for (int i = 0; i < 3; i++) {
            bool isMage = caster.data.heroClass == HeroClass.mage;
            projectiles.add(
              ProjectileEntity(
                id: "skill_${caster.instanceId}_$i",
                type: isMage ? ProjectileType.fireball : ProjectileType.arrow,
                target: target,
                x: caster.col.toDouble(),
                y: caster.row.toDouble(),
                damage: (caster.derivedAttack * 0.8),
                speed: 8.0 + i,
              ),
            );
          }
        }
        break;
      case SkillType.fireNova:
        if (target != null) {
          for (var h in _allHeroes) {
            if (h.isPlayer != caster.isPlayer && !h.isDead) {
              double dist = _calculateDistance(target, h);
              if (dist <= 2.0) {
                h.takeDamage(
                  skill.value.toInt() + (caster.derivedAttack * 0.5).toInt(),
                );
              }
            }
          }
        }
        break;
      case SkillType.heal:
        HeroEntity? ally;
        double minHp = 1.0;
        for (var h in _allHeroes) {
          if (h.isPlayer == caster.isPlayer && !h.isDead) {
            double pct = h.currentHp / h.data.stats.maxHp;
            if (pct <= minHp) {
              minHp = pct;
              ally = h;
            }
          }
        }
        if (ally != null) {
          ally.currentHp = (ally.currentHp + skill.value.toInt()).clamp(
            0,
            ally.data.stats.maxHp,
          );
          AudioManager().playSfx('audio/sfx_heal.mp3');
        }
        break;
      case SkillType.taunt:
        // Let's do: Heal Self + Def Buff + Taunt Effect (Conceptually)
        // Simple: Heal 200 + Def +50
        caster.currentHp = (caster.currentHp + 200).clamp(
          0,
          caster.data.stats.maxHp,
        );
        caster.bonusDefense += 50;
        // Ideally revert after duration, but for MVP permanent stack? Or timed?
        // Let's keep it simple: Instant Heal + Permanent small Def buff (stacking)
        debugPrint("${caster.data.name} Taunts!");
        break;
      case SkillType.shield:
        // Add Temp HP? Or just massive heal.
        // Let's do: Add 'Shield' variable to HeroEntity later?
        // For now: Heal + Shield Visual (Visual only?)
        // Let's just Heal widely or Heal Self massive
        caster.currentHp = (caster.currentHp + skill.value.toInt()).clamp(
          0,
          caster.data.stats.maxHp,
        );
        break;
      case SkillType.backstab:
        if (target != null) {
          // Teleport behind?
          // Just massive damage
          target.takeDamage((caster.derivedAttack * skill.value).toInt());
        }
        break;
      default:
        break;
    }
  }

  void _performAttack(HeroEntity attacker, HeroEntity target) {
    // Logic
    // Check if ranged
    bool isRanged = attacker.data.stats.range > 1;

    if (isRanged) {
      // Projectile
      bool isMage = attacker.data.heroClass == HeroClass.mage;
      projectiles.add(
        ProjectileEntity(
          id: "${attacker.instanceId}_${DateTime.now().millisecondsSinceEpoch}",
          type: isMage ? ProjectileType.fireball : ProjectileType.arrow,
          target: target,
          x: attacker.col.toDouble(),
          y: attacker.row.toDouble(),
          damage: attacker.derivedAttack.toDouble(),
          speed: 8.0,
        ),
      );
      AudioManager().playSfx('audio/sfx_shoot.mp3');
    } else {
      // Melee
      target.takeDamage(attacker.derivedAttack);
      AudioManager().playSfx('audio/sfx_hit.mp3');
    }

    // Mana Gain on Hit
    target.currentMana = (target.currentMana + 5).clamp(0, target.maxMana);
    attacker.currentMana = (attacker.currentMana + 10).clamp(
      0,
      attacker.maxMana,
    );

    // Check Skill Trigger (Simple Auto Cast at Max Mana)
    if (attacker.currentMana >= attacker.maxMana) {
      _tryCastSkill(attacker, target);
    }

    attacker
        .resetAttackCooldown(); // Uses derived speed internally if logic updated

    // Visual log (can be event stream later)
    debugPrint("${attacker.data.name} attacks ${target.data.name}!");
  }

  void _moveTowards(HeroEntity mover, HeroEntity target) {
    // Very dumb pathfinding: Reduce largest difference
    int dRow = target.row - mover.row;
    int dCol = target.col - mover.col;

    int newRow = mover.row;
    int newCol = mover.col;

    if (dRow.abs() > dCol.abs()) {
      newRow += dRow.sign;
    } else {
      newCol += dCol.sign;
    }

    // Check collision
    if (grid.getCell(newRow, newCol)?.isEmpty ?? false) {
      // Update Grid
      grid.clearCell(mover.row, mover.col);
      mover.row = newRow;
      mover.col = newCol;
      grid.placeUnit(mover.row, mover.col, mover.instanceId);
    }
  }

  void _endBattle(bool playerWon) {
    _state = BattleState.ended;
    this.playerWon = playerWon;
    _gameTimer?.cancel();

    if (playerWon) {
      // Wave cleared logic
      // Give Reward
      int reward = initialWaves[currentRoundIndex].rewardGold;
      // Interest calculation (1 gold per 10 held, max 5)
      int interest = (gold / 10).floor().clamp(0, 5);
      gold += reward + interest;

      // Prepare Next Round
      if (currentRoundIndex < initialWaves.length - 1) {
        // Auto advance to prep for next round?
        // Or wait for user to click "Next Round" on Result Screen?
        // Currently UI shows "Restart". Let's change state to 'preparation' immediately?
        // No, let's show Victory screen, then user clicks "Next Wave"
      } else {
        // Game Complete
      }
    } else {
      // Defeat
    }

    notifyListeners();
  }

  void sellHero(HeroEntity hero) {
    if (_state != BattleState.preparation) {
      return; // Can only sell in prep? Or anytime? Usually keys are locked in battle.
    }
    // Refund 70% or flat 2 gold?
    // Cost is 3. Refund 2.
    gold.value += 2;
    // Remove
    grid.clearCell(hero.row, hero.col);
    _allHeroes.remove(hero);
    // Also remove from bench? Bench not implemented fully as separate list, just 0,x row?
    // Assuming _allHeroes contains everyone.
    // If equipment? Refund items?
    // MVP: Items destroyed or returned to inventory?
    // Let's return items to inventory.
    for (var item in hero.equippedItems) {
      if (inventory.length < 10) {
        inventory.add(item);
      }
    }
    notifyListeners();
  }

  void sellItem(ItemData item) {
    // Sell item from inventory
    if (inventory.contains(item)) {
      gold.value += (item.cost * 0.5).toInt(); // 50% refund
      inventory.remove(item);
      notifyListeners();
    }
  }

  void _calculateInterest() {
    int interest = (gold.value / 10).floor();
    if (interest > 5) interest = 5;
    if (interest > 0) {
      gold.value += interest;
      debugPrint("Earned $interest Gold Interest!");
    }
  }

  void nextWave() {
    if (currentRoundIndex < initialWaves.length - 1) {
      _state = BattleState.preparation;
      _loadWave(currentRoundIndex + 1);
      // Heal all units? Or persistent HP?
      // Auto Battlers usually reset HP between rounds.
      for (var h in _allHeroes) {
        if (h.isPlayer) {
          h.currentHp = h.data.stats.maxHp;
          h.isDead = false;
          // Respawn dead units?
          if (grid.getCell(h.row, h.col)?.occupantId != h.instanceId &&
              h.row != -1) {
            if (grid.getCell(h.row, h.col)?.isEmpty ?? true) {
              grid.placeUnit(h.row, h.col, h.instanceId);
            } else {
              // Cell taken? (Unlikely if only player units remain)
              // Fallback: move to bench if stuck
              addToBench(h.data); // Logic break: recreating entity.
              // Better: Just set place if empty.
            }
          }
        }
      }
      _refreshShop(); // New shop for new round
      notifyListeners();
    }
  }
}
