import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../viewmodels/scan_view_model.dart';
import '../../viewmodels/chat_view_model.dart';
import '../../models/nutrition_info.dart';
import '../widgets/capture_prompt_card.dart';
import '../widgets/nutrient_result_card.dart';
import 'chat_screen.dart';
import 'meal_detail_screen.dart';

class ScanFoodScreen extends StatelessWidget {
  const ScanFoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Consumer<ScanViewModel>(builder: (context, vm, _) {
      if (vm.mode != ScanMode.foodPlate) {
        WidgetsBinding.instance.addPostFrameCallback((_) => vm.setMode(ScanMode.foodPlate));
      }
      return CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            pinned: true,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text('Scan Food', style: AppTextStyles.displaySmall),
              collapseMode: CollapseMode.pin,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (!vm.hasImage) ...[
                    CapturePromptCard(
                      icon: Icons.restaurant,
                      title: 'Scan Your Meal',
                      subtitle: 'Take a photo of your plate to identify foods and estimate nutritional value.',
                      iconColor: AppColors.accent,
                      onCameraTap: () => vm.takePhoto(),
                      onGalleryTap: () => vm.pickImage(),
                    ),
                    if (vm.history.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'SCAN HISTORY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: vm.history.length,
                        itemBuilder: (context, index) {
                          final item = vm.history[index];
                          return _buildHistoryItem(context, item);
                        },
                      ),
                    ],
                  ],
                  if (vm.hasImage)
                    ImagePreviewCard(
                      imagePath: vm.image!.path,
                      height: 280,
                      onClose: () => vm.clearImage(),
                      actions: vm.isAnalyzing
                          ? null
                          : Row(
                              children: [
                                Expanded(
                                  child: _ActionBtn(
                                    icon: Icons.auto_awesome,
                                    label: 'Analyze Meal',
                                    color: AppColors.accent,
                                    onTap: () => vm.analyze(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ActionBtn(
                                    icon: Icons.swap_horiz_rounded,
                                    label: 'Retake',
                                    color: colors.textSecondary,
                                    onTap: () => vm.clearImage(),
                                    filled: false,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  if (vm.isAnalyzing)
                    const AnalyzingIndicator(
                      title: 'Analyzing Your Meal...',
                      subtitle: 'Identifying foods and estimating nutrition',
                    ),
                  if (vm.hasResult && vm.nutritionInfo != null)
                    _buildScanResults(context, vm, vm.nutritionInfo!),
                  if (vm.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ErrorBanner(
                        message: vm.errorMessage!,
                        onDismiss: () => vm.clearResults(),
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildScanResults(BuildContext context, ScanViewModel vm, NutritionInfo info) {
    final colors = AppColors.of(context);
    // Categorize nutrients for warnings
    final excessive = info.nutrients
        .where((n) => n.dailyValue >= 30.0 || n.category == NutrientCategory.limit)
        .toList();
    final limited = info.nutrients
        .where((n) =>
            (n.category == NutrientCategory.insufficient || n.name.toLowerCase() == 'fiber') &&
            n.dailyValue < 30.0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // 1. Title and Description Card
        Text(info.name, style: AppTextStyles.displaySmall.copyWith(fontSize: 24, fontWeight: FontWeight.w800)),
        if (info.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              info.description,
              style: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary, height: 1.4),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // 2. Alert Droplist: Excessive & Limited Quantities
        _buildNutrientAlertList(context, 'Excessive Quantity ⚠️', excessive, AppColors.error),
        _buildNutrientAlertList(context, 'Limited Quantity ⚠️', limited, AppColors.warning),

        // 3. Remedies & Recommendations
        _buildRemediesList(context, info.remedies),
        _buildRecommendationsList(context, info.recommendations),

        // 4. Energy Distribution Card
        _buildEnergyDistribution(context, info, vm.servings),
        const SizedBox(height: 20),

        // 5. Time & Serving Editors
        _buildEditorTile(context,
          icon: Icons.access_time_outlined,
          label: 'Time',
          value: DateFormat('h:mm a').format(vm.logTime),
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(vm.logTime),
            );
            if (time != null) {
              final now = DateTime.now();
              vm.setLogTime(DateTime(now.year, now.month, now.day, time.hour, time.minute));
            }
          },
        ),
        const SizedBox(height: 10),
        _buildEditorTile(context,
          icon: Icons.restaurant_menu,
          label: 'Quantity',
          value: '${vm.servings.toStringAsFixed(1)} serving',
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) {
                final controller = TextEditingController(text: vm.servings.toStringAsFixed(1));
                return AlertDialog(
                  backgroundColor: colors.surface,
                  title: const Text('Edit Quantity'),
                  content: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Servings'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        final val = double.tryParse(controller.text);
                        if (val != null && val > 0) {
                          vm.setServings(val);
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),

        // 6. Action Button: Add to Intake
        SizedBox(
          width: double.infinity,
          height: 56,
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
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add to today\'s intake'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 7. Glow Sparkle Button: Is this food healthy for me?
        GestureDetector(
          onTap: () {
            context.read<ChatViewModel>().setContext(
                  'I just scanned a meal: ${info.name}. '
                  'Description: ${info.description}. '
                  'Calories: ${(info.calories * vm.servings).toStringAsFixed(0)} kcal, '
                  'Protein: ${(info.protein * vm.servings).toStringAsFixed(1)}g, '
                  'Carbs: ${(info.carbs * vm.servings).toStringAsFixed(1)}g, '
                  'Fat: ${(info.fat * vm.servings).toStringAsFixed(1)}g. '
                  'Is this healthy for me?',
                );
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFFF9E00), width: 1.5),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFFFF9E00), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Is this food healthy for me?',
                    style: TextStyle(
                      color: Color(0xFFFF9E00),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientAlertList(BuildContext context, String title, List<Nutrient> list, Color color) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        ...list.map((n) => _buildAlertTile(context, n, color)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAlertTile(BuildContext context, Nutrient n, Color color) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            n.name.toLowerCase() == 'sodium'
                ? Icons.grain
                : n.name.toLowerCase().contains('fat')
                    ? Icons.opacity
                    : Icons.restaurant_menu,
            color: color,
            size: 20,
          ),
          title: Text(n.name, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary, fontSize: 14)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${n.dailyValue.toStringAsFixed(1)}% DV',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down, color: colors.textTertiary, size: 18),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'A single serving provides ${n.value.toStringAsFixed(1)}${n.unit} (${n.dailyValue.toStringAsFixed(1)}% of your recommended daily value). '
                  'Consuming this in excess can impact your target health goals.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemediesList(BuildContext context, List<Map<String, String>> remedies) {
    final colors = AppColors.of(context);
    if (remedies.isEmpty) return const SizedBox.shrink();
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRecommendationsList(BuildContext context, List<Map<String, String>> recs) {
    final colors = AppColors.of(context);
    if (recs.isEmpty) return const SizedBox.shrink();
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEnergyDistribution(BuildContext context, NutritionInfo info, double servings) {
    final colors = AppColors.of(context);
    final pKcal = info.protein * 4;
    final cKcal = info.carbs * 4;
    final fKcal = info.fat * 9;
    final total = pKcal + cKcal + fKcal;

    final pPct = total > 0 ? (pKcal / total) : 0.0;
    final cPct = total > 0 ? (cKcal / total) : 0.0;
    final fPct = total > 0 ? (fKcal / total) : 0.0;

    final displayCals = info.calories * servings;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Energy Distribution',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
              Text('${displayCals.toStringAsFixed(0)} kcal',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: colors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (pKcal > 0)
                    Expanded(
                      flex: (pPct * 100).round().clamp(1, 100),
                      child: Container(color: const Color(0xFF8CEE2C)),
                    ),
                  if (fKcal > 0)
                    Expanded(
                      flex: (fPct * 100).round().clamp(1, 100),
                      child: Container(color: const Color(0xFFFF9E00)),
                    ),
                  if (cKcal > 0)
                    Expanded(
                      flex: (cPct * 100).round().clamp(1, 100),
                      child: Container(color: const Color(0xFFFFD400)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _energyLabel(context, '${(pPct * 100).toStringAsFixed(0)}% Protein', const Color(0xFF8CEE2C)),
              _energyLabel(context, '${(fPct * 100).toStringAsFixed(0)}% Fat', const Color(0xFFFF9E00)),
              _energyLabel(context, '${(cPct * 100).toStringAsFixed(0)}% Carbohydrate', const Color(0xFFFFD400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _energyLabel(BuildContext context, String label, Color color) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textSecondary)),
      ],
    );
  }

  Widget _buildEditorTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary, fontSize: 14)),
              ],
            ),
            Row(
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary, fontSize: 14)),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, color: colors.textTertiary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, NutritionInfo item) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.imagePath.isNotEmpty && File(item.imagePath).existsSync()
              ? Image.file(
                  File(item.imagePath),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
                ),
        ),
        title: Text(
          item.name,
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${item.calories.toStringAsFixed(0)} kcal  •  P: ${item.protein.toStringAsFixed(0)}g  •  C: ${item.carbs.toStringAsFixed(0)}g  •  F: ${item.fat.toStringAsFixed(0)}g',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.textTertiary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MealDetailScreen(item: item),
            ),
          );
        },
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? color : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: filled ? colors.textOnBrand : colors.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: filled ? colors.textOnBrand : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


