class CareerProfile {
  const CareerProfile({
    required this.name,
    required this.nationality,
    required this.shirtNumber,
    required this.position,
    required this.age,
    required this.overall,
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.dribbling,
    required this.defending,
    required this.physical,
    required this.seed,
  });

  factory CareerProfile.create({
    required String name,
    required String nationality,
    required int shirtNumber,
    required String position,
  }) {
    final seed = _stableHash('$name|$nationality|$shirtNumber|$position');
    const overall = 67;
    final modifiers = _attributeModifiers[position] ?? const [0, 0, 0, 0, 0, 0];

    int attribute(int index) => (overall + modifiers[index]).clamp(20, 85);

    return CareerProfile(
      name: name,
      nationality: nationality,
      shirtNumber: shirtNumber,
      position: position,
      age: 17,
      overall: overall,
      pace: attribute(0),
      shooting: attribute(1),
      passing: attribute(2),
      dribbling: attribute(3),
      defending: attribute(4),
      physical: attribute(5),
      seed: seed,
    );
  }

  static const _attributeModifiers = <String, List<int>>{
    'GK': [-20, -32, -7, -15, 3, 4],
    'LB': [3, -10, 0, 0, 3, 2],
    'CB': [-4, -14, -3, -6, 5, 5],
    'RB': [3, -10, 0, 0, 3, 2],
    'CDM': [-3, -6, 2, -2, 4, 4],
    'CM': [-2, -2, 4, 1, -1, 0],
    'CAM': [0, 1, 4, 4, -13, -5],
    'LM': [2, -1, 3, 2, -7, -2],
    'RM': [2, -1, 3, 2, -7, -2],
    'LW': [5, 1, -1, 4, -18, -3],
    'RW': [5, 1, -1, 4, -18, -3],
    'ST': [2, 4, -5, 1, -18, 0],
  };

  final String name;
  final String nationality;
  final int shirtNumber;
  final String position;
  final int age;
  final int overall;
  final int pace;
  final int shooting;
  final int passing;
  final int dribbling;
  final int defending;
  final int physical;
  final int seed;

  static int _stableHash(String value) {
    var hash = 2166136261;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}
