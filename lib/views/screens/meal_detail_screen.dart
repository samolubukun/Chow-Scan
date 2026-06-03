import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/nutrition_info.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/local_db_service.dart';
import '../../viewmodels/daily_intake_view_model.dart';
import '../../viewmodels/scan_view_model.dart';

class MealDetailScreen extends StatefulWidget {
  final NutritionInfo item;

  const MealDetailScreen({super.key, required this.item});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  AppColorSet get colors => AppColors.of(context);
  late NutritionInfo _item;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  double _getNutrientValue(String name) {
    return _item.nutrients
        .firstWhere(
          (n) => n.name.toLowerCase() == name.toLowerCase(),
          orElse: () => Nutrient(name: name, value: 0, unit: 'g'),
        )
        .value;
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.error : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(_isFavorite ? 'Added to Favorites' : 'Removed from Favorites'),
          ],
        ),
        backgroundColor: colors.surfaceAlt,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _shareMeal() {
    final text = 'Check out this meal I logged on ChowScan!\n\n'
        'Meal: ${_item.name}\n'
        'Calories: ${_item.calories.toStringAsFixed(0)} kcal\n'
        'Protein: ${_item.protein.toStringAsFixed(1)}g\n'
        'Carbs: ${_item.carbs.toStringAsFixed(1)}g\n'
        'Fat: ${_item.fat.toStringAsFixed(1)}g\n\n'
        'Logged on: ${DateFormat('MMMM dd, yyyy @ h:mm a').format(_item.date)}';
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.brand),
            SizedBox(width: 8),
            Text('Meal summary copied to clipboard!'),
          ],
        ),
        backgroundColor: colors.surfaceAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _duplicateMeal() async {
    final duplicate = NutritionInfo(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _item.name,
      imagePath: _item.imagePath,
      date: DateTime.now(),
      source: _item.source,
      nutrients: _item.nutrients,
      calories: _item.calories,
      protein: _item.protein,
      carbs: _item.carbs,
      fat: _item.fat,
    );

    await LocalDbService.instance.saveFoodIntake(duplicate);
    if (mounted) {
      context.read<DailyIntakeViewModel>().init();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.add_circle, color: AppColors.brand),
              SizedBox(width: 8),
              Text('Meal logged again for today!'),
            ],
          ),
          backgroundColor: colors.surfaceAlt,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showEditBottomSheet() {
    final nameController = TextEditingController(text: _item.name);
    final calorieController = TextEditingController(text: _item.calories.toStringAsFixed(0));
    final proteinController = TextEditingController(text: _item.protein.toStringAsFixed(1));
    final carbsController = TextEditingController(text: _item.carbs.toStringAsFixed(1));
    final fatController = TextEditingController(text: _item.fat.toStringAsFixed(1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Edit Meal Log',
                  style: AppTextStyles.heading1.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 20),
                _editField(
                  controller: nameController,
                  label: 'Meal Name',
                  icon: Icons.restaurant,
                  type: TextInputType.text,
                ),
                const SizedBox(height: 14),
                _editField(
                  controller: calorieController,
                  label: 'Calories (kcal)',
                  icon: Icons.local_fire_department,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _editField(
                  controller: proteinController,
                  label: 'Protein (g)',
                  icon: Icons.fitness_center,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _editField(
                  controller: carbsController,
                  label: 'Carbohydrates (g)',
                  icon: Icons.breakfast_dining,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _editField(
                  controller: fatController,
                  label: 'Fat (g)',
                  icon: Icons.opacity,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: colors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final newName = nameController.text.trim();
                          final newCalories = double.tryParse(calorieController.text) ?? _item.calories;
                          final newProtein = double.tryParse(proteinController.text) ?? _item.protein;
                          final newCarbs = double.tryParse(carbsController.text) ?? _item.carbs;
                          final newFat = double.tryParse(fatController.text) ?? _item.fat;

                          final updated = NutritionInfo(
                            id: _item.id,
                            name: newName,
                            imagePath: _item.imagePath,
                            date: _item.date,
                            source: _item.source,
                            nutrients: _item.nutrients,
                            calories: newCalories,
                            protein: newProtein,
                            carbs: newCarbs,
                            fat: newFat,
                          );

                          await LocalDbService.instance.updateFoodIntake(updated);
                          setState(() {
                            _item = updated;
                          });
                          if (mounted) {
                            context.read<DailyIntakeViewModel>().init();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Meal details updated'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.brand,
                          foregroundColor: colors.textOnBrand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          style: TextStyle(color: colors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.brand, size: 20),
            filled: true,
            fillColor: colors.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final fiber = _getNutrientValue('fiber');
    final sugar = _getNutrientValue('sugar');
    final sodium = _getNutrientValue('sodium');

    final hasImage = _item.imagePath.isNotEmpty && File(_item.imagePath).existsSync();

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image Section
            Stack(
              children: [
                Hero(
                  tag: 'meal_image_${_item.id}',
                  child: Container(
                    height: 320,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.card,
                      image: hasImage
                          ? DecorationImage(
                              image: FileImage(File(_item.imagePath)),
                              fit: BoxFit.cover,
                            )
                          : null,
                      gradient: !hasImage
                          ? const LinearGradient(
                              colors: [AppColors.brand, AppColors.accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                    ),
                    child: !hasImage
                        ? Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 72,
                              color: colors.textOnBrand,
                            ),
                          )
                        : null,
                  ),
                ),
                // Dark Gradient Overlay for title readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Top Action Buttons
                Positioned(
                  top: 50,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 22),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 20,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _shareMeal,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.ios_share, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _confirmDelete(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                // Title and Subtitle Overlay
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _item.name,
                        style: AppTextStyles.displaySmall.copyWith(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_item.source.name == 'scanFood' ? 'Food Scan' : _item.source.name == 'scanLabel' ? 'Label Scan' : 'Description'}  •  1 Serving  •  ${DateFormat('h:mm a').format(_item.date)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Action buttons row (plus, edit, heart)
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _duplicateMeal,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _showEditBottomSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.black, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _toggleFavorite,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _isFavorite
                                    ? AppColors.error.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: _isFavorite
                                    ? Border.all(color: AppColors.error, width: 1.5)
                                    : null,
                              ),
                              child: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: _isFavorite ? AppColors.error : Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Macro highlights cards row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _macroHighlightCard('Protein', '${_item.protein.toStringAsFixed(1)}g', true),
                      _macroHighlightCard('Carbs', '${_item.carbs.toStringAsFixed(1)}g', true),
                      _macroHighlightCard('Fiber', '${fiber.toStringAsFixed(1)}g', true),
                      _macroHighlightCard('Sugar', '${sugar.toStringAsFixed(1)}g', false),
                    ],
                  ),
                  if (_item.description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        _item.description,
                        style: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary, height: 1.4),
                      ),
                    ),
                  ],
                  if (_item.remedies.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildRemediesList(_item.remedies),
                  ],
                  if (_item.recommendations.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildRecommendationsList(_item.recommendations),
                  ],
                  const SizedBox(height: 32),

                  // Nutrition Breakdown Section Header
                  Text(
                    'Nutrients Breakdown',
                    style: AppTextStyles.heading1.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // List of detailed nutrients
                  Container(
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        _nutrientRow('Calories', '${_item.calories.toStringAsFixed(0)} kcal', 'kcal'),
                        Divider(color: colors.border, height: 1),
                        _nutrientRow('Protein', '${_item.protein.toStringAsFixed(1)} g', 'g'),
                        Divider(color: colors.border, height: 1),
                        _nutrientRow('Total Carbohydrates', '${_item.carbs.toStringAsFixed(1)} g', 'g'),
                        Divider(color: colors.border, height: 1),
                        _nutrientRow('Dietary Fiber', '${fiber.toStringAsFixed(1)} g', 'g'),
                        Divider(color: colors.border, height: 1),
                        _nutrientRow('Sugars', '${sugar.toStringAsFixed(1)} g', 'g'),
                        Divider(color: colors.border, height: 1),
                        _nutrientRow('Total Fat', '${_item.fat.toStringAsFixed(1)} g', 'g'),
                        if (sodium > 0) ...[
                          Divider(color: colors.border, height: 1),
                          _nutrientRow('Sodium', '${sodium.toStringAsFixed(0)} mg', 'mg'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Optimal quantity banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'OPTIMAL QUANTITY',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroHighlightCard(String label, String value, bool isHighPositive) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isHighPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 11,
                color: isHighPositive ? AppColors.success : AppColors.brand,
              ),
              const SizedBox(width: 2),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemediesList(List<Map<String, String>> remedies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'REMEDIES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFC5E1A5) : colors.textTertiary, letterSpacing: 0.5),
            ),
            SizedBox(width: 4),
            Icon(Icons.lightbulb_outline, size: 14, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFC5E1A5) : colors.textTertiary),
          ],
        ),
        const SizedBox(height: 8),
        ...remedies.map((rem) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rem['title'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(rem['desc'] ?? '',
                            style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildRecommendationsList(List<Map<String, String>> recs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECOMMENDATIONS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        ...recs.map((rec) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rec['title'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(rec['desc'] ?? '',
                            style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _nutrientRow(String name, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: AppTextStyles.bodyLarge.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        content: const Text('Remove this item from your log?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DailyIntakeViewModel>().deleteItem(_item);
              context.read<ScanViewModel>().loadHistory();
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}


