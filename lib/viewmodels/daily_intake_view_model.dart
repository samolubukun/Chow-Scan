import 'package:flutter/foundation.dart';
import '../models/nutrition_info.dart';
import '../models/user_profile.dart';
import '../services/local_db_service.dart';

class DailyIntakeViewModel extends ChangeNotifier {
  final LocalDbService _db;
  DateTime _selectedDate = DateTime.now();
  List<NutritionInfo> _intakeItems = [];
  Map<String, double> _totals = {};
  UserProfile? _profile;

  DailyIntakeViewModel(this._db);

  DateTime get selectedDate => _selectedDate;
  List<NutritionInfo> get intakeItems => _intakeItems;
  Map<String, double> get totals => _totals;
  UserProfile? get profile => _profile;

  double get calories => _totals['calories'] ?? 0;
  double get protein => _totals['protein'] ?? 0;
  double get carbs => _totals['carbs'] ?? 0;
  double get fat => _totals['fat'] ?? 0;
  double get fiber => _totals['fiber'] ?? 0;

  double get calorieGoal => _profile?.dailyCalorieGoal ?? 2000;
  double get proteinGoal => _profile?.dailyProteinGoal ?? 50;
  double get carbsGoal => _profile?.dailyCarbsGoal ?? 250;
  double get fatGoal => _profile?.dailyFatGoal ?? 65;

  Future<void> init() async {
    _profile = await _db.getProfile();
    await loadDate(_selectedDate);
  }

  Future<void> loadDate(DateTime date) async {
    _selectedDate = date;
    _intakeItems = await _db.getFoodIntake(date);
    _totals = await _db.getTotalNutrients(date);
    notifyListeners();
  }

  Future<void> deleteItem(NutritionInfo item) async {
    await _db.deleteFoodIntake(item.id, _selectedDate);
    await loadDate(_selectedDate);
  }

  void selectDate(DateTime date) {
    loadDate(date);
  }
}
