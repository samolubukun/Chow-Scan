class Nutrient {
  final String name;
  final double value;
  final String unit;
  final double dailyValue;
  final NutrientCategory category;

  const Nutrient({
    required this.name,
    required this.value,
    required this.unit,
    this.dailyValue = 0,
    this.category = NutrientCategory.moderate,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'unit': unit,
    'dailyValue': dailyValue,
    'category': category.name,
  };

  factory Nutrient.fromJson(Map<String, dynamic> json) => Nutrient(
    name: json['name'] ?? '',
    value: (json['value'] ?? 0).toDouble(),
    unit: json['unit'] ?? 'g',
    dailyValue: (json['dailyValue'] ?? 0).toDouble(),
    category: NutrientCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => NutrientCategory.moderate,
    ),
  );
}

enum NutrientCategory { optimal, moderate, limit, insufficient }

class NutritionInfo {
  final String id;
  final String name;
  final String imagePath;
  final DateTime date;
  final NutritionSource source;
  final List<Nutrient> nutrients;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String description;
  final List<Map<String, String>> remedies;
  final List<Map<String, String>> recommendations;

  const NutritionInfo({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.date,
    required this.source,
    required this.nutrients,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.description = '',
    this.remedies = const [],
    this.recommendations = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'date': date.toIso8601String(),
    'source': source.name,
    'nutrients': nutrients.map((n) => n.toJson()).toList(),
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'description': description,
    'remedies': remedies,
    'recommendations': recommendations,
  };

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    imagePath: json['imagePath'] ?? '',
    date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    source: NutritionSource.values.firstWhere(
      (s) => s.name == json['source'],
      orElse: () => NutritionSource.scanLabel,
    ),
    nutrients: (json['nutrients'] as List? ?? [])
        .map((n) => Nutrient.fromJson(n))
        .toList(),
    calories: (json['calories'] ?? 0).toDouble(),
    protein: (json['protein'] ?? 0).toDouble(),
    carbs: (json['carbs'] ?? 0).toDouble(),
    fat: (json['fat'] ?? 0).toDouble(),
    description: json['description'] ?? '',
    remedies: (json['remedies'] as List?)
            ?.map((e) => Map<String, String>.from(e as Map))
            .toList() ??
        [],
    recommendations: (json['recommendations'] as List?)
            ?.map((e) => Map<String, String>.from(e as Map))
            .toList() ??
        [],
  );

  double get fiber => nutrients
      .firstWhere((n) => n.name.toLowerCase() == 'fiber',
          orElse: () => const Nutrient(name: 'fiber', value: 0, unit: 'g'))
      .value;
}

enum NutritionSource { scanLabel, scanFood, description, manual }
