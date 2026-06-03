import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../viewmodels/daily_intake_view_model.dart';
import '../../models/nutrition_info.dart';
import 'meal_detail_screen.dart';

class DailyIntakeScreen extends StatefulWidget {
  const DailyIntakeScreen({super.key});

  @override
  State<DailyIntakeScreen> createState() => _DailyIntakeScreenState();
}

class _DailyIntakeScreenState extends State<DailyIntakeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyIntakeViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Consumer<DailyIntakeViewModel>(builder: (context, vm, _) {
      return CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            pinned: true,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text('Daily Intake', style: AppTextStyles.displaySmall),
              collapseMode: CollapseMode.pin,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dateStrip(context, colors, vm),
                  const SizedBox(height: 20),
                  _calorieCard(colors, vm),
                  const SizedBox(height: 16),
                  _macroRow(colors, vm),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM d, y').format(vm.selectedDate) ==
                                DateFormat('MMM d, y').format(DateTime.now())
                            ? "Today's Intake"
                            : DateFormat('MMM d').format(vm.selectedDate),
                        style: AppTextStyles.heading1.copyWith(fontWeight: FontWeight.w800, fontSize: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (vm.intakeItems.isEmpty) _emptyState(colors),
                  ...vm.intakeItems.map((item) => _mealCard(context, colors, vm, item)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _dateStrip(BuildContext context, AppColorSet colors, DailyIntakeViewModel vm) {
    final now = DateTime.now();
    return Row(
      children: [
        // Calendar picker button
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: vm.selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.brand),
                ),
                child: child!,
              ),
            );
            if (picked != null) vm.selectDate(picked);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: const Icon(Icons.calendar_month_outlined, color: AppColors.brand, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: List.generate(7, (i) {
                final date = now.subtract(Duration(days: 6 - i));
                final sel = date.day == vm.selectedDate.day &&
                    date.month == vm.selectedDate.month &&
                    date.year == vm.selectedDate.year;
                final isToday = date.day == now.day &&
                    date.month == now.month &&
                    date.year == now.year;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => vm.selectDate(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.brand : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isToday && !sel
                            ? Border.all(color: AppColors.brand.withValues(alpha: 0.5), width: 1.5)
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('E').format(date).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: sel ? colors.textOnBrand : colors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: sel ? colors.textOnBrand : colors.textPrimary,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 4, height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: sel ? colors.textOnBrand : AppColors.brand,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _calorieCard(AppColorSet colors, DailyIntakeViewModel vm) {
    final pct = vm.calorieGoal > 0 ? (vm.calories / vm.calorieGoal).clamp(0.0, 1.0) : 0.0;
    final pctText = '${(pct * 100).toStringAsFixed(0)}%';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TODAY'S CALORIES",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                    color: colors.textTertiary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    vm.calories.toStringAsFixed(0),
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: colors.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Text('kcal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colors.textSecondary)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'of ${vm.calorieGoal.toStringAsFixed(0)} goal',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textTertiary),
              ),
            ],
          ),
          SizedBox(
            width: 76, height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 76, height: 76,
                  child: CircularProgressIndicator(
                    value: pct, strokeWidth: 7,
                    backgroundColor: colors.surfaceAlt,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF8CEE2C)),
                  ),
                ),
                Text(pctText,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _macroRow(AppColorSet colors, DailyIntakeViewModel vm) {
    return Row(
      children: [
        _macroCard(colors, 'Protein', vm.protein, vm.proteinGoal, const Color(0xFF8CEE2C)),
        const SizedBox(width: 10),
        _macroCard(colors, 'Carbs', vm.carbs, vm.carbsGoal, const Color(0xFFFFD400)),
        const SizedBox(width: 10),
        _macroCard(colors, 'Fat', vm.fat, vm.fatGoal, const Color(0xFFFF9E00)),
      ],
    );
  }

  Widget _macroCard(AppColorSet colors, String label, double current, double goal, Color color) {
    final pct = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary)),
                Icon(Icons.more_horiz, size: 14, color: colors.textTertiary),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${current.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                Text(' / ${goal.toStringAsFixed(0)}g',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.textTertiary)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 5, width: double.infinity,
              decoration: BoxDecoration(color: colors.surfaceAlt, borderRadius: BorderRadius.circular(3)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(AppColorSet colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: colors.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No meals logged', style: AppTextStyles.heading3),
          const SizedBox(height: 6),
          Text('Scan a product label or meal photo to start tracking.',
              textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _mealCard(BuildContext context, AppColorSet colors, DailyIntakeViewModel vm, NutritionInfo item) {
    final hasImage = item.imagePath.isNotEmpty && File(item.imagePath).existsSync();
    final timeStr = DateFormat('h:mm a').format(item.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 140,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MealDetailScreen(item: item)),
            ).then((_) => vm.init());
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Hero(
                  tag: 'meal_image_${item.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      image: hasImage
                          ? DecorationImage(image: FileImage(File(item.imagePath)), fit: BoxFit.cover)
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
                        ? Center(child: Icon(Icons.restaurant, size: 40, color: colors.textOnBrand))
                        : null,
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14, left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_outlined, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(timeStr,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 14, left: 16, right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(item.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 12),
                    Text('${item.calories.toStringAsFixed(0)} kcal',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }
}
