// ============================================================
// BattlePass Screen -- MG-0006 Hero Auto Battle
// Genre: RPG Auto Battler · Retention System UI
//
// Firebase Analytics Events:
//   - battlepass_screen_opened: Screen view tracking
//   - battlepass_tier_claimed:  {tier, is_premium} on reward claim
//   - battlepass_premium_purchased: Premium upgrade conversion
//   - battlepass_mission_claimed: {mission_id, exp_reward} mission completion
//   - battlepass_claim_all: Bulk claim action
//
// Template: This file is the canonical template for 47 remaining games.
// ============================================================import 'package:mg_common_game/l10n/localization.dart';


import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import 'package:mg_common_game/core/ui/widgets/battlepass/battlepass_tier_list.dart';
import 'package:mg_common_game/systems/battlepass/battlepass_config.dart';
import 'package:mg_common_game/systems/battlepass/battlepass_manager.dart';
import '../l10n/localization.dart';

/// Full-screen BattlePass UI with season progress, tier rewards,
/// mission list, and premium upgrade flow.
///
/// Access pattern: `GetIt.I<BattlePassManager>()` registered in main.dart.
/// Uses mg_common_game shared widgets: [BattlePassHeader],
/// [BattlePassTierList], [BattlePassMissionList].
class BattlePassScreen extends StatefulWidget {
  const BattlePassScreen({super.key});

  @override
  State<BattlePassScreen> createState() => _BattlePassScreenState();
}

class _BattlePassScreenState extends State<BattlePassScreen>
    with SingleTickerProviderStateMixin {
  late final BattlePassManager _bpManager;
  late final TabController _tabController;

  // Firebase Analytics: cached instance for event logging
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    _bpManager = GetIt.I<BattlePassManager>();
    _tabController = TabController(length: 2, vsync: this);
    _bpManager.addListener(_onBattlePassChanged);

    // Firebase Analytics: screen_view event
    _analytics.logEvent(
      name: 'battlepass_screen_opened',
      parameters: {
        'season_id': _bpManager.currentSeason?.id ?? 'none',
        'current_level': _bpManager.currentLevel,
        'is_premium': _bpManager.isPremium,
      },
    );
  }

  @override
  void dispose() {
    _bpManager.removeListener(_onBattlePassChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onBattlePassChanged() {
    if (mounted) setState(() {});
  }

  // ── Firebase Event: Tier reward claimed ──────────────────
  Future<void> _onClaimReward(int level, bool isPremium) async {
    final rewards = _bpManager.claimReward(
      level,
      isPremiumReward: isPremium,
    );

    if (rewards.isNotEmpty) {
      await _analytics.logEvent(
        name: 'battlepass_tier_claimed',
        parameters: {
          'tier': level,
          'is_premium': isPremium,
          'reward_count': rewards.length,
          'season_id': _bpManager.currentSeason?.id ?? 'none',
        },
      );

      if (mounted) {
        _showRewardSnackBar(rewards, level);
      }
    }
  }

  // ── Firebase Event: Premium purchased ────────────────────
  Future<void> _onPurchasePremium() async {
    final confirmed = await MGModal.confirm(
      context: context,
      title: 'Premium BattlePass',
      message:
          'Unlock all premium rewards for this season?\n'
          'Price: \$${_bpManager.currentSeason?.premiumPrice ?? 9.99}',
      confirmText: 'Purchase',
      cancelText: 'Cancel',
    );

    if (confirmed && mounted) {
      _bpManager.purchasePremium();

      await _analytics.logEvent(
        name: 'battlepass_premium_purchased',
        parameters: {
          'season_id': _bpManager.currentSeason?.id ?? 'none',
          'current_level': _bpManager.currentLevel,
          'price': _bpManager.currentSeason?.premiumPrice ?? 9.99,
        },
      );
    }
  }

  // ── Firebase Event: Mission reward claimed ───────────────
  Future<void> _onClaimMission(String missionId) async {
    // Lookup expReward before claiming (state changes after claim)
    final allMissions = [
      ..._bpManager.dailyMissions,
      ..._bpManager.weeklyMissions,
    ];
    final mission = allMissions.where((m) => m.id == missionId).firstOrNull;
    final expReward = mission?.expReward ?? 0;

    final success = _bpManager.claimMissionReward(missionId);

    if (success) {
      await _analytics.logEvent(
        name: 'battlepass_mission_claimed',
        parameters: {
          'mission_id': missionId,
          'exp_reward': expReward,
          'season_id': _bpManager.currentSeason?.id ?? 'none',
        },
      );
    }
  }

  // ── Firebase Event: Claim all available rewards ──────────
  Future<void> _onClaimAll() async {
    final rewards = _bpManager.claimAllAvailable();

    if (rewards.isNotEmpty) {
      await _analytics.logEvent(
        name: 'battlepass_claim_all',
        parameters: {
          'reward_count': rewards.length,
          'current_level': _bpManager.currentLevel,
          'season_id': _bpManager.currentSeason?.id ?? 'none',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.notification_rewardslength_rewards_claimed),
            backgroundColor: MGColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showRewardSnackBar(List<BPReward> rewards, int level) {
    final names = rewards.map((r) => r.nameKr).join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.progress_tier_level_names),
        backgroundColor: MGColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final season = _bpManager.currentSeason;

    if (season == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.progress_level_battlepasscurrentlevel)),
        body: const Center(
          child: Text(
            'No active season',
            style: TextStyle(color: MGColors.textMediumEmphasis),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MGColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(season),
            _buildTabBar(),
            Expanded(child: _buildTabContent(season)),
          ],
        ),
      ),
    );
  }

  // ── Header: season info, XP bar, premium button ──────────
  Widget _buildHeader(BPSeasonConfig season) {
    final tier = season.getTier(_bpManager.currentLevel);
    final requiredExp = tier?.requiredExp ?? season.expPerLevel;

    return Column(
      children: [
        // Top bar with back button and claim-all
        Padding(
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
              if (_bpManager.unclaimedRewardCount > 0)
                MGButton(
                  label: context.l10n.notification_claim_all__bpmanagerunclaimedrewardcount,
                  size: MGButtonSize.small,
                  icon: Icons.done_all,
                  backgroundColor: MGColors.success,
                  onPressed: _onClaimAll,
                ),
            ],
          ),
        ),
        // Season header with level, XP, premium
        BattlePassHeader(
          seasonName: season.nameKr,
          currentLevel: _bpManager.currentLevel,
          maxLevel: season.maxLevel,
          currentExp: _bpManager.currentExp,
          expToNextLevel: requiredExp,
          remainingDays: season.remainingDays,
          isPremium: _bpManager.isPremium,
          onPurchasePremium:
              _bpManager.isPremium ? null : _onPurchasePremium,
        ),
      ],
    );
  }

  // ── Tab bar: Rewards | Missions ──────────────────────────
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MGColors.border,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: MGColors.primaryAction,
        labelColor: MGColors.textHighEmphasis,
        unselectedLabelColor: MGColors.textDisabled,
        tabs: const [
          Tab(icon: Icon(Icons.card_giftcard), text: 'Rewards'),
          Tab(icon: Icon(Icons.assignment), text: 'Missions'),
        ],
      ),
    );
  }

  // ── Tab content ──────────────────────────────────────────
  Widget _buildTabContent(BPSeasonConfig season) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildRewardsTab(season),
        _buildMissionsTab(),
      ],
    );
  }

  // ── Rewards Tab: horizontal tier list ────────────────────
  Widget _buildRewardsTab(BPSeasonConfig season) {
    final state = _bpManager.state;

    return Column(
      children: [
        // Free vs Premium label row
        Padding(
          padding: MGSpacing.symmetric(
            horizontal: MGSpacing.md,
            vertical: MGSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_open,
                color: MGColors.textMediumEmphasis,
                size: 16,
              ),
              SizedBox(width: MGSpacing.xs),
              Text(
                'FREE',
                style: MGTextStyles.caption.copyWith(
                  color: MGColors.textMediumEmphasis,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.star,
                color: MGColors.gold,
                size: 16,
              ),
              SizedBox(width: MGSpacing.xs),
              Text(
                'PREMIUM',
                style: MGTextStyles.caption.copyWith(
                  color: MGColors.gold,
                ),
              ),
            ],
          ),
        ),
        // Horizontal tier list
        Expanded(
          child: BattlePassTierList(
            tiers: season.tiers,
            currentLevel: _bpManager.currentLevel,
            isPremium: _bpManager.isPremium,
            claimedFreeLevels: state?.claimedFreeLevels ?? {},
            claimedPremiumLevels: state?.claimedPremiumLevels ?? {},
            onClaimReward: _onClaimReward,
          ),
        ),
        // Level progress bar at the bottom
        Padding(
          padding: MGSpacing.symmetric(
            horizontal: MGSpacing.md,
            vertical: MGSpacing.md,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Season Progress',
                    style: MGTextStyles.caption.copyWith(
                      color: MGColors.textMediumEmphasis,
                    ),
                  ),
                  Text(
                    'Lv.${_bpManager.currentLevel} / ${season.maxLevel}',
                    style: MGTextStyles.caption.copyWith(
                      color: MGColors.textHighEmphasis,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: MGSpacing.xs),
              MGLinearProgress(
                value: _bpManager.currentLevel / season.maxLevel,
                height: 8,
                valueColor: MGColors.year1Accent,
                backgroundColor: MGColors.surfaceDark,
                borderRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Missions Tab: daily + weekly missions ────────────────
  Widget _buildMissionsTab() {
    final state = _bpManager.state;
    final missionProgressMap = <String, int>{};
    final claimedMissions = <String>{};

    // Convert MissionProgress map to the format expected by widgets
    if (state != null) {
      for (final entry in state.missionProgress.entries) {
        final progress = entry.value;
        // Map by tracking key for the widget
        final allMissions = [
          ..._bpManager.dailyMissions,
          ..._bpManager.weeklyMissions,
        ];
        final mission = allMissions
            .where((m) => m.id == entry.key)
            .firstOrNull;
        if (mission?.trackingKey != null) {
          missionProgressMap[mission!.trackingKey!] = progress.currentValue;
        }
        if (progress.isClaimed) {
          claimedMissions.add(entry.key);
        }
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(MGSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Missions
          _buildMissionSection(
            title: 'Daily Missions',
            icon: Icons.today,
            iconColor: MGColors.info,
            missions: _bpManager.dailyMissions,
            missionProgress: missionProgressMap,
            claimedMissions: claimedMissions,
          ),
          SizedBox(height: MGSpacing.lg),
          // Weekly Missions
          _buildMissionSection(
            title: 'Weekly Missions',
            icon: Icons.date_range,
            iconColor: MGColors.warning,
            missions: _bpManager.weeklyMissions,
            missionProgress: missionProgressMap,
            claimedMissions: claimedMissions,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<BPMission> missions,
    required Map<String, int> missionProgress,
    required Set<String> claimedMissions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            SizedBox(width: MGSpacing.xs),
            Text(
              title,
              style: MGTextStyles.h3.copyWith(
                color: MGColors.textHighEmphasis,
              ),
            ),
            const Spacer(),
            Text(
              '${_getCompletedCount(missions, claimedMissions)}/${missions.length}',
              style: MGTextStyles.caption.copyWith(
                color: MGColors.textMediumEmphasis,
              ),
            ),
          ],
        ),
        SizedBox(height: MGSpacing.sm),
        BattlePassMissionList(
          missions: missions,
          missionProgress: missionProgress,
          claimedMissions: claimedMissions,
          onClaimMission: _onClaimMission,
        ),
      ],
    );
  }

  int _getCompletedCount(
    List<BPMission> missions,
    Set<String> claimedMissions,
  ) {
    return missions.where((m) => claimedMissions.contains(m.id)).length;
  }
}
