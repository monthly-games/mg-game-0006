import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// MG UI 기반 오토배틀 HUD
/// mg_common_game의 공통 UI 컴포넌트 활용
///
/// Navigation buttons (top-right): BattlePass (trophy), Gacha (star)
/// These navigate to full-screen retention system UIs.
class MGBattleHud extends StatelessWidget {
  final int gold;
  final int wave;
  final int maxWave;
  final int playerHp;
  final int playerMaxHp;
  final int enemyHp;
  final int enemyMaxHp;
  final double battleSpeed;
  final VoidCallback? onPause;
  final VoidCallback? onSpeedChange;
  final int unclaimedBattlePassRewards;
  final VoidCallback? onDailyHub;
  final VoidCallback? onGuildWar;
  final VoidCallback? onTournament;
  final VoidCallback? onSeasonalEvent;

  const MGBattleHud({
    super.key,
    required this.gold,
    this.wave = 1,
    this.maxWave = 10,
    this.playerHp = 100,
    this.playerMaxHp = 100,
    this.enemyHp = 100,
    this.enemyMaxHp = 100,
    this.battleSpeed = 1.0,
    this.onPause,
    this.onSpeedChange,
    this.unclaimedBattlePassRewards = 0,
    this.onDailyHub,
    this.onGuildWar,
    this.onTournament,
    this.onSeasonalEvent,
  });

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;

    return Positioned.fill(
      child: Column(
        children: [
          // 상단 HUD: 웨이브 + 골드
          Container(
            padding: EdgeInsets.only(
              top: safeArea.top + MGSpacing.hudMargin,
              left: safeArea.left + MGSpacing.hudMargin,
              right: safeArea.right + MGSpacing.hudMargin,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWaveInfo(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // BattlePass navigation -- trophy icon
                    _RetentionNavButton(
                      icon: Icons.emoji_events,
                      tooltip: 'BattlePass',
                      badgeCount: unclaimedBattlePassRewards,
                      onPressed: () => Navigator.of(context)
                          .pushNamed('/battlepass'),
                    ),
                    SizedBox(width: MGSpacing.xs),
                    // Gacha navigation -- star icon
                    _RetentionNavButton(
                      icon: Icons.auto_awesome,
                      tooltip: 'Gacha',
                      onPressed: () => Navigator.of(context)
                          .pushNamed('/gacha'),
                    ),
                    SizedBox(width: MGSpacing.sm),
                    MGResourceBar(
                      icon: Icons.monetization_on,
                      value: _formatNumber(gold),
                      iconColor: MGColors.gold,
                      onTap: null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          MGSpacing.vSm,

          // HP 바들
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: safeArea.left + MGSpacing.hudMargin,
            ),
            child: Row(
              children: [
                Expanded(child: _buildPlayerHpBar()),
                MGSpacing.hMd,
                const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                MGSpacing.hMd,
                Expanded(child: _buildEnemyHpBar()),
              ],
            ),
          ),

          // 중앙 영역 확장 (배틀 필드)
          const Expanded(child: SizedBox()),
          // Spine 캐릭터
          _buildSpineCharacter(),
          const SizedBox(height: 50),

          // 하단 HUD: 컨트롤
          Container(
            padding: EdgeInsets.only(
              bottom: safeArea.bottom + MGSpacing.hudMargin,
              left: safeArea.left + MGSpacing.hudMargin,
              right: safeArea.right + MGSpacing.hudMargin,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
        if (onGuildWar != null)
          MGIconButton(
            icon: Icons.shield,
            onPressed: onGuildWar,
            size: 44,
            backgroundColor: MGColors.info.withValues(alpha: 0.8),
            color: MGColors.textHighEmphasis,
            tooltip: 'Guild War',
          ),
        MGSpacing.hXs,
        if (onTournament != null)
          MGIconButton(
            icon: Icons.emoji_events,
            onPressed: onTournament,
            size: 44,
            backgroundColor: MGColors.info.withValues(alpha: 0.8),
            color: MGColors.textHighEmphasis,
            tooltip: 'Tournament',
          ),
        MGSpacing.hXs,
        if (onSeasonalEvent != null)
          MGIconButton(
            icon: Icons.celebration,
            onPressed: onSeasonalEvent,
            size: 44,
            backgroundColor: MGColors.info.withValues(alpha: 0.8),
            color: MGColors.textHighEmphasis,
            tooltip: 'Seasonal Event',
          ),
        MGSpacing.hXs,
        if (onDailyHub != null)
          MGIconButton(
            icon: Icons.calendar_today,
            onPressed: onDailyHub,
            size: 44,
            backgroundColor: MGColors.info.withValues(alpha: 0.8),
            color: MGColors.textHighEmphasis,
            tooltip: 'Daily Hub',
          ),
        MGSpacing.hXs,
                if (onPause != null)
                  MGIconButton(
                    icon: Icons.pause,
                    onPressed: onPause,
                    size: 44,
                    backgroundColor: Colors.black54,
                    color: Colors.white,
                  ),
                _buildSpeedControl(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MGColors.warning.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.flag,
            color: Colors.amber,
            size: 20,
          ),
          MGSpacing.hXs,
          Text(
            'Wave $wave/$maxWave',
            style: MGTextStyles.hud.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHpBar() {
    final percentage = playerMaxHp > 0 ? playerHp / playerMaxHp : 0.0;
    final isLow = percentage <= 0.25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PLAYER',
          style: MGTextStyles.caption.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: MGSpacing.xxs),
        MGLinearProgress(
          value: percentage,
          height: 12,
          valueColor: isLow ? MGColors.error : Colors.green,
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          borderRadius: 6,
        ),
      ],
    );
  }

  Widget _buildEnemyHpBar() {
    final percentage = enemyMaxHp > 0 ? enemyHp / enemyMaxHp : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'ENEMY',
          style: MGTextStyles.caption.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: MGSpacing.xxs),
        MGLinearProgress(
          value: percentage,
          height: 12,
          valueColor: Colors.red,
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          borderRadius: 6,
        ),
      ],
    );
  }

  Widget _buildSpeedControl() {
    return GestureDetector(
      onTap: onSpeedChange,
      child: Container(
        padding: const EdgeInsets.all(MGSpacing.xs),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              battleSpeed > 1.0 ? Icons.fast_forward : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: MGSpacing.xxs),
            Text(
              '${battleSpeed.toStringAsFixed(0)}x',
              style: MGTextStyles.caption.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildSpineCharacter() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.withAlpha(150), width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 24, color: Colors.white),
            SizedBox(height: 2),
            Text(
              'Battle Commander',
              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Retention Nav Button -- HUD shortcut to BattlePass / Gacha
// ============================================================

class _RetentionNavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final int badgeCount;
  final VoidCallback? onPressed;

  const _RetentionNavButton({
    required this.icon,
    required this.tooltip,
    this.badgeCount = 0,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: MGColors.year1Accent.withValues(alpha: 0.4),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  icon,
                  color: MGColors.year1Accent,
                  size: 22,
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(MGSpacing.xxs),
                    decoration: const BoxDecoration(
                      color: MGColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: MGColors.textHighEmphasis,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}
