class UserProfile {
  final String name;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String? gender;
  final double dailyCalorieGoal;
  final double dailyProteinGoal;
  final double dailyCarbsGoal;
  final double dailyFatGoal;
  final List<String> healthConditions;
  final List<String> dietaryPreferences;
  final bool onboardingComplete;

  const UserProfile({
    required this.name,
    this.age,
    this.weightKg,
    this.heightCm,
    this.gender,
    this.dailyCalorieGoal = 2000,
    this.dailyProteinGoal = 50,
    this.dailyCarbsGoal = 250,
    this.dailyFatGoal = 65,
    this.healthConditions = const [],
    this.dietaryPreferences = const [],
    this.onboardingComplete = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'gender': gender,
    'dailyCalorieGoal': dailyCalorieGoal,
    'dailyProteinGoal': dailyProteinGoal,
    'dailyCarbsGoal': dailyCarbsGoal,
    'dailyFatGoal': dailyFatGoal,
    'healthConditions': healthConditions,
    'dietaryPreferences': dietaryPreferences,
    'onboardingComplete': onboardingComplete,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] ?? '',
    age: json['age'],
    weightKg: json['weightKg']?.toDouble(),
    heightCm: json['heightCm']?.toDouble(),
    gender: json['gender'],
    dailyCalorieGoal: (json['dailyCalorieGoal'] ?? 2000).toDouble(),
    dailyProteinGoal: (json['dailyProteinGoal'] ?? 50).toDouble(),
    dailyCarbsGoal: (json['dailyCarbsGoal'] ?? 250).toDouble(),
    dailyFatGoal: (json['dailyFatGoal'] ?? 65).toDouble(),
    healthConditions: List<String>.from(json['healthConditions'] ?? []),
    dietaryPreferences: List<String>.from(json['dietaryPreferences'] ?? []),
    onboardingComplete: json['onboardingComplete'] ?? false,
  );

  UserProfile copyWith({
    String? name,
    int? age,
    double? weightKg,
    double? heightCm,
    String? gender,
    double? dailyCalorieGoal,
    double? dailyProteinGoal,
    double? dailyCarbsGoal,
    double? dailyFatGoal,
    List<String>? healthConditions,
    List<String>? dietaryPreferences,
    bool? onboardingComplete,
  }) => UserProfile(
    name: name ?? this.name,
    age: age ?? this.age,
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    gender: gender ?? this.gender,
    dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
    dailyProteinGoal: dailyProteinGoal ?? this.dailyProteinGoal,
    dailyCarbsGoal: dailyCarbsGoal ?? this.dailyCarbsGoal,
    dailyFatGoal: dailyFatGoal ?? this.dailyFatGoal,
    healthConditions: healthConditions ?? this.healthConditions,
    dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
  );
}
