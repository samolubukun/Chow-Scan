import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/nutrition_info.dart';

class NutrientResultCard extends StatelessWidget {
  final NutritionInfo info;
  final Color accentColor;

  const NutrientResultCard({
    super.key,
    required this.info,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withValues(alpha: 0.12), AppColors.card.withValues(alpha: 0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.name, style: AppTextStyles.heading2),
                const SizedBox(height: 4),
                Text('${info.calories.toStringAsFixed(0)} kcal  •  ${info.protein.toStringAsFixed(1)}g protein  •  ${info.carbs.toStringAsFixed(1)}g carbs  •  ${info.fat.toStringAsFixed(1)}g fat',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, curve: Curves.easeOutCubic);
  }
}

class CalorieRing extends StatelessWidget {
  final double calories;
  final double goal;
  final Color barColor;

  const CalorieRing({
    super.key,
    required this.calories,
    this.goal = 2000,
    this.barColor = AppColors.brand,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (calories / goal).clamp(0.0, 1.0);
    final color = pct > 0.9 ? AppColors.error : pct > 0.7 ? AppColors.warning : barColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 6,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Text('${calories.toStringAsFixed(0)}', style: AppTextStyles.numericSmall),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calories', style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text('${(pct * 100).toStringAsFixed(0)}% of daily target (${goal.toStringAsFixed(0)} kcal)',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double goal;
  final Color color;

  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.labelLarge),
              Text('${value.toStringAsFixed(1)} $unit', style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class NutrientTile extends StatelessWidget {
  final Nutrient nutrient;

  const NutrientTile({super.key, required this.nutrient});

  @override
  Widget build(BuildContext context) {
    final color = switch (nutrient.category) {
      NutrientCategory.optimal => AppColors.success,
      NutrientCategory.moderate => AppColors.warning,
      NutrientCategory.limit => AppColors.error,
      NutrientCategory.insufficient => AppColors.textTertiary,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(nutrient.name, style: AppTextStyles.bodyMedium)),
          Text('${nutrient.value.toStringAsFixed(1)} ${nutrient.unit}',
              style: AppTextStyles.labelLarge),
          if (nutrient.dailyValue > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${nutrient.dailyValue.toStringAsFixed(0)}% DV',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AnalyzingIndicator extends StatelessWidget {
  final String title;
  final String subtitle;

  const AnalyzingIndicator({
    super.key,
    this.title = 'Analyzing...',
    this.subtitle = 'Processing image with AI',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.brand.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.bodySmall),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const ErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, color: AppColors.error, size: 18),
            ),
        ],
      ),
    );
  }
}

class ImagePreviewCard extends StatelessWidget {
  final String imagePath;
  final double height;
  final Widget? actions;
  final VoidCallback onClose;

  const ImagePreviewCard({
    super.key,
    required this.imagePath,
    this.height = 260,
    this.actions,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Stack(
            children: [
              Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: height,
                errorBuilder: (_, __, ___) => Container(
                  height: height,
                  color: AppColors.surfaceAlt,
                  child: const Center(child: Icon(Icons.broken_image, color: AppColors.textTertiary)),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          if (actions != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: actions,
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
