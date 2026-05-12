// ============================================================
// Gacha Screen -- MG-0006 Hero Auto Battle
// Genre: RPG Auto Battler · Retention System UI
//
// Firebase Analytics Events:
//   - gacha_screen_opened:  Screen view tracking
//   - gacha_pull:           {pool_id, pull_count, currency_spent} single/multi
//   - gacha_pool_selected:  {pool_id} pool tab change
//   - gacha_history_viewed: History/collection tab opened
//
// Template: This file is the canonical template for 47 remaining games.
// ============================================================import 'package:mg_common_game/l10n/localization.dart';


import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import 'package:mg_common_game/core/ui/widgets/gacha/gacha_pull_animation.dart';
import 'package:mg_common_game/systems/gacha/gacha_manager.dart';
import 'package:mg_common_game/systems/gacha/gacha_pool.dart';

/// Gacha pull costs (game-specific tuning constants).
const int _kSinglePullCost = 160;
const int _kMultiPullCost = 1600;
const int _kMultiPullCount = 10;

/// Full-screen Gacha UI with pool selection, currency display,
/// pull buttons, animated results, pity indicator, and history.
///
/// Access pattern: `GetIt.I<GachaManager>()` registered in main.dart.
/// Uses mg_common_game shared widgets: [GachaPullAnimation],
/// [GachaPullButton], [GachaPityIndicator].
class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen>
    with SingleTickerProviderStateMixin {
  late final GachaManager _gachaManager;
  late final TabController _tabController;

  // Firebase Analytics: cached instance for event logging
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Current state
  String? _selectedPoolId;
  List<GachaResult>? _pullResults;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _gachaManager = GetIt.I<GachaManager>();
    _tabController = TabController(length: 2, vsync: this);
    _gachaManager.addListener(_onGachaChanged);

    // Select first active pool
    final pools = _gachaManager.activePools;
    if (pools.isNotEmpty) {
      _selectedPoolId = pools.first.id;
    }

    // Firebase Analytics: screen_view event
    _analytics.logEvent(
      name: 'gacha_screen_opened',
      parameters: {
        'pool_count': _gachaManager.activePools.length,
        'selected_pool': _selectedPoolId ?? 'none',
      },
    );
  }

  @override
  void dispose() {
    _gachaManager.removeListener(_onGachaChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onGachaChanged() {
    if (mounted) setState(() {});
  }

  GachaPool? get _currentPool {
    if (_selectedPoolId == null) return null;
    return _gachaManager.activePools
        .where((p) => p.id == _selectedPoolId)
        .firstOrNull;
  }

  // ── Firebase Event: Single pull ──────────────────────────
  Future<void> _onSinglePull() async {
    if (_selectedPoolId == null || _isAnimating) return;

    final result = _gachaManager.pull(_selectedPoolId!);
    if (result == null) return;

    setState(() {
      _pullResults = [result];
      _isAnimating = true;
    });

    await _analytics.logEvent(
      name: 'gacha_pull',
      parameters: {
        'pool_id': _selectedPoolId!,
        'pull_count': 1,
        'currency_spent': _kSinglePullCost,
        'result_rarity': result.item.rarity.nameKr,
        'is_pity_triggered': result.isPityTriggered,
      },
    );
  }

  // ── Firebase Event: Multi pull (10x) ─────────────────────
  Future<void> _onMultiPull() async {
    if (_selectedPoolId == null || _isAnimating) return;

    final results = _gachaManager.multiPull(
      _selectedPoolId!,
      count: _kMultiPullCount,
    );
    if (results.isEmpty) return;

    // Find highest rarity in results for analytics
    final highestRarity = results
        .map((r) => r.item.rarity.index)
        .reduce((a, b) => a > b ? a : b);

    setState(() {
      _pullResults = results;
      _isAnimating = true;
    });

    await _analytics.logEvent(
      name: 'gacha_pull',
      parameters: {
        'pool_id': _selectedPoolId!,
        'pull_count': _kMultiPullCount,
        'currency_spent': _kMultiPullCost,
        'highest_rarity': GachaRarity.values[highestRarity].nameKr,
        'pity_triggered_count':
            results.where((r) => r.isPityTriggered).length,
      },
    );
  }

  // ── Firebase Event: Pool selection change ─────────────────
  Future<void> _onPoolSelected(String poolId) async {
    setState(() => _selectedPoolId = poolId);

    await _analytics.logEvent(
      name: 'gacha_pool_selected',
      parameters: {'pool_id': poolId},
    );
  }

  void _onAnimationComplete() {
    setState(() => _isAnimating = false);
  }

  void _dismissResults() {
    setState(() {
      _pullResults = null;
      _isAnimating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show pull animation overlay when results are available
    if (_pullResults != null) {
      return Scaffold(
        backgroundColor: MGColors.backgroundDark,
        body: SafeArea(
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(MGSpacing.md),
                  child: MGIconButton(
                    icon: Icons.close,
                    onPressed: _dismissResults,
                    color: MGColors.textHighEmphasis,
                    backgroundColor: MGColors.surfaceDark,
                    size: 40,
                    enabled: !_isAnimating,
                  ),
                ),
              ),
              // Pull animation/results
              Expanded(
                child: GachaPullAnimation(
                  results: _pullResults!.map((r) => r.item).toList(),
                  onComplete: _onAnimationComplete,
                ),
              ),
              // Result summary
              if (!_isAnimating) _buildResultSummary(),
              // Dismiss button
              if (!_isAnimating)
                Padding(
                  padding: EdgeInsets.all(MGSpacing.lg),
                  child: MGButton(
                    label: 'View collection',
                    onPressed: _dismissResults,
                    size: MGButtonSize.large,
                    width: double.infinity,
                    backgroundColor: MGColors.primaryAction,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MGColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPullTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar: back button + currency display ──────────────
  Widget _buildTopBar() {
    return Padding(
      padding: MGSpacing.symmetric(
        horizontal: MGSpacing.md,
        vertical: MGSpacing.xs,
      ),
      child: Row(
        children: [
          MGIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
            color: MGColors.textHighEmphasis,
            backgroundColor: MGColors.surfaceDark,
            size: 40,
          ),
          const Spacer(),
          // Gem currency display
          MGResourceBar(
            icon: Icons.diamond,
            value: '2,400',
            iconColor: MGColors.gem,
          ),
          SizedBox(width: MGSpacing.sm),
          // Ticket currency display
          MGResourceBar(
            icon: Icons.confirmation_number,
            value: '5',
            iconColor: MGColors.year1Accent,
          ),
        ],
      ),
    );
  }

  // ── Tab bar: Pull | History ──────────────────────────────
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MGColors.border, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: MGColors.gem,
        labelColor: MGColors.textHighEmphasis,
        unselectedLabelColor: MGColors.textDisabled,
        onTap: (index) {
          if (index == 1) {
            // Firebase Analytics: history tab viewed
            _analytics.logEvent(
              name: 'gacha_history_viewed',
              parameters: {
                'pool_id': _selectedPoolId ?? 'none',
                'total_pulls':
                    _gachaManager.getPityState(_selectedPoolId ?? '')
                        ?.totalPulls ?? 0,
              },
            );
          }
        },
        tabs: const [
          Tab(icon: Icon(Icons.auto_awesome), text: 'Summon'),
          Tab(icon: Icon(Icons.history), text: 'History'),
        ],
      ),
    );
  }

  // ── Pull Tab: pool selector + pull area + pity ───────────
  Widget _buildPullTab() {
    final pools = _gachaManager.activePools;

    if (pools.isEmpty) {
      return const Center(
        child: Text(
          'No active gacha pools',
          style: TextStyle(color: MGColors.textMediumEmphasis),
        ),
      );
    }

    final pool = _currentPool;
    if (pool == null) return const SizedBox.shrink();

    final pityState = _gachaManager.getPityState(pool.id);
    final pityConfig = _gachaManager.pityConfig;

    return SingleChildScrollView(
      padding: EdgeInsets.all(MGSpacing.md),
      child: Column(
        children: [
          // Pool selector (if multiple pools)
          if (pools.length > 1) ...[
            _buildPoolSelector(pools),
            SizedBox(height: MGSpacing.lg),
          ],
          // Banner visual area
          _buildBannerArea(pool),
          SizedBox(height: MGSpacing.lg),
          // Rate table
          _buildRateTable(pool),
          SizedBox(height: MGSpacing.lg),
          // Pity indicator
          if (pityState != null)
            GachaPityIndicator(
              currentPulls: pityState.currentPity,
              softPity: pityConfig.softPityStart,
              hardPity: pityConfig.hardPity,
            ),
          SizedBox(height: MGSpacing.lg),
          // Pull buttons row
          _buildPullButtons(),
        ],
      ),
    );
  }

  // ── Pool selector chips ──────────────────────────────────
  Widget _buildPoolSelector(List<GachaPool> pools) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pools.length,
        separatorBuilder: (_, _) => SizedBox(width: MGSpacing.sm),
        itemBuilder: (context, index) {
          final pool = pools[index];
          final isSelected = pool.id == _selectedPoolId;

          return GestureDetector(
            onTap: () => _onPoolSelected(pool.id),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: MGSpacing.md,
                vertical: MGSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? MGColors.gem.withValues(alpha: 0.3)
                    : MGColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? MGColors.gem : MGColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                pool.nameKr,
                style: TextStyle(
                  color: isSelected
                      ? MGColors.textHighEmphasis
                      : MGColors.textMediumEmphasis,
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Banner visual area: featured characters ──────────────
  Widget _buildBannerArea(GachaPool pool) {
    return MGCard(
      backgroundColor: MGColors.surfaceDark,
      borderColor: MGColors.gem.withValues(alpha: 0.3),
      padding: EdgeInsets.all(MGSpacing.lg),
      child: Column(
        children: [
          Text(
            pool.nameKr,
            style: MGTextStyles.h2.copyWith(
              color: MGColors.textHighEmphasis,
            ),
          ),
          if (pool.description != null) ...[
            SizedBox(height: MGSpacing.xs),
            Text(
              pool.description!,
              style: MGTextStyles.bodySmall.copyWith(
                color: MGColors.textMediumEmphasis,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: MGSpacing.md),
          // Featured item showcase placeholder
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  MGColors.gem.withValues(alpha: 0.15),
                  MGColors.legendary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MGColors.gem.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: MGColors.gem,
                    size: 40,
                  ),
                  SizedBox(height: MGSpacing.xs),
                  Text(
                    '${pool.items.length} items available',
                    style: MGTextStyles.caption.copyWith(
                      color: MGColors.textMediumEmphasis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Remaining time
          if (pool.remainingSeconds != null) ...[
            SizedBox(height: MGSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, color: MGColors.warning, size: 16),
                SizedBox(width: MGSpacing.xs),
                Text(
                  _formatRemainingTime(pool.remainingSeconds!),
                  style: MGTextStyles.caption.copyWith(
                    color: MGColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Rate table: probability display ──────────────────────
  Widget _buildRateTable(GachaPool pool) {
    return MGCard.outlined(
      padding: EdgeInsets.all(MGSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drop Rates',
            style: MGTextStyles.h3.copyWith(
              color: MGColors.textHighEmphasis,
            ),
          ),
          SizedBox(height: MGSpacing.sm),
          ...GachaRarity.values.reversed.map((rarity) {
            final rate = pool.getRateForRarity(rarity);
            if (rate <= 0) return const SizedBox.shrink();
            return _buildRateRow(rarity, rate);
          }),
        ],
      ),
    );
  }

  Widget _buildRateRow(GachaRarity rarity, double rate) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MGSpacing.xxs),
      child: Row(
        children: [
          // Rarity badge
          Container(
            width: 40,
            padding: EdgeInsets.symmetric(
              horizontal: MGSpacing.xs,
              vertical: MGSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: _getRarityColor(rarity),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              rarity.nameKr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: MGSpacing.sm),
          // Rate bar
          Expanded(
            child: MGLinearProgress(
              value: rate / 100,
              height: 6,
              valueColor: _getRarityColor(rarity),
              backgroundColor: MGColors.surfaceDark,
              borderRadius: 3,
            ),
          ),
          SizedBox(width: MGSpacing.sm),
          // Rate percentage
          SizedBox(
            width: 50,
            child: Text(
              '${rate.toStringAsFixed(1)}%',
              style: MGTextStyles.caption.copyWith(
                color: MGColors.textHighEmphasis,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pull buttons: 1x and 10x ─────────────────────────────
  Widget _buildPullButtons() {
    return Row(
      children: [
        // Single pull
        Expanded(
          child: GachaPullButton(
            label: '1x Pull',
            cost: _kSinglePullCost,
            onPressed: _onSinglePull,
          ),
        ),
        SizedBox(width: MGSpacing.md),
        // Multi pull (10x)
        Expanded(
          child: GachaPullButton(
            label: '10x Pull',
            cost: _kMultiPullCost,
            onPressed: _onMultiPull,
          ),
        ),
      ],
    );
  }

  // ── Result summary after animation ───────────────────────
  Widget _buildResultSummary() {
    if (_pullResults == null) return const SizedBox.shrink();

    // Count by rarity
    final rarityCounts = <GachaRarity, int>{};
    for (final result in _pullResults!) {
      rarityCounts[result.item.rarity] =
          (rarityCounts[result.item.rarity] ?? 0) + 1;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MGSpacing.md),
      child: Wrap(
        spacing: MGSpacing.sm,
        children: rarityCounts.entries.map((entry) {
          return Chip(
            avatar: CircleAvatar(
              backgroundColor: _getRarityColor(entry.key),
              radius: 10,
            ),
            label: Text(
              '${entry.key.nameKr} x${entry.value}',
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: MGColors.surfaceDark,
            side: BorderSide(
              color: _getRarityColor(entry.key).withValues(alpha: 0.5),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── History Tab: pull log + collection stats ─────────────
  Widget _buildHistoryTab() {
    final history = _gachaManager.history;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              color: MGColors.textDisabled,
              size: 64,
            ),
            SizedBox(height: MGSpacing.md),
            Text(
              'No pull history yet',
              style: MGTextStyles.body.copyWith(
                color: MGColors.textDisabled,
              ),
            ),
            SizedBox(height: MGSpacing.xs),
            Text(
              'Your summon results will appear here',
              style: MGTextStyles.caption.copyWith(
                color: MGColors.textDisabled,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stats summary
        _buildHistoryStats(),
        const Divider(color: MGColors.border, height: 1),
        // History list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(MGSpacing.md),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              return _buildHistoryEntry(entry);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryStats() {
    if (_selectedPoolId == null) return const SizedBox.shrink();

    final stats = _gachaManager.getStats(_selectedPoolId!);
    final pityState = _gachaManager.getPityState(_selectedPoolId!);

    return Padding(
      padding: EdgeInsets.all(MGSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            'Total Pulls',
            '${stats.totalPulls}',
            Icons.repeat,
            MGColors.info,
          ),
          _buildStatItem(
            'Pity Counter',
            '${pityState?.currentPity ?? 0}',
            Icons.trending_up,
            MGColors.warning,
          ),
          _buildStatItem(
            'SSR Rate',
            '${stats.getRateForRarity(GachaRarity.ultraRare).toStringAsFixed(1)}%',
            Icons.auto_awesome,
            MGColors.gem,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: MGSpacing.xs),
        Text(
          value,
          style: MGTextStyles.h3.copyWith(
            color: MGColors.textHighEmphasis,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: MGTextStyles.caption.copyWith(
            color: MGColors.textMediumEmphasis,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryEntry(GachaHistoryEntry entry) {
    final rarityColor = _getRarityColor(entry.rarity);

    return Padding(
      padding: EdgeInsets.only(bottom: MGSpacing.xs),
      child: MGCard(
        backgroundColor: MGColors.surfaceDark,
        padding: EdgeInsets.symmetric(
          horizontal: MGSpacing.md,
          vertical: MGSpacing.sm,
        ),
        child: Row(
          children: [
            // Rarity indicator
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: rarityColor),
              ),
              child: Center(
                child: Text(
                  entry.rarity.nameKr,
                  style: TextStyle(
                    color: rarityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: MGSpacing.sm),
            // Item info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.itemId,
                    style: MGTextStyles.bodySmall.copyWith(
                      color: MGColors.textHighEmphasis,
                    ),
                  ),
                  Text(
                    'Pull #${entry.pullNumber}',
                    style: MGTextStyles.caption.copyWith(
                      color: MGColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
            // Timestamp
            Text(
              _formatTimestamp(entry.timestamp),
              style: MGTextStyles.caption.copyWith(
                color: MGColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  /// Map GachaRarity to MGColors rarity palette.
  Color _getRarityColor(GachaRarity rarity) {
    return switch (rarity) {
      GachaRarity.normal => MGColors.common,
      GachaRarity.rare => MGColors.rare,
      GachaRarity.superRare => MGColors.legendary,
      GachaRarity.ultraRare => MGColors.legendary,
      GachaRarity.legendary => MGColors.mythic,
    };
  }

  String _formatRemainingTime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    if (days > 0) return '${days}d ${hours}h remaining';
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m remaining';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
