import 'package:flutter/material.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';

/// MG UI 기반 오토배틀 HUD
/// mg_common_game의 공통 UI 컴포넌트 활용
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
                MGResourceBar(
                  icon: Icons.monetization_on,
                  value: _formatNumber(gold),
                  iconColor: MGColors.gold,
                  onTap: null,
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
        const SizedBox(height: 4),
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
        const SizedBox(height: 4),
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
        padding: const EdgeInsets.all(8),
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
            const SizedBox(width: 4),
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
}
