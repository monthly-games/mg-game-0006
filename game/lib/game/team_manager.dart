import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/systems/progression/upgrade_manager.dart';

/// Manages team composition limits and synergy bonuses.
///
/// Reads upgrade levels from [UpgradeManager] to compute:
/// - **Team Size** — maximum units deployable on the battle grid
/// - **Synergy Bonus** — multiplier strengthening all active synergy effects
class TeamManager extends ChangeNotifier {
  // ── Upgrade IDs (match keys registered in UpgradeManager) ──────────
  static const String kTeamSize = 'team_size';
  static const String kSynergyBonus = 'synergy_bonus';

  // ── Base values ────────────────────────────────────────────────────
  static const int _baseTeamSize = 5;
  static const double _baseSynergyMultiplier = 1.0;

  /// Maximum number of heroes deployable to the battle grid.
  int get maxTeamSize {
    final upgrade = GetIt.I<UpgradeManager>().getUpgrade(kTeamSize);
    return _baseTeamSize + (upgrade?.currentLevel ?? 0);
  }

  /// Multiplier applied to all active synergy effect values.
  ///
  /// At base (1.0) synergy effects apply at face value.
  /// Each upgrade level adds 12%, so Lv 5 → 1.60× synergy strength.
  double get synergyMultiplier {
    final upgrade = GetIt.I<UpgradeManager>().getUpgrade(kSynergyBonus);
    return _baseSynergyMultiplier + (upgrade?.currentValue ?? 0.0);
  }

  /// Check whether another unit can be deployed given [currentDeployed] count.
  bool canDeployMore(int currentDeployed) {
    return currentDeployed < maxTeamSize;
  }

  /// Recalculate derived values from current upgrade levels and notify UI.
  void refresh() {
    notifyListeners();
  }
}
