import 'hero_data.dart';

class WaveData {
  final int round;
  final List<WaveEnemy> enemies;
  final int rewardGold;

  const WaveData({
    required this.round,
    required this.enemies,
    required this.rewardGold,
  });
}

class WaveEnemy {
  final HeroData data;
  final int r;
  final int c;
  final int starLevel; // For stats scaling (1=Base, 2=Stronger)

  const WaveEnemy(this.data, this.r, this.c, {this.starLevel = 1});
}

// Initial Waves (5 Rounds)
// Positions based on enemy side (Right side: cols 4,5 usually)
// Grid is 8 rows x 6 cols. Enemy side is roughly cols 3-5?
// Let's assume player uses left (0-2), enemy uses right (3-5).
// Rows 0-7.

final List<WaveData> initialWaves = [
  // Round 1: Simple 1v1 or 1v2 Weak
  WaveData(
    round: 1,
    enemies: [
      WaveEnemy(initialHeroes[0], 3, 4), // Warrior
    ],
    rewardGold: 2,
  ),
  // Round 2: 2 Enemies
  WaveData(
    round: 2,
    enemies: [
      WaveEnemy(initialHeroes[0], 2, 4), // Warrior
      WaveEnemy(initialHeroes[1], 4, 4), // Archer
    ],
    rewardGold: 3,
  ),
  // Round 3: Tank + DPS
  WaveData(
    round: 3,
    enemies: [
      WaveEnemy(initialHeroes[0], 3, 3, starLevel: 1), // Frontline
      WaveEnemy(initialHeroes[3], 2, 5), // Ranger back
      WaveEnemy(initialHeroes[3], 4, 5), // Ranger back
    ],
    rewardGold: 4,
  ),
  // Round 4: Mages
  WaveData(
    round: 4,
    enemies: [
      WaveEnemy(initialHeroes[6], 2, 4), // Fire Sorc
      WaveEnemy(initialHeroes[7], 4, 4), // Ice Wizard
      WaveEnemy(initialHeroes[0], 3, 3, starLevel: 2), // Tankier Warrior
    ],
    rewardGold: 5,
  ),
  // Round 5: Elite Challenge
  WaveData(
    round: 5,
    enemies: [
      WaveEnemy(
        initialHeroes[0],
        2,
        4,
        starLevel: 2,
      ), // Elite Berserker (Warrior)
      WaveEnemy(initialHeroes[1], 0, 5, starLevel: 1), // Archer
      WaveEnemy(initialHeroes[6], 4, 5, starLevel: 1), // Mage (Fire Sorc)
    ],
    rewardGold: 5,
  ),
  // Round 6: Swarm
  WaveData(
    round: 6,
    enemies: [
      WaveEnemy(initialHeroes[0], 1, 3, starLevel: 1), // Warrior
      WaveEnemy(initialHeroes[0], 2, 3, starLevel: 1), // Warrior
      WaveEnemy(initialHeroes[0], 3, 3, starLevel: 1), // Warrior
      WaveEnemy(initialHeroes[1], 1, 5, starLevel: 1), // Archer
      WaveEnemy(initialHeroes[1], 3, 5, starLevel: 1), // Archer
    ],
    rewardGold: 6,
  ),
  // Round 7: Tank & Spank
  WaveData(
    round: 7,
    enemies: [
      WaveEnemy(initialHeroes[0], 2, 3, starLevel: 2), // Big Golem (Warrior)
      WaveEnemy(initialHeroes[1], 0, 6, starLevel: 2), // Sniper (Archer)
      WaveEnemy(initialHeroes[7], 4, 6, starLevel: 2), // Ice Wizard
    ],
    rewardGold: 7,
  ),
  // Round 8: Assassin Strike
  WaveData(
    round: 8,
    enemies: [
      WaveEnemy(initialHeroes[0], 2, 3, starLevel: 2), // Tank (Warrior)
      WaveEnemy(initialHeroes[9], 0, 2, starLevel: 2), // Flank? (Assassin)
      WaveEnemy(initialHeroes[9], 4, 2, starLevel: 2), // Flank? (Assassin)
    ],
    rewardGold: 8,
  ),
  // Round 9: High Synergy
  WaveData(
    round: 9,
    enemies: [
      WaveEnemy(initialHeroes[0], 2, 3, starLevel: 2), // Warrior
      WaveEnemy(initialHeroes[6], 1, 5, starLevel: 2), // Mage (Fire Sorc)
      WaveEnemy(initialHeroes[6], 3, 5, starLevel: 2), // Mage (Fire Sorc)
      WaveEnemy(initialHeroes[8], 2, 6, starLevel: 3), // Healer (Cleric)
    ],
    rewardGold: 9,
  ),
  // Round 10: BOSS BATTLE
  WaveData(
    round: 10,
    enemies: [
      WaveEnemy(initialHeroes[0], 2, 4, starLevel: 3), // BOSS GOLEM (Warrior)
      WaveEnemy(initialHeroes[6], 0, 6, starLevel: 3), // Mage (Fire Sorc)
      WaveEnemy(initialHeroes[6], 4, 6, starLevel: 3), // Mage (Fire Sorc)
    ],
    rewardGold: 20,
  ),
];
