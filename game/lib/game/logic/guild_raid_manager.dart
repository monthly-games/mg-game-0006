import 'dart:math';
import 'package:flutter/foundation.dart';

/// Guild Raid Boss difficulty tier
enum RaidDifficulty {
  normal,
  hard,
  extreme,
  nightmare,
}

/// Raid reward type
enum RewardType {
  soulStones,
  equipment,
  gold,
  rareShards,
}

/// Raid reward
class RaidReward {
  final RewardType type;
  final int amount;
  final int rarity; // 1-5 stars

  const RaidReward({
    required this.type,
    required this.amount,
    required this.rarity,
  });

  @override
  String toString() => 'RaidReward($type, $amount, $rarity★)';
}

/// Raid boss configuration
class RaidBoss {
  final String id;
  final String name;
  final int baseHp;
  final int baseAttack;
  final RaidDifficulty difficulty;
  final List<RaidReward> rewards;
  final DateTime unlockTime;

  const RaidBoss({
    required this.id,
    required this.name,
    required this.baseHp,
    required this.baseAttack,
    required this.difficulty,
    required this.rewards,
    required this.unlockTime,
  });

  /// Calculate current HP based on guild size
  int get currentHp => baseHp * 10;

  /// Calculate max HP based on guild size
  int get maxHp => baseHp * 10;

  /// Get damage multiplier based on difficulty
  double get damageMultiplier {
    switch (difficulty) {
      case RaidDifficulty.normal:
        return 1.0;
      case RaidDifficulty.hard:
        return 1.5;
      case RaidDifficulty.extreme:
        return 2.0;
      case RaidDifficulty.nightmare:
        return 2.5;
    }
  }

  /// Get reward multiplier based on difficulty
  double get rewardMultiplier {
    switch (difficulty) {
      case RaidDifficulty.normal:
        return 1.0;
      case RaidDifficulty.hard:
        return 1.5;
      case RaidDifficulty.extreme:
        return 2.0;
      case RaidDifficulty.nightmare:
        return 3.0;
    }
  }
}

/// Individual raid contribution
class RaidContribution {
  final String playerId;
  final String playerName;
  final int totalDamage;
  final int attackCount;
  final DateTime lastAttackTime;

  const RaidContribution({
    required this.playerId,
    required this.playerName,
    required this.totalDamage,
    required this.attackCount,
    required this.lastAttackTime,
  });

  /// Calculate contribution score for reward distribution
  double get contributionScore {
    final damageScore = totalDamage / 1000000.0; // Normalized by 1M damage
    final attackBonus = attackCount * 0.1; // Bonus for participation
    return damageScore + attackBonus;
  }

  @override
  String toString() => 'RaidContribution($playerName, $totalDamage dmg)';
}

/// Guild Raid Manager for MG-0006 Hero Auto Battle
/// Manages weekly guild boss raids with contribution tracking and rewards
class GuildRaidManager extends ChangeNotifier {
  // Raid state
  RaidBoss? _currentBoss;
  int _remainingBossHp = 0;
  final List<RaidContribution> _contributions = [];
  DateTime? _weeklyResetTime;
  int _totalGuildDamage = 0;
  bool _isDefeated = false;

  // Player state
  final String _playerId;
  final String _playerName;
  int _playerStamina = 100;
  int _personalDamage = 0;
  int _personalAttackCount = 0;

  // Constants
  static const int maxStamina = 100;
  static const int staminaRegenPerHour = 10;
  static const int staminaCostPerAttack = 10;
  static const Duration weeklyResetDuration = Duration(days: 7);

  // Random for damage calculations
  final Random _random = Random();

  // Predefined raid bosses
  static List<RaidBoss> get _raidBosses => [
    RaidBoss(
      id: 'boss_001',
      name: 'Ancient Dragon',
      baseHp: 50000000,
      baseAttack: 5000,
      difficulty: RaidDifficulty.normal,
      unlockTime: _mondayStartOfWeek,
      rewards: const [
        RaidReward(type: RewardType.soulStones, amount: 100, rarity: 3),
        RaidReward(type: RewardType.equipment, amount: 1, rarity: 4),
      ],
    ),
    RaidBoss(
      id: 'boss_002',
      name: 'Shadow Lord',
      baseHp: 100000000,
      baseAttack: 8000,
      difficulty: RaidDifficulty.hard,
      unlockTime: _mondayStartOfWeek,
      rewards: const [
        RaidReward(type: RewardType.soulStones, amount: 200, rarity: 4),
        RaidReward(type: RewardType.equipment, amount: 2, rarity: 4),
        RaidReward(type: RewardType.rareShards, amount: 10, rarity: 5),
      ],
    ),
    RaidBoss(
      id: 'boss_003',
      name: 'Void Titan',
      baseHp: 200000000,
      baseAttack: 12000,
      difficulty: RaidDifficulty.extreme,
      unlockTime: _mondayStartOfWeek,
      rewards: const [
        RaidReward(type: RewardType.soulStones, amount: 500, rarity: 5),
        RaidReward(type: RewardType.equipment, amount: 3, rarity: 5),
        RaidReward(type: RewardType.rareShards, amount: 20, rarity: 5),
      ],
    ),
  ];

  static final DateTime _mondayStartOfWeek = DateTime.utc(2024, 1, 1);

  /// Initialize GuildRaidManager
  GuildRaidManager({
    required String playerId,
    required String playerName,
  })  : _playerId = playerId,
        _playerName = playerName {
    _initializeWeeklyRaid();
  }

  /// Get current raid boss
  RaidBoss? get currentBoss => _currentBoss;

  /// Get remaining boss HP
  int get remainingBossHp => _remainingBossHp;

  /// Get max boss HP
  int get maxBossHp => _currentBoss?.maxHp ?? 0;

  /// Get boss defeat status
  bool get isDefeated => _isDefeated;

  /// Get weekly reset time
  DateTime? get weeklyResetTime => _weeklyResetTime;

  /// Get all contributions
  List<RaidContribution> get contributions => List.unmodifiable(_contributions);

  /// Get total guild damage
  int get totalGuildDamage => _totalGuildDamage;

  /// Get player stamina
  int get playerStamina => _playerStamina;

  /// Get personal damage
  int get personalDamage => _personalDamage;

  /// Get personal attack count
  int get personalAttackCount => _personalAttackCount;

  /// Get boss HP percentage
  double get bossHpPercentage {
    if (maxBossHp <= 0) return 0.0;
    return (_remainingBossHp / maxBossHp).clamp(0.0, 1.0);
  }

  /// Initialize weekly raid
  void _initializeWeeklyRaid() {
    _weeklyResetTime = _getNextWeeklyReset();

    // Select boss based on current week
    final weekNumber = _getCurrentWeekNumber();
    final bossIndex = weekNumber % _raidBosses.length;
    _currentBoss = _raidBosses[bossIndex];
    _remainingBossHp = _currentBoss!.maxHp;
    _isDefeated = false;

    notifyListeners();
  }

  /// Get next weekly reset time (Monday 00:00 UTC)
  DateTime _getNextWeeklyReset() {
    final now = DateTime.now().toUtc();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final reset = DateTime.utc(monday.year, monday.month, monday.day)
        .add(weeklyResetDuration);
    return reset;
  }

  /// Get current week number (weeks since epoch)
  int _getCurrentWeekNumber() {
    final now = DateTime.now().toUtc();
    final epoch = DateTime.utc(1970, 1, 5); // First Monday
    return (now.difference(epoch).inDays / 7).floor();
  }

  /// Attack raid boss
  /// Returns true if attack was successful
  bool attackBoss(int teamPower) {
    // Check stamina
    if (_playerStamina < staminaCostPerAttack) {
      return false;
    }

    // Check if boss is already defeated
    if (_isDefeated) {
      return false;
    }

    // Check weekly reset
    if (_weeklyResetTime != null && DateTime.now().toUtc().isAfter(_weeklyResetTime!)) {
      _resetWeeklyRaid();
    }

    // Calculate damage based on team power and random variance
    final baseDamage = (teamPower * 1000.0 * (_currentBoss!.damageMultiplier)).toInt();
    final variance = 0.8 + (_random.nextDouble() * 0.4); // 80%-120%
    final damage = (baseDamage * variance).toInt();

    // Apply damage
    _remainingBossHp = (_remainingBossHp - damage).clamp(0, maxBossHp);
    _totalGuildDamage += damage;
    _personalDamage += damage;
    _personalAttackCount++;
    _playerStamina -= staminaCostPerAttack;

    // Update or add player contribution
    _updatePlayerContribution();

    // Check if boss is defeated
    if (_remainingBossHp <= 0) {
      _isDefeated = true;
    }

    notifyListeners();
    return true;
  }

  /// Update player's contribution record
  void _updatePlayerContribution() {
    final existingIndex = _contributions.indexWhere(
      (c) => c.playerId == _playerId,
    );

    final contribution = RaidContribution(
      playerId: _playerId,
      playerName: _playerName,
      totalDamage: _personalDamage,
      attackCount: _personalAttackCount,
      lastAttackTime: DateTime.now(),
    );

    if (existingIndex >= 0) {
      _contributions[existingIndex] = contribution;
    } else {
      _contributions.add(contribution);
    }

    // Sort by total damage
    _contributions.sort((a, b) => b.totalDamage.compareTo(a.totalDamage));
  }

  /// Get player's contribution rank
  int getPlayerRank() {
    final index = _contributions.indexWhere((c) => c.playerId == _playerId);
    return index >= 0 ? index + 1 : 0;
  }

  /// Calculate rewards based on contribution rank and boss defeat
  List<RaidReward> calculateRewards() {
    if (!_isDefeated) return [];

    final rank = getPlayerRank();
    if (rank == 0) return [];

    final baseRewards = _currentBoss!.rewards;
    final multiplier = _currentBoss!.rewardMultiplier;

    // Rank-based reward multiplier
    double rankMultiplier;
    if (rank <= 1) {
      rankMultiplier = 1.5; // 1st place
    } else if (rank <= 3) {
      rankMultiplier = 1.3; // Top 3
    } else if (rank <= 10) {
      rankMultiplier = 1.1; // Top 10
    } else if (rank <= 50) {
      rankMultiplier = 1.0; // Top 50
    } else {
      rankMultiplier = 0.8; // Participation
    }

    return baseRewards.map((reward) {
      final adjustedAmount = (reward.amount * multiplier * rankMultiplier).round();
      return RaidReward(
        type: reward.type,
        amount: adjustedAmount,
        rarity: reward.rarity,
      );
    }).toList();
  }

  /// Regenerate stamina (call this hourly)
  void regenerateStamina() {
    _playerStamina = (_playerStamina + staminaRegenPerHour).clamp(0, maxStamina);
    notifyListeners();
  }

  /// Reset weekly raid
  void _resetWeeklyRaid() {
    _currentBoss = null;
    _remainingBossHp = 0;
    _contributions.clear();
    _totalGuildDamage = 0;
    _isDefeated = false;
    _personalDamage = 0;
    _personalAttackCount = 0;
    _playerStamina = maxStamina;

    _initializeWeeklyRaid();
  }

  /// Get raid state for save/load
  Map<String, dynamic> toJson() {
    return {
      'playerId': _playerId,
      'playerName': _playerName,
      'currentBossId': _currentBoss?.id,
      'remainingBossHp': _remainingBossHp,
      'totalGuildDamage': _totalGuildDamage,
      'isDefeated': _isDefeated,
      'weeklyResetTime': _weeklyResetTime?.toIso8601String(),
      'playerStamina': _playerStamina,
      'personalDamage': _personalDamage,
      'personalAttackCount': _personalAttackCount,
      'contributions': _contributions.map((c) => {
        'playerId': c.playerId,
        'playerName': c.playerName,
        'totalDamage': c.totalDamage,
        'attackCount': c.attackCount,
        'lastAttackTime': c.lastAttackTime.toIso8601String(),
      }).toList(),
    };
  }

  /// Load raid state
  void loadFromJson(Map<String, dynamic> json) {
    final bossId = json['currentBossId'] as String?;
    if (bossId != null) {
      _currentBoss = _raidBosses.where((b) => b.id == bossId).firstOrNull;
    }

    _remainingBossHp = json['remainingBossHp'] as int? ?? 0;
    _totalGuildDamage = json['totalGuildDamage'] as int? ?? 0;
    _isDefeated = json['isDefeated'] as bool? ?? false;

    final resetTime = json['weeklyResetTime'] as String?;
    if (resetTime != null) {
      _weeklyResetTime = DateTime.parse(resetTime);
    }

    _playerStamina = json['playerStamina'] as int? ?? maxStamina;
    _personalDamage = json['personalDamage'] as int? ?? 0;
    _personalAttackCount = json['personalAttackCount'] as int? ?? 0;

    _contributions.clear();
    final contributionsList = json['contributions'] as List<dynamic>? ?? [];
    for (final c in contributionsList) {
      final contributionJson = c as Map<String, dynamic>;
      _contributions.add(RaidContribution(
        playerId: contributionJson['playerId'] as String,
        playerName: contributionJson['playerName'] as String,
        totalDamage: contributionJson['totalDamage'] as int,
        attackCount: contributionJson['attackCount'] as int,
        lastAttackTime: DateTime.parse(contributionJson['lastAttackTime'] as String),
      ));
    }

    notifyListeners();
  }
}
