import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';

/// Manages auto-combat parameters for Hero Auto Battle.
///
/// Computes real-time combat modifiers by reading current upgrade levels
/// from [UpgradeManager]. Each parameter affects the battle simulation:
///
/// - **Battle Speed** -- tick rate multiplier for faster battles
/// - **Auto-Skill Chance** -- probability of auto-casting skills when ready
/// - **AI Intelligence** -- tier-based targeting sophistication
/// - **Damage Multiplier** -- flat damage boost for all player units
class AutoCombatManager extends ChangeNotifier {
  // ── Upgrade IDs (match keys registered in UpgradeManager) ──────────
  static const String kBattleSpeed = 'battle_speed';
  static const String kAutoSkillChance = 'auto_skill_chance';
  static const String kAiIntelligence = 'ai_intelligence';
  static const String kDamageMultiplier = 'damage_multiplier';

  // ── Base values ────────────────────────────────────────────────────
  static const double _baseBattleSpeed = 1.0;
  static const double _baseAutoSkillChance = 0.0;
  static const int _baseAiTier = 0;
  static const double _baseDamageMultiplier = 0.614;

  /// Current battle speed multiplier (1.0 = normal, 2.5 = 2.5× speed).
  double get battleSpeedMultiplier {
    final upgrade = GetIt.I<UpgradeManager>().getUpgrade(kBattleSpeed);
    return _baseBattleSpeed + (upgrade?.currentValue ?? 0.0);
  }

  /// Probability [0.0-1.0] that a unit auto-casts a skill when mana is full.
  double get autoSkillChance {
    final upgrade = GetIt.I<UpgradeManager>().getUpgrade(kAutoSkillChance);
    return (_baseAutoSkillChance + (upgrade?.currentValue ?? 0.0)).clamp(0.0, 1.0);
  }

  /// AI intelligence tier (0 = closest-first, higher = smarter targeting).
  ///
  /// Tier 0: Attack nearest enemy
  /// Tier 1: Prioritize low-HP targets
  /// Tier 2: Consider enemy threat level
  /// Tier 3: Focus healers and supports
  /// Tier 4+: Optimal target selection with synergy awareness
  int get aiIntelligenceTier {
    final upgrade = GetIt.I<UpgradeManager>().getUpgrade(kAiIntelligence);
    return _baseAiTier + (upgrade?.currentLevel ?? 0);
  }

  /// Global damage multiplier applied to all player unit attacks.
  double get damageMultiplier {
    final upgrade = GetIt.I<UpgradeManager>().getUpgrade(kDamageMultiplier);
    return _baseDamageMultiplier + (upgrade?.currentValue ?? 0.0);
  }

  /// Recalculate derived values from current upgrade levels and notify UI.
  void refresh() {
    notifyListeners();
  }
}
