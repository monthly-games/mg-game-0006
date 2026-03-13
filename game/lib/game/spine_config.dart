import 'package:mg_common_game/core/assets/asset_types.dart';

/// Spine 통합 플래그. `--dart-define=SPINE_ENABLED=true`로 활성화.
const kSpineEnabled = bool.fromEnvironment(
  'SPINE_ENABLED',
  defaultValue: false,
);

// ── Battle Hero ──────────────────────────────────────────────

const kBattleHeroMeta = SpineAssetMeta(
  key: 'battle_hero',
  path: 'spine/characters/battle_hero',
  atlasPath:
      'assets/spine/characters/battle_hero/battle_hero.atlas',
  skeletonPath:
      'assets/spine/characters/battle_hero/battle_hero.skel',
  animations: ['idle', 'walk', 'attack', 'hit'],
  defaultAnimation: 'idle',
  defaultMix: 0.2,
);

// ── Battle Mage ──────────────────────────────────────────────

const kBattleMageMeta = SpineAssetMeta(
  key: 'battle_mage',
  path: 'spine/characters/battle_mage',
  atlasPath:
      'assets/spine/characters/battle_mage/battle_mage.atlas',
  skeletonPath:
      'assets/spine/characters/battle_mage/battle_mage.skel',
  animations: ['idle', 'walk', 'attack', 'hit'],
  defaultAnimation: 'idle',
  defaultMix: 0.2,
);

// ── Battle Assassin ──────────────────────────────────────────

const kBattleAssassinMeta = SpineAssetMeta(
  key: 'battle_assassin',
  path: 'spine/characters/battle_assassin',
  atlasPath:
      'assets/spine/characters/battle_assassin/battle_assassin.atlas',
  skeletonPath:
      'assets/spine/characters/battle_assassin/battle_assassin.skel',
  animations: ['idle', 'walk', 'attack', 'hit'],
  defaultAnimation: 'idle',
  defaultMix: 0.2,
);
