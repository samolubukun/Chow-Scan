import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../viewmodels/describe_meal_view_model.dart';
import '../../models/nutrition_info.dart';
import '../widgets/nutrient_result_card.dart';

class DescribeMealScreen extends StatefulWidget {
  const DescribeMealScreen({super.key});

  @override
  State<DescribeMealScreen> createState() => _DescribeMealScreenState();
}

class _DescribeMealScreenState extends State<DescribeMealScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(title: const Text('Describe Meal'), backgroundColor: Colors.transparent),
      body: Consumer<DescribeMealViewModel>(builder: (context, vm, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!vm.hasResult && !vm.isAnalyzing) _buildInputPrompt(context, colors, vm),
              if (vm.isAnalyzing) _buildAnalyzing(colors),
              if (vm.hasResult && vm.nutritionInfo != null) _buildResults(context, colors, vm, vm.nutritionInfo!),
              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(vm.errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInputPrompt(BuildContext context, AppColorSet colors, DescribeMealViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.info.withValues(alpha: 0.2), AppColors.info.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.edit_note, color: AppColors.info, size: 30),
          ),
          const SizedBox(height: 20),
          Text('Describe What You Ate', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(
            'Type a detailed description of your meal including ingredients, portion sizes, and preparation method.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Grilled chicken breast with steamed broccoli and brown rice...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () => vm.analyze(_controller.text),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Analyze Meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08);
  }

  Widget _buildAnalyzing(AppColorSet colors) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.info.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Analyzing Description...', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text('Estimating nutritional content from your description', style: AppTextStyles.bodySmall),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildResults(BuildContext context, AppColorSet colors, DescribeMealViewModel vm, NutritionInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NutrientResultCard(info: info, accentColor: AppColors.info),
        const SizedBox(height: 16),
        CalorieRing(calories: info.calories, barColor: AppColors.info),
        const SizedBox(height: 16),
        MacroBar(label: 'Protein', value: info.protein, unit: 'g', goal: 50, color: AppColors.brand),
        MacroBar(label: 'Carbs', value: info.carbs, unit: 'g', goal: 250, color: AppColors.info),
        MacroBar(label: 'Fat', value: info.fat, unit: 'g', goal: 65, color: AppColors.accent),
        const SizedBox(height: 8),
        ...info.nutrients
            .where((n) => !['Calories', 'Protein', 'Carbohydrate', 'Fat'].contains(n.name))
            .map((n) => NutrientTile(nutrient: n)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              vm.saveToIntake();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Added to daily intake'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add to Daily Intake'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 56,
          child: OutlinedButton.icon(
            onPressed: () => vm.clearResults(),
            icon: const Icon(Icons.refresh),
            label: const Text('Analyze Another Meal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textPrimary,
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }
}
