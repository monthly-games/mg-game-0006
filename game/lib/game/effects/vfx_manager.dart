import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// VFX Manager for Hero Auto Battle Arena (MG-0006)
/// Auto-Battler + PVP 게임 전용 이펙트 관리자
class VfxManager extends Component with HasGameRef {
  VfxManager();
  final Random _random = Random();

  // ============================================================
  // Battle Effects
  // ============================================================

  void showAttackHit(Vector2 position, {Color color = Colors.white, bool isCritical = false}) {
    gameRef.add(_createHitEffect(position: position, color: color, isCritical: isCritical));
    if (isCritical) {
      gameRef.add(_createSparkleEffect(position: position, color: Colors.yellow, count: 12));
    }
  }

  void showDamageNumber(Vector2 position, int damage, {bool isCritical = false, bool isHeal = false}) {
    gameRef.add(_DamageNumber(position: position, damage: damage, isCritical: isCritical, isHeal: isHeal));
  }

  void showSkillActivation(Vector2 position, Color skillColor) {
    gameRef.add(_createConvergeEffect(position: position, color: skillColor));
    gameRef.add(_createGroundCircle(position: position, color: skillColor));
  }

  void showSkillHit(Vector2 position, Color skillColor, {double radius = 50}) {
    gameRef.add(_createExplosionEffect(position: position, color: skillColor, count: 25, radius: radius));
  }

  void showUnitDeath(Vector2 position, {bool isEnemy = true}) {
    final color = isEnemy ? Colors.red : Colors.blue;
    gameRef.add(_createExplosionEffect(position: position, color: color, count: 20, radius: 50));
    gameRef.add(_createSmokeEffect(position: position, count: 6));
  }

  void showBuffApply(Vector2 position, Color buffColor, {bool isDebuff = false}) {
    gameRef.add(_createBuffEffect(position: position, color: buffColor, isDebuff: isDebuff));
  }

  void showBattleStart(Vector2 centerPosition) {
    gameRef.add(_BattleStartText(position: centerPosition));
    gameRef.add(_createExplosionEffect(position: centerPosition, color: Colors.white, count: 30, radius: 80));
  }

  void showVictory(Vector2 centerPosition) {
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (!isMounted) return;
        final offset = Vector2((_random.nextDouble() - 0.5) * 200, (_random.nextDouble() - 0.5) * 100);
        gameRef.add(_createSparkleEffect(position: centerPosition + offset, color: Colors.amber, count: 15));
      });
    }
    gameRef.add(_VictoryText(position: centerPosition));
  }

  void showDefeat(Vector2 centerPosition) {
    gameRef.add(_createSmokeEffect(position: centerPosition, count: 20));
    gameRef.add(_DefeatText(position: centerPosition));
  }

  // ============================================================
  // Card/Unit Effects
  // ============================================================

  void showCardFlip(Vector2 position) {
    gameRef.add(_createSparkleEffect(position: position, color: Colors.white, count: 10));
  }

  void showRankUp(Vector2 position) {
    gameRef.add(_createRisingEffect(position: position, color: Colors.amber, count: 20, speed: 100));
    gameRef.add(_RankUpText(position: position));
    _triggerScreenShake(intensity: 3, duration: 0.2);
  }

  void showUnitSummon(Vector2 position) {
    gameRef.add(_createConvergeEffect(position: position, color: Colors.blue));
    gameRef.add(_createGroundCircle(position: position, color: Colors.cyan));
  }

  // ============================================================
  // Progression Effects
  // ============================================================

  void showGoldGain(Vector2 position, int amount) {
    gameRef.add(_createCoinEffect(position: position, count: (amount / 50).clamp(5, 15).toInt()));
    showNumberPopup(position, '+$amount', color: Colors.amber);
  }

  void showExpGain(Vector2 position) {
    gameRef.add(_createRisingEffect(position: position, color: Colors.lightBlue, count: 8, speed: 50));
  }

  void showNumberPopup(Vector2 position, String text, {Color color = Colors.white}) {
    gameRef.add(_NumberPopup(position: position, text: text, color: color));
  }

  void _triggerScreenShake({double intensity = 5, double duration = 0.3}) {
    if (gameRef.camera.viewfinder.children.isNotEmpty) {
      gameRef.camera.viewfinder.add(
        MoveByEffect(Vector2(intensity, 0), EffectController(duration: duration / 10, repeatCount: (duration * 10).toInt(), alternate: true)),
      );
    }
  }

  // ============================================================
  // Private Effect Generators
  // ============================================================

  ParticleSystemComponent _createHitEffect({required Vector2 position, required Color color, required bool isCritical}) {
    final count = isCritical ? 20 : 12;
    final speed = isCritical ? 140.0 : 100.0;

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.4,
        generator: (i) {
          final angle = (i / count) * 2 * pi;
          final velocity = Vector2(cos(angle), sin(angle)) * (speed * (0.5 + _random.nextDouble() * 0.5));

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2(0, 200),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                final size = (isCritical ? 5 : 3) * (1.0 - progress * 0.5);
                canvas.drawCircle(Offset.zero, size, Paint()..color = color.withOpacity(opacity));
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createExplosionEffect({required Vector2 position, required Color color, required int count, required double radius}) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.7,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = radius * (0.4 + _random.nextDouble() * 0.6);
          final velocity = Vector2(cos(angle), sin(angle)) * speed;

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2(0, 100),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (1.0 - progress).clamp(0.0, 1.0);
                final size = 5 * (1.0 - progress * 0.3);
                canvas.drawCircle(Offset.zero, size, Paint()..color = color.withOpacity(opacity));
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createConvergeEffect({required Vector2 position, required Color color}) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 12,
        lifespan: 0.5,
        generator: (i) {
          final startAngle = (i / 12) * 2 * pi;
          final startPos = Vector2(cos(startAngle), sin(startAngle)) * 50;

          return MovingParticle(
            from: position + startPos,
            to: position.clone(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = (1.0 - particle.progress * 0.5).clamp(0.0, 1.0);
                canvas.drawCircle(Offset.zero, 4, Paint()..color = color.withOpacity(opacity));
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createBuffEffect({required Vector2 position, required Color color, required bool isDebuff}) {
    final direction = isDebuff ? 1.0 : -1.0;

    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 15,
        lifespan: 0.8,
        generator: (i) {
          final spreadX = (_random.nextDouble() - 0.5) * 40;

          return AcceleratedParticle(
            position: position.clone() + Vector2(spreadX, isDebuff ? -20 : 20),
            speed: Vector2(0, direction * 50),
            acceleration: Vector2(0, direction * 30),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
                canvas.drawCircle(Offset.zero, 3, Paint()..color = color.withOpacity(opacity * 0.7));
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createSparkleEffect({required Vector2 position, required Color color, required int count}) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.5,
        generator: (i) {
          final angle = _random.nextDouble() * 2 * pi;
          final speed = 50 + _random.nextDouble() * 40;
          final velocity = Vector2(cos(angle), sin(angle)) * speed;

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2(0, 40),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
                final size = 3 * (1.0 - particle.progress * 0.5);
                final path = Path();
                for (int j = 0; j < 4; j++) {
                  final a = (j * pi / 2);
                  if (j == 0) path.moveTo(cos(a) * size, sin(a) * size);
                  else path.lineTo(cos(a) * size, sin(a) * size);
                }
                path.close();
                canvas.drawPath(path, Paint()..color = color.withOpacity(opacity));
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createRisingEffect({required Vector2 position, required Color color, required int count, required double speed}) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.8,
        generator: (i) {
          final spreadX = (_random.nextDouble() - 0.5) * 30;
          return AcceleratedParticle(
            position: position.clone() + Vector2(spreadX, 0),
            speed: Vector2(0, -speed),
            acceleration: Vector2(0, -20),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
                canvas.drawCircle(Offset.zero, 3, Paint()..color = color.withOpacity(opacity));
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createSmokeEffect({required Vector2 position, required int count}) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.8,
        generator: (i) {
          final spreadX = (_random.nextDouble() - 0.5) * 25;
          return AcceleratedParticle(
            position: position.clone() + Vector2(spreadX, 0),
            speed: Vector2((_random.nextDouble() - 0.5) * 15, -30 - _random.nextDouble() * 20),
            acceleration: Vector2(0, -10),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final progress = particle.progress;
                final opacity = (0.5 - progress * 0.5).clamp(0.0, 1.0);
                final size = 6 + progress * 10;
                canvas.drawCircle(Offset.zero, size, Paint()..color = Colors.grey.withOpacity(opacity));
              },
            ),
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createGroundCircle({required Vector2 position, required Color color}) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: 1,
        lifespan: 0.6,
        generator: (i) {
          return ComputedParticle(
            renderer: (canvas, particle) {
              final progress = particle.progress;
              final opacity = (1.0 - progress).clamp(0.0, 1.0);
              final radius = 15 + progress * 35;
              canvas.drawCircle(
                Offset(position.x, position.y),
                radius,
                Paint()
                  ..color = color.withOpacity(opacity * 0.4)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2,
              );
            },
          );
        },
      ),
    );
  }

  ParticleSystemComponent _createCoinEffect({required Vector2 position, required int count}) {
    return ParticleSystemComponent(
      particle: Particle.generate(
        count: count,
        lifespan: 0.7,
        generator: (i) {
          final angle = -pi / 2 + (_random.nextDouble() - 0.5) * pi / 4;
          final speed = 130 + _random.nextDouble() * 80;
          final velocity = Vector2(cos(angle), sin(angle)) * speed;

          return AcceleratedParticle(
            position: position.clone(),
            speed: velocity,
            acceleration: Vector2(0, 350),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final opacity = (1.0 - particle.progress * 0.2).clamp(0.0, 1.0);
                final rotation = particle.progress * 3 * pi;
                canvas.save();
                canvas.rotate(rotation);
                canvas.drawOval(const Rect.fromLTWH(-3, -2, 6, 4), Paint()..color = Colors.amber.withOpacity(opacity));
                canvas.restore();
              },
            ),
          );
        },
      ),
    );
  }
}

class _DamageNumber extends TextComponent {
  _DamageNumber({required Vector2 position, required int damage, required bool isCritical, required bool isHeal})
      : super(
          text: isHeal ? '+$damage' : '$damage',
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              fontSize: isCritical ? 26 : 18,
              fontWeight: FontWeight.bold,
              color: isHeal ? Colors.green : (isCritical ? Colors.yellow : Colors.white),
              shadows: const [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(MoveByEffect(Vector2(0, -45), EffectController(duration: 0.7, curve: Curves.easeOut)));
    add(OpacityEffect.fadeOut(EffectController(duration: 0.7, startDelay: 0.2)));
    add(RemoveEffect(delay: 0.9));
  }
}

class _BattleStartText extends TextComponent {
  _BattleStartText({required Vector2 position})
      : super(text: 'BATTLE START!', position: position, anchor: Anchor.center, textRenderer: TextPaint(style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 3, shadows: [Shadow(color: Colors.red, blurRadius: 15)])));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    scale = Vector2.all(0.3);
    add(ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 0.4, curve: Curves.elasticOut)));
    add(OpacityEffect.fadeOut(EffectController(duration: 1.5, startDelay: 0.8)));
    add(RemoveEffect(delay: 2.3));
  }
}

class _VictoryText extends TextComponent {
  _VictoryText({required Vector2 position})
      : super(text: 'VICTORY!', position: position, anchor: Anchor.center, textRenderer: TextPaint(style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.amber, letterSpacing: 4, shadows: [Shadow(color: Colors.orange, blurRadius: 15)])));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    scale = Vector2.all(0.3);
    add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.5, curve: Curves.elasticOut)));
    add(RemoveEffect(delay: 3.0));
  }
}

class _DefeatText extends TextComponent {
  _DefeatText({required Vector2 position})
      : super(text: 'DEFEAT', position: position, anchor: Anchor.center, textRenderer: TextPaint(style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 3)));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(OpacityEffect.fadeIn(EffectController(duration: 1.0)));
    add(RemoveEffect(delay: 3.0));
  }
}

class _RankUpText extends TextComponent {
  _RankUpText({required Vector2 position})
      : super(text: 'RANK UP!', position: position + Vector2(0, -40), anchor: Anchor.center, textRenderer: TextPaint(style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber, shadows: [Shadow(color: Colors.orange, blurRadius: 10)])));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    scale = Vector2.all(0.5);
    add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.3, curve: Curves.elasticOut)));
    add(MoveByEffect(Vector2(0, -20), EffectController(duration: 1.0, curve: Curves.easeOut)));
    add(OpacityEffect.fadeOut(EffectController(duration: 1.0, startDelay: 0.5)));
    add(RemoveEffect(delay: 1.5));
  }
}

class _NumberPopup extends TextComponent {
  _NumberPopup({required Vector2 position, required String text, required Color color})
      : super(text: text, position: position, anchor: Anchor.center, textRenderer: TextPaint(style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, shadows: const [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))])));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(MoveByEffect(Vector2(0, -25), EffectController(duration: 0.6, curve: Curves.easeOut)));
    add(OpacityEffect.fadeOut(EffectController(duration: 0.6, startDelay: 0.2)));
    add(RemoveEffect(delay: 0.8));
  }
}
