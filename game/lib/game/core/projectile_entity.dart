import 'dart:math';
import 'hero_entity.dart';

enum ProjectileType { arrow, fireball, icicle }

class ProjectileEntity {
  final String id;
  final ProjectileType type;
  final HeroEntity target;
  double x; // Current X (col * cellSize) - simplified to logic coordinates?
  // Actually, for smoothness, projectiles need visual coordinates.
  // But logic runs on Grid.
  // Let's use Grid Coordinates (double) for logic.
  double y; // Current Y (row * cellSize)
  final double damage;
  final double speed; // Cells per second

  bool hasHit = false;

  ProjectileEntity({
    required this.id,
    required this.type,
    required this.target,
    required this.x,
    required this.y,
    required this.damage,
    this.speed = 8.0,
  });

  void update(double dt) {
    if (hasHit) return;

    // Target might be dead or null logic handled by manager?
    // If target is dead, just fly to last known position or disappear?
    // For MVP, if target dead, projectile disappears immediately.
    if (target.isDead) {
      hasHit = true;
      return;
    }

    double tx = target.col.toDouble();
    double ty = target.row.toDouble();

    double dx = tx - x;
    double dy = ty - y;
    double dist = sqrt(dx * dx + dy * dy);

    if (dist < 0.5) {
      // Hit radius
      hasHit = true;
      target.takeDamage(damage.toInt());
    } else {
      double moveStep = speed * dt;
      x += (dx / dist) * moveStep;
      y += (dy / dist) * moveStep;
    }
  }
}
