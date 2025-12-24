enum SkillType {
  none,
  powerStrike, // Warrior: High dmg single target
  rapidFire, // Archer: Temp attack speed boost
  fireNova, // Mage: AoE Damage
  heal, // Cleric: Heal ally
  taunt, // Tank: Force enemies to target self
  shield, // Tank: Gain temporary HP
  backstab, // Assassin: High single target dmg (teleport?)
}

class SkillData {
  final String id;
  final String name;
  final SkillType type;
  final int manaCost;
  final double value; // Dmg multiplier, Heal amount, Duration etc.

  const SkillData({
    required this.id,
    required this.name,
    required this.type,
    this.manaCost = 100,
    required this.value,
  });
}

const Map<SkillType, SkillData> skillRegistry = {
  SkillType.powerStrike: SkillData(
    id: 'power_strike',
    name: 'Power Strike',
    type: SkillType.powerStrike,
    value: 2.5, // 250% Dmg
  ),
  SkillType.rapidFire: SkillData(
    id: 'rapid_fire',
    name: 'Rapid Fire',
    type: SkillType.rapidFire,
    value: 3.0, // 3 seconds duration? Or speed mult? Let's say +200% AS for 3s
  ),
  SkillType.fireNova: SkillData(
    id: 'fire_nova',
    name: 'Fire Nova',
    type: SkillType.fireNova,
    value: 100.0, // 100 Flat Dmg AoE
  ),
  SkillType.heal: SkillData(
    id: 'heal',
    name: 'Divine Light',
    type: SkillType.heal,
    value: 200.0,
  ),
  SkillType.taunt: SkillData(
    id: 'taunt',
    name: 'Taunt',
    type: SkillType.taunt,
    value: 3.0, // Duration
  ),
  SkillType.shield: SkillData(
    id: 'shield',
    name: 'Iron Skin',
    type: SkillType.shield,
    value: 300.0, // Shield Amount
  ),
  SkillType.backstab: SkillData(
    id: 'backstab',
    name: 'Assassinate',
    type: SkillType.backstab,
    value: 4.0, // 400% Dmg
  ),
};
