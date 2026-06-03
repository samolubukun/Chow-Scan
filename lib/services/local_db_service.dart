import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nutrition_info.dart';
import '../models/user_profile.dart';

class LocalDbService {
  static const _profileKey = 'smf_user_profile';
  static const _intakeKey = 'smf_daily_intake_';
  static const _intakeListKey = 'smf_intake_dates';

  static final LocalDbService instance = LocalDbService._();
  LocalDbService._();

  // --- User Profile ---
  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw));
  }

  Future<bool> hasProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_profileKey);
  }

  // --- Daily Intake ---
  Future<void> saveFoodIntake(NutritionInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _intakeKey + info.date.toIso8601String().split('T')[0];
    final existing = prefs.getString(dateKey);
    final List<dynamic> items = existing != null ? jsonDecode(existing) : [];
    items.add(info.toJson());
    await prefs.setString(dateKey, jsonEncode(items));
    final dates = prefs.getStringList(_intakeListKey) ?? [];
    final dateStr = info.date.toIso8601String().split('T')[0];
    if (!dates.contains(dateStr)) {
      dates.add(dateStr);
      await prefs.setStringList(_intakeListKey, dates);
    }
  }

  Future<void> updateFoodIntake(NutritionInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _intakeKey + info.date.toIso8601String().split('T')[0];
    final existing = prefs.getString(dateKey);
    if (existing == null) return;
    final List<dynamic> items = jsonDecode(existing);
    final idx = items.indexWhere((e) => e['id'] == info.id);
    if (idx != -1) {
      items[idx] = info.toJson();
      await prefs.setString(dateKey, jsonEncode(items));
    }
  }

  Future<List<NutritionInfo>> getFoodIntake(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _intakeKey + date.toIso8601String().split('T')[0];
    final raw = prefs.getString(dateKey);
    if (raw == null) return [];
    final List<dynamic> items = jsonDecode(raw);
    return items.map((e) => NutritionInfo.fromJson(e)).toList();
  }

  Future<void> deleteFoodIntake(String id, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _intakeKey + date.toIso8601String().split('T')[0];
    final raw = prefs.getString(dateKey);
    if (raw == null) return;
    final List<dynamic> items = jsonDecode(raw);
    items.removeWhere((e) => e['id'] == id);
    if (items.isEmpty) {
      await prefs.remove(dateKey);
      final dates = prefs.getStringList(_intakeListKey) ?? [];
      dates.remove(date.toIso8601String().split('T')[0]);
      await prefs.setStringList(_intakeListKey, dates);
    } else {
      await prefs.setString(dateKey, jsonEncode(items));
    }
  }

  Future<Map<String, double>> getTotalNutrients(DateTime date) async {
    final items = await getFoodIntake(date);
    if (items.isEmpty) return {};

    double calories = 0, protein = 0, carbs = 0, fat = 0, fiber = 0;
    for (final item in items) {
      calories += item.calories;
      protein += item.protein;
      carbs += item.carbs;
      fat += item.fat;
      fiber += item.fiber;
    }
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
    };
  }

  Future<List<String>> getDatesWithIntake() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_intakeListKey) ?? [];
  }

  Future<List<NutritionInfo>> getAllScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final dates = prefs.getStringList(_intakeListKey) ?? [];
    final List<NutritionInfo> allScans = [];
    for (final dateStr in dates) {
      final dateKey = _intakeKey + dateStr;
      final raw = prefs.getString(dateKey);
      if (raw != null) {
        final List<dynamic> items = jsonDecode(raw);
        allScans.addAll(items.map((e) => NutritionInfo.fromJson(e)));
      }
    }
    // Sort by date descending
    allScans.sort((a, b) => b.date.compareTo(a.date));
    return allScans;
  }
}
