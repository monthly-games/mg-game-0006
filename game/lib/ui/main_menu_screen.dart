import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mg_common_game/core/ui/mg_ui.dart';
import 'package:mg_common_game/l10n/localization.dart';
import 'battle_screen.dart';


// ============================================================
// Main Menu Screen -- MG-0006 Hero Auto Battle
// Navigation hub: Battle, BattlePass, Gacha, Upgrades
// ============================================================

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [MGColors.surfaceDark, MGColors.backgroundDark],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: MGSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: MGSpacing.xxl),
                      // ── Game title ──
                      const Text(
                        'HERO AUTO\nBATTLE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: MGColors.textHighEmphasis,
                          letterSpacing: 6,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: MGSpacing.sm),
                      Container(
                        width: 60,
                        height: 3,
                        decoration: BoxDecoration(
                          color: MGColors.year1Accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: MGSpacing.xxl),

                      // ── Primary CTA: Start Battle ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BattleScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.flash_on, size: 28),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Text(
                              'START BATTLE',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MGColors.year1Primary,
                            foregroundColor: MGColors.textHighEmphasis,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                      SizedBox(height: MGSpacing.xl),

                      // ── Secondary navigation row ──
                      Row(
                        children: [
                          Expanded(
                            child: _MenuTile(
                              icon: Icons.military_tech,
                              label: 'Battle Pass',
                              accentColor: MGColors.year1Accent,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/battlepass',
                              ),
                            ),
                          ),
                          SizedBox(width: MGSpacing.sm),
                          Expanded(
                            child: _MenuTile(
                              icon: Icons.auto_awesome,
                              label: 'Gacha',
                              accentColor: MGColors.gem,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/gacha',
                              ),
                            ),
                          ),
                          SizedBox(width: MGSpacing.sm),
                          Expanded(
                            child: _MenuTile(
                              icon: Icons.trending_up,
                              label: 'Upgrades',
                              accentColor: MGColors.info,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/upgrades',
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: MGSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Spine character placeholder (top-right corner)
          Positioned(
            top: 60,
            right: 16,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Hero Commander greets you!"),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: MGColors.year1Accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MGColors.year1Accent, width: 2),
                ),
                child: const Icon(
                  Icons.shield,
                  size: 60,
                  color: MGColors.textHighEmphasis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Menu Tile -- square navigation card with icon + label
// ============================================================

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: MGSpacing.md,
          horizontal: MGSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: MGColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            SizedBox(height: MGSpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: MGColors.textHighEmphasis,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
