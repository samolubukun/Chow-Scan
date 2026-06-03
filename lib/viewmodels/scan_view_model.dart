import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/nutrition_info.dart';
import '../services/model_manager.dart';
import '../services/image_service.dart';
import '../services/local_db_service.dart';

enum ScanMode { productLabel, foodPlate }

class ScanViewModel extends ChangeNotifier {
  final ModelManager _modelManager;
  final ImageService _imageService;
  final LocalDbService _db;

  ScanMode _mode = ScanMode.productLabel;
  File? _image;
  bool _isAnalyzing = false;
  String? _analysisResult;
  NutritionInfo? _nutritionInfo;
  String? _errorMessage;
  List<NutritionInfo> _history = [];

  // Servings and log time customizable by the user
  double _servings = 1.0;
  DateTime _logTime = DateTime.now();

  ScanViewModel(this._modelManager, this._imageService, this._db) {
    loadHistory();
  }

  ScanMode get mode => _mode;
  File? get image => _image;
  bool get isAnalyzing => _isAnalyzing;
  bool get hasImage => _image != null;
  bool get hasResult => _nutritionInfo != null;
  String? get analysisResult => _analysisResult;
  NutritionInfo? get nutritionInfo => _nutritionInfo;
  String? get errorMessage => _errorMessage;
  List<NutritionInfo> get history => _history;

  double get servings => _servings;
  DateTime get logTime => _logTime;

  Future<void> loadHistory() async {
    try {
      final all = await _db.getAllScanHistory();
      _history = all.where((item) {
        if (_mode == ScanMode.productLabel) {
          return item.source == NutritionSource.scanLabel;
        } else {
          return item.source == NutritionSource.scanFood;
        }
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading scan history: $e');
    }
  }

  void setMode(ScanMode mode) {
    _mode = mode;
    clearImage();
    loadHistory();
  }

  void setServings(double val) {
    _servings = val;
    notifyListeners();
  }

  void setLogTime(DateTime time) {
    _logTime = time;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final path = await _imageService.pickFromGallery();
    if (path != null) {
      _image = File(path);
      clearResults();
      notifyListeners();
    }
  }

  Future<void> takePhoto() async {
    final path = await _imageService.pickFromCamera();
    if (path != null) {
      _image = File(path);
      clearResults();
      notifyListeners();
    }
  }

  void setImage(File file) {
    _image = file;
    clearResults();
    notifyListeners();
  }

  Future<void> analyze() async {
    if (_image == null || _isAnalyzing) return;
    _isAnalyzing = true;
    _errorMessage = null;
    _servings = 1.0;
    _logTime = DateTime.now();
    notifyListeners();

    try {
      final bytes = await _image!.readAsBytes();
      
      // Prompt optimized to output description, remedies, recommendations, and dailyValue %
      final prompt = _mode == ScanMode.productLabel
          ? '''
Analyze this product nutrition label image. Extract and return ONLY valid JSON with this exact structure:
{
  "name": "Product Name",
  "description": "A 1-2 sentence description of the product and its general nutritional nature.",
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
  "fat": 0,
  "remedies": [
    {"title": "Warning Category (e.g. High Sodium Content)", "desc": "Explanation of risks and why to limit this (1 sentence)."}
  ],
  "recommendations": [
    {"title": "Healthy Option (e.g. Fresh spinach)", "desc": "How this option balances the diet (1 sentence)."}
  ]
}
Category must be one of: "optimal", "moderate", "limit", "insufficient". Set dailyValue as the percentage (0 to 100) of recommended daily intake. Use realistic values.
Return ONLY valid raw JSON without code blocks or headers.'''
          : '''
Analyze this food plate image. Identify all food items, estimate portions, and return ONLY valid JSON:
{
  "name": "Descriptive Meal Name",
  "description": "A 1-2 sentence description of the meal and culinary style.",
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
  "fat": 0,
  "remedies": [
    {"title": "Nutrient Alert (e.g. Moderate Carbohydrates)", "desc": "Brief advice on balancing this intake (1 sentence)."}
  ],
  "recommendations": [
    {"title": "Healthy Addition (e.g. Mixed green salad)", "desc": "Why this matches well (1 sentence)."}
  ]
}
Category must be one of: "optimal", "moderate", "limit", "insufficient". Set dailyValue as the percentage (0 to 100).
Return ONLY valid raw JSON without code blocks or headers.''';

      final response = await _modelManager.generateMultimodalResponse(prompt, bytes);
      if (response != null) {
        _analysisResult = response;
        final parsed = _parseNutritionJson(response);
        if (parsed != null) {
          _nutritionInfo = parsed;
        } else {
          _setError('Could not extract nutritional details. Please make sure the photo is well-lit and covers the full item.');
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
    debugPrint('RAW GEMMA OUTPUT:\n$raw');
    try {
      String json = raw.trim();
      
      // Clean up markdown block if present
      if (json.startsWith('```')) {
        final lines = json.split('\n');
        if (lines.isNotEmpty && lines.first.startsWith('```')) {
          lines.removeAt(0);
        }
        if (lines.isNotEmpty && lines.last.startsWith('```')) {
          lines.removeLast();
        }
        json = lines.join('\n').trim();
      }

      // Find first '{' and last '}'
      final start = json.indexOf('{');
      final end = json.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        json = json.substring(start, end + 1);
      }

      final Map<String, dynamic> data = jsonDecode(json) as Map<String, dynamic>;

      final nutrients = (data['nutrients'] as List? ?? [])
          .map((n) => Nutrient(
                name: n['name'] ?? '',
                value: _parseDouble(n['value']),
                unit: n['unit'] ?? 'g',
                dailyValue: _parseDouble(n['dailyValue']),
                category: _parseCategory(n['category']?.toString()),
              ))
          .toList();

      final remediesList = (data['remedies'] as List? ?? [])
          .map((e) => {
                'title': e['title']?.toString() ?? '',
                'desc': e['desc']?.toString() ?? '',
              })
          .toList();

      final recsList = (data['recommendations'] as List? ?? [])
          .map((e) => {
                'title': e['title']?.toString() ?? '',
                'desc': e['desc']?.toString() ?? '',
              })
          .toList();

      return NutritionInfo(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: data['name'] ?? 'Unknown',
        imagePath: _image?.path ?? '',
        date: DateTime.now(),
        source: _mode == ScanMode.productLabel
            ? NutritionSource.scanLabel
            : NutritionSource.scanFood,
        nutrients: nutrients,
        calories: _parseDouble(data['calories']),
        protein: _parseDouble(data['protein']),
        carbs: _parseDouble(data['carbs']),
        fat: _parseDouble(data['fat']),
        description: data['description'] ?? '',
        remedies: remediesList,
        recommendations: recsList,
      );
    } catch (e) {
      debugPrint('JSON parse error: $e. Attempting regex fallback...');
      return _regexFallbackParse(raw);
    }
  }

  NutritionInfo? _regexFallbackParse(String raw) {
    try {
      // Try to extract name
      String name = 'Unknown Meal';
      final nameReg = RegExp(r'"name"\s*:\s*"([^"]+)"', caseSensitive: false);
      final nameMatch = nameReg.firstMatch(raw);
      if (nameMatch != null) {
        name = nameMatch.group(1) ?? 'Unknown Meal';
      }

      // Try to extract description
      String description = '';
      final descReg = RegExp(r'"description"\s*:\s*"([^"]+)"', caseSensitive: false);
      final descMatch = descReg.firstMatch(raw);
      if (descMatch != null) {
        description = descMatch.group(1) ?? '';
      }

      // Try to extract main macros
      double calories = 0;
      final calReg = RegExp(r'"calories"\s*:\s*(\d+(\.\d+)?)', caseSensitive: false);
      final calMatch = calReg.firstMatch(raw);
      if (calMatch != null) {
        calories = double.tryParse(calMatch.group(1) ?? '0') ?? 0;
      }

      double protein = 0;
      final protReg = RegExp(r'"protein"\s*:\s*(\d+(\.\d+)?)', caseSensitive: false);
      final protMatch = protReg.firstMatch(raw);
      if (protMatch != null) {
        protein = double.tryParse(protMatch.group(1) ?? '0') ?? 0;
      }

      double carbs = 0;
      final carbReg = RegExp(r'"carbs"\s*:\s*(\d+(\.\d+)?)', caseSensitive: false);
      final carbMatch = carbReg.firstMatch(raw);
      if (carbMatch != null) {
        carbs = double.tryParse(carbMatch.group(1) ?? '0') ?? 0;
      }

      double fat = 0;
      final fatReg = RegExp(r'"fat"\s*:\s*(\d+(\.\d+)?)', caseSensitive: false);
      final fatMatch = fatReg.firstMatch(raw);
      if (fatMatch != null) {
        fat = double.tryParse(fatMatch.group(1) ?? '0') ?? 0;
      }

      final List<Nutrient> nutrients = [
        Nutrient(name: 'Calories', value: calories, unit: 'kcal', dailyValue: (calories / 2000) * 100, category: NutrientCategory.moderate),
        Nutrient(name: 'Protein', value: protein, unit: 'g', dailyValue: (protein / 50) * 100, category: NutrientCategory.optimal),
        Nutrient(name: 'Carbohydrate', value: carbs, unit: 'g', dailyValue: (carbs / 250) * 100, category: NutrientCategory.moderate),
        Nutrient(name: 'Fat', value: fat, unit: 'g', dailyValue: (fat / 65) * 100, category: NutrientCategory.moderate),
      ];

      return NutritionInfo(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        imagePath: _image?.path ?? '',
        date: DateTime.now(),
        source: _mode == ScanMode.productLabel
            ? NutritionSource.scanLabel
            : NutritionSource.scanFood,
        nutrients: nutrients,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        description: description,
      );
    } catch (e) {
      debugPrint('Regex Fallback Parse failed: $e');
      return null;
    }
  }

  NutrientCategory _parseCategory(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'optimal': return NutrientCategory.optimal;
      case 'moderate': return NutrientCategory.moderate;
      case 'limit': return NutrientCategory.limit;
      case 'insufficient': return NutrientCategory.insufficient;
      default: return NutrientCategory.moderate;
    }
  }

  Future<void> saveToIntake() async {
    if (_nutritionInfo == null) return;

    // Scale values according to selected portion sizes
    final scaledNutrients = _nutritionInfo!.nutrients.map((n) => Nutrient(
      name: n.name,
      value: n.value * _servings,
      unit: n.unit,
      dailyValue: n.dailyValue * _servings,
      category: n.category,
    )).toList();

    final loggedInfo = NutritionInfo(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nutritionInfo!.name,
      imagePath: _nutritionInfo!.imagePath,
      date: _logTime,
      source: _nutritionInfo!.source,
      nutrients: scaledNutrients,
      calories: _nutritionInfo!.calories * _servings,
      protein: _nutritionInfo!.protein * _servings,
      carbs: _nutritionInfo!.carbs * _servings,
      fat: _nutritionInfo!.fat * _servings,
      description: _nutritionInfo!.description,
      remedies: _nutritionInfo!.remedies,
      recommendations: _nutritionInfo!.recommendations,
    );

    await _db.saveFoodIntake(loggedInfo);
    clearImage();
    loadHistory();
  }

  void clearResults() {
    _analysisResult = null;
    _nutritionInfo = null;
    _errorMessage = null;
    _servings = 1.0;
    _logTime = DateTime.now();
    notifyListeners();
  }

  void clearImage() {
    _image = null;
    clearResults();
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }
}
