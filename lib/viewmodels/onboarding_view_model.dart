import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/local_db_service.dart';

class OnboardingViewModel extends ChangeNotifier {
  final LocalDbService _db;
  int _currentStep = 0;
  String _name = '';
  int? _age;
  double? _weight;
  double? _height;
  String? _gender;
  final List<String> _healthConditions = [];
  final List<String> _dietaryPreferences = [];
  double _calorieGoal = 2000;

  OnboardingViewModel(this._db);

  int get currentStep => _currentStep;
  String get name => _name;
  int? get age => _age;
  double? get weight => _weight;
  double? get height => _height;
  String? get gender => _gender;
  List<String> get healthConditions => _healthConditions;
  List<String> get dietaryPreferences => _dietaryPreferences;
  double get calorieGoal => _calorieGoal;
  int get totalSteps => 5;

  void setName(String v) { _name = v; notifyListeners(); }
  void setAge(int v) { _age = v; notifyListeners(); }
  void setWeight(double v) { _weight = v; notifyListeners(); }
  void setHeight(double v) { _height = v; notifyListeners(); }
  void setGender(String v) { _gender = v; notifyListeners(); }
  void setCalorieGoal(double v) { _calorieGoal = v; notifyListeners(); }

  void toggleHealthCondition(String condition) {
    if (_healthConditions.contains(condition)) {
      _healthConditions.remove(condition);
    } else {
      _healthConditions.add(condition);
    }
    notifyListeners();
  }

  void toggleDietaryPreference(String pref) {
    if (_dietaryPreferences.contains(pref)) {
      _dietaryPreferences.remove(pref);
    } else {
      _dietaryPreferences.add(pref);
    }
    notifyListeners();
  }

  void setStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    final profile = UserProfile(
      name: _name,
      age: _age,
      weightKg: _weight,
      heightCm: _height,
      gender: _gender,
      dailyCalorieGoal: _calorieGoal,
      healthConditions: List.from(_healthConditions),
      dietaryPreferences: List.from(_dietaryPreferences),
      onboardingComplete: true,
    );
    await _db.saveProfile(profile);
  }
}
