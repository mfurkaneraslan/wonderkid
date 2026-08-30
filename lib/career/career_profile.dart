class CareerProfile {
  const CareerProfile({
    required this.name,
    required this.nationality,
    required this.shirtNumber,
    required this.position,
    required this.avatarId,
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
    int avatarId = 3,
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
      avatarId: avatarId,
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

  factory CareerProfile.fromJson(Map<String, dynamic> json) {
    return CareerProfile(
      name: json['name'] as String,
      nationality: json['nationality'] as String,
      shirtNumber: json['shirtNumber'] as int,
      position: json['position'] as String,
      avatarId: json['avatarId'] as int,
      age: json['age'] as int,
      overall: json['overall'] as int,
      pace: json['pace'] as int,
      shooting: json['shooting'] as int,
      passing: json['passing'] as int,
      dribbling: json['dribbling'] as int,
      defending: json['defending'] as int,
      physical: json['physical'] as int,
      seed: json['seed'] as int,
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
  final int avatarId;
  final int age;
  final int overall;
  final int pace;
  final int shooting;
  final int passing;
  final int dribbling;
  final int defending;
  final int physical;
  final int seed;

  CareerProfile increaseAttribute(String attribute) {
    return CareerProfile(
      name: name,
      nationality: nationality,
      shirtNumber: shirtNumber,
      position: position,
      avatarId: avatarId,
      age: age,
      overall: overall,
      pace: pace + (attribute == 'pace' ? 1 : 0),
      shooting: shooting + (attribute == 'shooting' ? 1 : 0),
      passing: passing + (attribute == 'passing' ? 1 : 0),
      dribbling: dribbling + (attribute == 'dribbling' ? 1 : 0),
      defending: defending + (attribute == 'defending' ? 1 : 0),
      physical: physical + (attribute == 'physical' ? 1 : 0),
      seed: seed,
    );
  }

  String get avatarAssetPath => 'assets/players/avatar_$avatarId.webp';

  Map<String, dynamic> toJson() => {
    'name': name,
    'nationality': nationality,
    'shirtNumber': shirtNumber,
    'position': position,
    'avatarId': avatarId,
    'age': age,
    'overall': overall,
    'pace': pace,
    'shooting': shooting,
    'passing': passing,
    'dribbling': dribbling,
    'defending': defending,
    'physical': physical,
    'seed': seed,
  };

  static int _stableHash(String value) {
    var hash = 2166136261;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}
