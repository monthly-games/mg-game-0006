class SynergyData {
  final String id;
  final String name;
  final String description;
  final Map<int, String> thresholds; // Count -> Effect Description

  const SynergyData({
    required this.id,
    required this.name,
    required this.description,
    required this.thresholds,
  });
}

const List<SynergyData> allSynergies = [
  SynergyData(
    id: 'warrior',
    name: 'Warrior',
    description: 'Increases Defense of all Warriors.',
    thresholds: {3: '+20 Defense', 5: '+50 Defense'},
  ),
  SynergyData(
    id: 'archer',
    name: 'Archer',
    description: 'Increases Attack Speed of all Archers.',
    thresholds: {3: '+25% Attack Speed', 5: '+60% Attack Speed'},
  ),
  SynergyData(
    id: 'mage',
    name: 'Mage',
    description: 'Increases Attack of all Mages.',
    thresholds: {3: '+30 Attack', 5: '+80 Attack'},
  ),
];

class ActiveSynergy {
  final SynergyData data;
  final int count;
  final int activeThreshold;

  ActiveSynergy(this.data, this.count, this.activeThreshold);
}
