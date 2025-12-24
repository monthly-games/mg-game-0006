import 'skill_data.dart';

enum HeroClass { warrior, archer, mage, assassin, tank, support }

enum HeroElement { fire, water, earth, wind }

class HeroStats {
  final int maxHp;
  final int attack;
  final int defense;
  final double attackSpeed; // Attacks per second
  final int range; // Grid distance (1 = melee)
  final double moveSpeed; // Grid cells per second

  const HeroStats({
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.attackSpeed,
    required this.range,
    required this.moveSpeed,
  });
}

class HeroData {
  final String id;
  final String name;
  final HeroClass heroClass;
  final HeroElement element;
  final HeroStats stats;
  final String assetPath; // Path to sprite/spine
  final SkillType skill; // Active Skill

  const HeroData({
    required this.id,
    required this.name,
    required this.heroClass,
    required this.element,
    required this.stats,
    required this.assetPath,
    this.skill = SkillType.none,
  });
}

// Initial Data Set - EXPANDED VOLUMNE
const List<HeroData> initialHeroes = [
  // --- WARRIORS ---
  HeroData(
    id: 'warrior_1',
    name: 'Iron Guard',
    heroClass: HeroClass
        .warrior, // Changed from tank to warrior for synergy simplicity
    element: HeroElement.earth,
    stats: HeroStats(
      maxHp: 1000,
      attack: 50,
      defense: 20,
      attackSpeed: 0.8,
      range: 1,
      moveSpeed: 200,
    ),
    assetPath: 'heroes/warrior.png',
  ),
  HeroData(
    id: 'warrior_2',
    name: 'Berserker',
    heroClass: HeroClass.warrior,
    element: HeroElement.fire,
    stats: HeroStats(
      maxHp: 800,
      attack: 80,
      defense: 10,
      attackSpeed: 1.2,
      range: 1,
      moveSpeed: 250,
    ),
    assetPath: 'heroes/berserker.png',
  ),
  HeroData(
    id: 'warrior_3',
    name: 'Paladin',
    heroClass: HeroClass.warrior,
    element: HeroElement.wind, // Fast movement
    stats: HeroStats(
      maxHp: 1200,
      attack: 40,
      defense: 30,
      attackSpeed: 0.7,
      range: 1,
      moveSpeed: 180,
    ),
    assetPath: 'heroes/paladin.png',
  ),

  // --- ARCHERS ---
  HeroData(
    id: 'archer_1',
    name: 'Elven Ranger',
    heroClass: HeroClass.archer,
    element: HeroElement.wind,
    stats: HeroStats(
      maxHp: 400,
      attack: 90,
      defense: 5,
      attackSpeed: 1.2,
      range: 4,
      moveSpeed: 250,
    ),
    assetPath: 'heroes/archer.png',
    skill: SkillType.rapidFire,
  ),
  HeroData(
    id: 'archer_2',
    name: 'Sniper',
    heroClass: HeroClass.archer,
    element: HeroElement.fire, // High dmg
    stats: HeroStats(
      maxHp: 350,
      attack: 130,
      defense: 0,
      attackSpeed: 0.8,
      range: 6,
      moveSpeed: 200,
    ),
    assetPath: 'heroes/sniper.png',
  ),
  HeroData(
    id: 'archer_3',
    name: 'Crossbowman',
    heroClass: HeroClass.archer,
    element: HeroElement.earth,
    stats: HeroStats(
      maxHp: 500,
      attack: 70,
      defense: 10,
      attackSpeed: 1.5,
      range: 3,
      moveSpeed: 220,
    ),
    assetPath: 'heroes/crossbow.png',
  ),

  // --- MAGES ---
  HeroData(
    id: 'mage_1',
    name: 'Fire Sorcerer',
    heroClass: HeroClass.mage,
    element: HeroElement.fire,
    stats: HeroStats(
      maxHp: 350,
      attack: 120,
      defense: 0,
      attackSpeed: 0.6,
      range: 3,
      moveSpeed: 180,
    ),
    assetPath: 'heroes/mage.png',
  ),
  HeroData(
    id: 'mage_2',
    name: 'Ice Wizard',
    heroClass: HeroClass.mage,
    element: HeroElement.water,
    stats: HeroStats(
      maxHp: 400,
      attack: 100,
      defense: 5,
      attackSpeed: 0.7,
      range: 3,
      moveSpeed: 190,
    ),
    assetPath: 'heroes/ice_wizard.png',
  ),
  HeroData(
    id: 'mage_3',
    name: 'Storm Caller',
    heroClass: HeroClass.mage,
    element: HeroElement.wind,
    stats: HeroStats(
      maxHp: 380,
      attack: 110,
      defense: 2,
      attackSpeed: 0.9,
      range: 3,
      moveSpeed: 200,
    ),
    assetPath: 'heroes/storm.png',
  ),

  // --- ASSASSINS ---
  HeroData(
    id: 'assassin_1',
    name: 'Shadow Blade',
    heroClass: HeroClass.assassin,
    element: HeroElement.water,
    stats: HeroStats(
      maxHp: 450,
      attack: 140,
      defense: 0,
      attackSpeed: 1.8,
      range: 1,
      moveSpeed: 300,
    ),
    assetPath: 'heroes/ninja.png',
    skill: SkillType.backstab,
  ),

  // --- TANKS ---
  HeroData(
    id: 'tank_1',
    name: 'Stone Golem',
    heroClass: HeroClass.tank,
    element: HeroElement.earth,
    stats: HeroStats(
      maxHp: 1500,
      attack: 30,
      defense: 50,
      attackSpeed: 0.5,
      range: 1,
      moveSpeed: 150,
    ),
    assetPath: 'heroes/golem.png',
    skill: SkillType.taunt,
  ),
  HeroData(
    id: 'tank_2',
    name: 'Royal Guard',
    heroClass: HeroClass.tank,
    element: HeroElement.wind, // Need for Speed? No, maybe just synergy filler
    stats: HeroStats(
      maxHp: 1200,
      attack: 40,
      defense: 40,
      attackSpeed: 0.8,
      range: 1,
      moveSpeed: 180,
    ),
    assetPath: 'heroes/knight.png', // Reuse knight asset for now
    skill: SkillType.shield,
  ),

  // --- SUPPORTS ---
  HeroData(
    id: 'support_1',
    name: 'High Priest',
    heroClass: HeroClass.support,
    element: HeroElement.water,
    stats: HeroStats(
      maxHp: 600,
      attack: 20,
      defense: 10,
      attackSpeed: 1.0,
      range: 3,
      moveSpeed: 200,
    ),
    assetPath: 'heroes/priest.png',
    skill: SkillType.heal,
  ),
];
