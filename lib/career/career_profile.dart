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

    double attribute(int index) =>
        (overall + modifiers[index]).clamp(20, 85).toDouble();

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
      pace: (json['pace'] as num).toDouble(),
      shooting: (json['shooting'] as num).toDouble(),
      passing: (json['passing'] as num).toDouble(),
      dribbling: (json['dribbling'] as num).toDouble(),
      defending: (json['defending'] as num).toDouble(),
      physical: (json['physical'] as num).toDouble(),
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
  final double pace;
  final double shooting;
  final double passing;
  final double dribbling;
  final double defending;
  final double physical;
  final int seed;

  CareerProfile increaseAttribute(String attribute) {
    return increaseAttributeBy(
      attribute,
      trainingIncrement(attributeValue(attribute)),
    );
  }

  CareerProfile increaseAttributeBy(String attribute, double amount) {
    double increased(double value) {
      final next = value + amount;
      return ((next.clamp(0, 99)) * 100).roundToDouble() / 100;
    }

    return CareerProfile(
      name: name,
      nationality: nationality,
      shirtNumber: shirtNumber,
      position: position,
      avatarId: avatarId,
      age: age,
      overall: overall,
      pace: attribute == 'pace' ? increased(pace) : pace,
      shooting: attribute == 'shooting' ? increased(shooting) : shooting,
      passing: attribute == 'passing' ? increased(passing) : passing,
      dribbling: attribute == 'dribbling' ? increased(dribbling) : dribbling,
      defending: attribute == 'defending' ? increased(defending) : defending,
      physical: attribute == 'physical' ? increased(physical) : physical,
      seed: seed,
    );
  }

  double attributeValue(String attribute) => switch (attribute) {
    'pace' => pace,
    'shooting' => shooting,
    'passing' => passing,
    'dribbling' => dribbling,
    'defending' => defending,
    'physical' => physical,
    _ => throw ArgumentError.value(attribute, 'attribute'),
  };

  static double trainingIncrement(double currentValue) {
    if (currentValue >= 90) return 0.33;
    if (currentValue >= 80) return 0.5;
    return 1;
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

String formatCareerAttribute(num value) {
  final rounded = (value.toDouble() * 100).round() / 100;
  if (rounded == rounded.truncateToDouble()) return rounded.toInt().toString();
  final source = rounded.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  return source.replaceFirst('.', ',');
}
