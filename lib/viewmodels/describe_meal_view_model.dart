import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/nutrition_info.dart';
import '../services/model_manager.dart';
import '../services/local_db_service.dart';

class DescribeMealViewModel extends ChangeNotifier {
  final ModelManager _modelManager;
  final LocalDbService _db;

  bool _isAnalyzing = false;
  String? _description;
  String? _analysisResult;
  NutritionInfo? _nutritionInfo;
  String? _errorMessage;

  DescribeMealViewModel(this._modelManager, this._db);

  bool get isAnalyzing => _isAnalyzing;
  String? get description => _description;
  String? get analysisResult => _analysisResult;
  NutritionInfo? get nutritionInfo => _nutritionInfo;
  String? get errorMessage => _errorMessage;
  bool get hasResult => _nutritionInfo != null;

  Future<void> analyze(String description) async {
    if (description.trim().isEmpty || _isAnalyzing) return;
    _description = description.trim();
    _isAnalyzing = true;
    _errorMessage = null;
    _analysisResult = null;
    _nutritionInfo = null;
    notifyListeners();

    try {
      final prompt = '''
You are a nutrition analysis AI. Analyze this meal description and return ONLY valid JSON:

Meal: "${description.trim()}"

Return exactly this JSON structure with realistic nutritional estimates:
{
  "name": "Meal Name",
  "nutrients": [
    {"name": "Calories", "value": 0, "unit": "kcal", "dailyValue": 0, "category": "moderate"},
    {"name": "Protein", "value": 0, "unit": "g", "dailyValue": 0, "category": "moderate"},
    {"name": "Carbohydrate", "value": 0, "unit": "g", "dailyValue": 0, "category": "moderate"},
    {"name": "Fat", "value": 0, "unit": "g", "dailyValue": 0, "category": "moderate"},
    {"name": "Fiber", "value": 0, "unit": "g", "dailyValue": 0, "category": "moderate"},
    {"name": "Sugar", "value": 0, "unit": "g", "dailyValue": 0, "category": "moderate"},
    {"name": "Sodium", "value": 0, "unit": "mg", "dailyValue": 0, "category": "moderate"}
  ],
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0
}
Category must be one of: "optimal", "moderate", "limit", "insufficient".
Numbers must be output as regular numeric values, NOT wrapped in double quotes. Return ONLY the JSON block. Do not write explanation, notes or preamble.''';

      final response = await _modelManager.generateResponse(prompt);
      if (response != null) {
        _analysisResult = response;
        final parsed = _parseNutritionJson(response);
        if (parsed != null) {
          _nutritionInfo = parsed;
        } else {
          _setError('Could not estimate nutrients from the description. Please describe the meal with more detail or ingredients.');
        }
      } else {
        _setError('Analysis failed. Ensure the AI model is downloaded and ready.');
      }
    } catch (e) {
      _setError('Analysis error: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^0-9.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  NutritionInfo? _parseNutritionJson(String raw) {
    try {
      String json = raw;
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        json = raw.substring(start, end + 1);
      }
      final data = jsonDecode(json) as Map<String, dynamic>;

      final nutrients = (data['nutrients'] as List? ?? [])
          .map((n) => Nutrient(
                name: n['name'] ?? '',
                value: _parseDouble(n['value']),
                unit: n['unit'] ?? 'g',
                dailyValue: _parseDouble(n['dailyValue']),
                category: switch (n['category']?.toString().toLowerCase()) {
                  'optimal' => NutrientCategory.optimal,
                  'limit' => NutrientCategory.limit,
                  'insufficient' => NutrientCategory.insufficient,
                  _ => NutrientCategory.moderate,
                },
              ))
          .toList();

      return NutritionInfo(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: data['name'] ?? 'Unknown Meal',
        imagePath: '',
        date: DateTime.now(),
        source: NutritionSource.description,
        nutrients: nutrients,
        calories: _parseDouble(data['calories']),
        protein: _parseDouble(data['protein']),
        carbs: _parseDouble(data['carbs']),
        fat: _parseDouble(data['fat']),
      );
    } catch (e) {
      debugPrint('JSON parse error: $e');
      return null;
    }
  }

  Future<void> saveToIntake() async {
    if (_nutritionInfo == null) return;
    await _db.saveFoodIntake(_nutritionInfo!);
    clearResults();
  }

  void clearResults() {
    _description = null;
    _analysisResult = null;
    _nutritionInfo = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }
}
