import 'hero_data.dart';

class ItemData {
  final String id;
  final String name;
  final String iconPath; // For MVP use Icons.code or similar if image missing
  final HeroStats stats; // Bonus stats
  final int cost;
  final int rarity; // 0: Common, 1: Rare, 2: Epic

  const ItemData({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.stats,
    this.cost = 5,
    this.rarity = 0,
  });
}

const List<ItemData> allItems = [
  ItemData(
    id: 'sword',
    name: 'Iron Sword',
    iconPath: 'assets/images/items/sword.png',
    stats: HeroStats(
      attack: 20,
      maxHp: 0,
      defense: 0,
      attackSpeed: 0,
      range: 0,
      moveSpeed: 0,
    ),
    cost: 5,
    rarity: 0,
  ),
  ItemData(
    id: 'armor',
    name: 'Chainmail',
    iconPath: 'assets/images/items/armor.png',
    stats: HeroStats(
      attack: 0,
      maxHp: 200,
      defense: 15,
      attackSpeed: 0,
      range: 0,
      moveSpeed: 0,
    ),
    cost: 5,
    rarity: 0,
  ),
  ItemData(
    id: 'bow',
    name: 'Rapid Bow',
    iconPath: 'assets/images/items/bow.png',
    stats: HeroStats(
      attack: 10,
      maxHp: 0,
      defense: 0,
      attackSpeed: 0.3,
      range: 1,
      moveSpeed: 0,
    ),
    cost: 8,
    rarity: 1,
  ),
];
