import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/economy/gold_manager.dart';
import '../core/hero_unit.dart';

enum TeamRole { tank, damage, support, control, hybrid }

class TeamCompositionBonus {
  final String name;
  final String description;
  final int requiredHeroes;
  final double hpMultiplier;
  final double atkMultiplier;
  final double skillCooldownReduction;

  const TeamCompositionBonus({
    required this.name,
    required this.description,
    required this.requiredHeroes,
    this.hpMultiplier = 1.0,
    this.atkMultiplier = 1.0,
    this.skillCooldownReduction = 0.0,
  });
}

class TeamCompositionManager extends ChangeNotifier {
  final GoldManager _goldManager = GetIt.I<GoldManager>();
  final List<HeroUnit> _activeTeam = [];
  final List<HeroUnit> _reserveTeam = [];

  List<HeroUnit> get activeTeam => _activeTeam;
  List<HeroUnit> get reserveTeam => _reserveTeam;

  static const int maxTeamSize = 5;

  // Composition bonuses
  static const Map<String, TeamCompositionBonus> compositionBonuses = {
    'balanced': TeamCompositionBonus(
      name: '균형 잡힌 팀',
      description: '모든 역할이 포함된 균형 잡힌 팀',
      requiredHeroes: 4,
      hpMultiplier: 1.1,
      atkMultiplier: 1.1,
    ),
    'tank_squad': TeamCompositionBonus(
      name: '탱크 부대',
      description: '방어력 증가',
      requiredHeroes: 3,
      hpMultiplier: 1.3,
    ),
    'damage_squad': TeamCompositionBonus(
      name: '공격 부대',
      description: '공격력 증가',
      requiredHeroes: 3,
      atkMultiplier: 1.25,
    ),
    'support_squad': TeamCompositionBonus(
      name: '서포트 부대',
      description: '스킬 쿨다운 감소',
      requiredHeroes: 2,
      skillCooldownReduction: 0.15,
    ),
    'full_team': TeamCompositionBonus(
      name: '완벽한 팀',
      description: '모든 슬롯이 채워짐',
      requiredHeroes: 5,
      hpMultiplier: 1.15,
      atkMultiplier: 1.15,
      skillCooldownReduction: 0.1,
    ),
  };

  TeamCompositionManager() {
    _initializeDefaultTeam();
  }

  void _initializeDefaultTeam() {
    // Initialize with 1 basic hero if none exist
    if (_activeTeam.isEmpty) {
      // Add default starter hero
    }
  }

  bool addToTeam(HeroUnit hero) {
    if (_activeTeam.length >= maxTeamSize) return false;
    if (_activeTeam.any((h) => h.id == hero.id)) return false;

    _activeTeam.add(hero);
    _reserveTeam.removeWhere((h) => h.id == hero.id);
    notifyListeners();
    return true;
  }

  bool removeFromTeam(String heroId) {
    final hero = _activeTeam.firstWhere(
      (h) => h.id == heroId,
      orElse: () => _activeTeam.first,
    );

    _activeTeam.removeWhere((h) => h.id == heroId);
    _reserveTeam.add(hero);
    notifyListeners();
    return true;
  }

  bool swapTeamMembers(String heroId1, String heroId2) {
    final idx1 = _activeTeam.indexWhere((h) => h.id == heroId1);
    final idx2 = _activeTeam.indexWhere((h) => h.id == heroId2);

    if (idx1 == -1 || idx2 == -1) return false;

    final temp = _activeTeam[idx1];
    _activeTeam[idx1] = _activeTeam[idx2];
    _activeTeam[idx2] = temp;

    notifyListeners();
    return true;
  }

  List<TeamCompositionBonus> getActiveBonuses() {
    final bonuses = <TeamCompositionBonus>[];

    if (_activeTeam.length < 3) return bonuses;

    final roles = _activeTeam.map((h) => _getHeroRole(h)).toSet();

    // Check each composition type
    if (roles.length >= 4 && _activeTeam.length >= 4) {
      bonuses.add(compositionBonuses['balanced']!);
    }

    final tankCount = roles.where((r) => r == TeamRole.tank).length;
    if (tankCount >= 3) {
      bonuses.add(compositionBonuses['tank_squad']!);
    }

    final damageCount = roles.where((r) => r == TeamRole.damage).length;
    if (damageCount >= 3) {
      bonuses.add(compositionBonuses['damage_squad']!);
    }

    final supportCount = roles.where((r) => r == TeamRole.support).length;
    if (supportCount >= 2) {
      bonuses.add(compositionBonuses['support_squad']!);
    }

    if (_activeTeam.length >= maxTeamSize) {
      bonuses.add(compositionBonuses['full_team']!);
    }

    return bonuses;
  }

  double getTotalHpMultiplier() {
    double multiplier = 1.0;
    for (var bonus in getActiveBonuses()) {
      multiplier *= bonus.hpMultiplier;
    }
    return multiplier;
  }

  double getTotalAtkMultiplier() {
    double multiplier = 1.0;
    for (var bonus in getActiveBonuses()) {
      multiplier *= bonus.atkMultiplier;
    }
    return multiplier;
  }

  double getTotalCooldownReduction() {
    double reduction = 0.0;
    for (var bonus in getActiveBonuses()) {
      reduction += bonus.skillCooldownReduction;
    }
    return reduction.clamp(0.0, 0.5);
  }

  TeamRole _getHeroRole(HeroUnit hero) {
    // Determine role based on hero stats/type
    if (hero.defense >= 15) return TeamRole.tank;
    if (hero.attack >= 20) return TeamRole.damage;
    if (hero.maxHp >= 120) return TeamRole.support;
    return TeamRole.hybrid;
  }

  Map<TeamRole, int> getTeamRoleDistribution() {
    final distribution = <TeamRole, int>{};
    for (var role in TeamRole.values) {
      distribution[role] = 0;
    }

    for (var hero in _activeTeam) {
      final role = _getHeroRole(hero);
      distribution[role] = (distribution[role] ?? 0) + 1;
    }

    return distribution;
  }

  List<String> getTeamCompositionTips() {
    final tips = <String>[];
    final roles = getTeamRoleDistribution();
    final currentSize = _activeTeam.length;

    if (currentSize < maxTeamSize) {
      tips.add('팀에 영웅을 더 추가하세요 (${currentSize}/$maxTeamSize)');
    }

    if (roles[TeamRole.tank] == 0) {
      tips.add('탱커 영웅을 추가하여 팀의 생존력을 높이세요');
    }

    if (roles[TeamRole.damage] == 0) {
      tips.add('딜러 영웅을 추가하여 DPS를 높이세요');
    }

    if (roles[TeamRole.support] == 0) {
      tips.add('서포터 영웅을 추가하여 버프를 받으세요');
    }

    if (getActiveBonuses().isEmpty) {
      tips.add('역할 조합을 맞춰 보너스를 받으세요');
    }

    return tips;
  }

  bool canAddToTeam() {
    return _activeTeam.length < maxTeamSize;
  }

  int getEmptySlots() {
    return maxTeamSize - _activeTeam.length;
  }
}
