class CareerShopState {
  const CareerShopState({
    this.balanceEuro = 0,
    this.categoryLevels = const <String, int>{},
  });

  factory CareerShopState.initial(int weeklySalaryEuro) {
    return const CareerShopState();
  }

  factory CareerShopState.fromJson(Map<String, dynamic> json) {
    final rawLevels = json['categoryLevels'] as Map<String, dynamic>?;
    return CareerShopState(
      balanceEuro: json['balanceEuro'] as int? ?? 0,
      categoryLevels: rawLevels == null
          ? const <String, int>{}
          : rawLevels.map(
              (category, level) => MapEntry(category, level as int),
            ),
    );
  }

  final int balanceEuro;
  final Map<String, int> categoryLevels;

  int levelFor(String categoryId) => categoryLevels[categoryId] ?? 0;

  CareerShopState purchase({
    required String categoryId,
    required int level,
    required int priceEuro,
  }) {
    return CareerShopState(
      balanceEuro: balanceEuro - priceEuro,
      categoryLevels: {...categoryLevels, categoryId: level},
    );
  }

  CareerShopState credit(int amountEuro) {
    return CareerShopState(
      balanceEuro: balanceEuro + amountEuro,
      categoryLevels: categoryLevels,
    );
  }

  Map<String, dynamic> toJson() => {
    'balanceEuro': balanceEuro,
    'categoryLevels': categoryLevels,
  };
}
