import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';

/// Manages player progression, leveling, and prestige mechanics.
///
/// Tracks player level, XP accumulation, and prestige cycles. Reads
/// upgrade levels from [UpgradeManager] to compute:
/// - **XP Multiplier** — bonus XP rate from battles
/// - **Prestige Points** — additional points earned per prestige reset
class ProgressionManager extends ChangeNotifier {
  // ── Upgrade IDs (match keys registered in UpgradeManager) ──────────
  static const String kXpMultiplier = 'xp_multiplier';
  static const String kPrestigePoints = 'prestige_points';

  // ── Base values ────────────────────────────────────────────────────
  static const double _baseXpMultiplier = 1.0;
  static const int _basePrestigeBonus = 0;
  static const int _minPrestigeLevel = 10;
  static const int _baseXpPerLevel = 100;

  // ── Player state ──────────────────────────────────────────────────
  int _playerLevel = 1;
  int _currentXp = 0;
  int _totalPrestigePoints = 0;
  int _prestigeCount = 0;

  int get playerLevel => _playerLevel;
  int get currentXp => _currentXp;
  int get totalPrestigePoints => _totalPrestigePoints;
  int get prestigeCount => _prestigeCount;

  /// XP required to reach the next level (scales linearly with level).
  int get xpToNextLevel => _baseXpPerLevel * _playerLevel;

  /// Progress fraction [0.0–1.0] toward the next level.
  double get levelProgress {
    final needed = xpToNextLevel;
    if (needed <= 0) return 0.0;
    return (_currentXp / needed).clamp(0.0, 1.0);
  }

  /// Whether the player meets the minimum level for prestige.
  bool get canPrestige => _playerLevel >= _minPrestigeLevel;

  /// XP gain multiplier based on upgrade level.
  ///
  /// Base is 1.0×. Each upgrade level adds 15%, so Lv 10 → 2.5× XP.
  double get xpMultiplier {
    final upgrade = GetIt.I<UpgradeManager>().getUpgrade(kXpMultiplier);
    return _baseXpMultiplier + (upgrade?.currentValue ?? 0.0);
  }

  /// Bonus prestige points earned per prestige reset.
  ///
  /// Base is 0. Each upgrade level adds 1 bonus point per reset.
  int get bonusPrestigePoints {
    final upgrade = GetIt.I<UpgradeManager>().getUpgrade(kPrestigePoints);
    return _basePrestigeBonus + (upgrade?.currentLevel ?? 0);
  }

  /// Award XP after a battle, applying the [xpMultiplier].
  /// Automatically levels up when XP exceeds the threshold.
  void gainXp(int baseAmount) {
    _currentXp += (baseAmount * xpMultiplier).round();
    while (_currentXp >= xpToNextLevel) {
      _currentXp -= xpToNextLevel;
      _playerLevel++;
    }
    notifyListeners();
  }

  /// Perform a prestige reset: sacrifices current level for prestige points.
  ///
  /// Requires [canPrestige] to be true (minimum level 10).
  /// Awards `playerLevel + bonusPrestigePoints` prestige points.
  void prestige() {
    if (!canPrestige) return;
    final earned = _playerLevel + bonusPrestigePoints;
    _totalPrestigePoints += earned;
    _prestigeCount++;
    _playerLevel = 1;
    _currentXp = 0;
    notifyListeners();
  }

  /// Recalculate derived values from current upgrade levels and notify UI.
  void refresh() {
    notifyListeners();
  }
}
