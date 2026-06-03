import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../viewmodels/onboarding_view_model.dart';
import '../widgets/wordmark.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  AppColorSet get colors => AppColors.of(context);
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Consumer<OnboardingViewModel>(
      builder: (context, vm, _) {
        // Keep PageController in sync with viewmodel's currentStep
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            final currentPage = _pageController.page?.round();
            if (currentPage != vm.currentStep) {
              _pageController.animateToPage(
                vm.currentStep,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        });

        return Scaffold(
          backgroundColor: colors.scaffold,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildStep(vm, context)),
                const SizedBox(height: 16),
                _stepIndicator(vm),
                const SizedBox(height: 8),
                _buildBottomBar(vm, context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(OnboardingViewModel vm, BuildContext context) {
    return PageView(
      controller: _pageController,
      onPageChanged: vm.setStep,
      children: [
        _welcomeStep(vm, context),
        _nameStep(vm, context),
        _metricsStep(vm, context),
        _goalsStep(vm, context),
        _preferencesStep(vm, context),
      ],
    );
  }

  Widget _welcomeStep(OnboardingViewModel vm, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/icons/chowscan_app_icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 48),
          const Wordmark(size: 44),
          const SizedBox(height: 12),
          Text(
            'Your intelligent nutrition companion.\nScan, analyze, and track your food - all offline.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 48),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _nameStep(OnboardingViewModel vm, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Let's get to know you", style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text('Tell us about yourself so we can personalize your nutrition goals.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 32),
          TextField(
            decoration: const InputDecoration(labelText: 'Your Name', hintText: 'Enter your name'),
            onChanged: vm.setName,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(labelText: 'Age', hintText: 'Your age'),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final age = int.tryParse(v);
              if (age != null) vm.setAge(age);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Weight (kg)', hintText: 'e.g. 70'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final w = double.tryParse(v);
                    if (w != null) vm.setWeight(w);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Height (cm)', hintText: 'e.g. 175'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final h = double.tryParse(v);
                    if (h != null) vm.setHeight(h);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Gender', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: ['Male', 'Female', 'Other'].map((g) {
              final selected = vm.gender == g;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: g == 'Other' ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => vm.setGender(g),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.brand.withValues(alpha: 0.15) : colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? AppColors.brand : colors.border),
                      ),
                      child: Text(g, textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600,
                              color: selected ? AppColors.brand : colors.textSecondary)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _metricsStep(OnboardingViewModel vm, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Conditions', style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text('Select any that apply to you.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          ...['Diabetes', 'High Blood Pressure', 'High Cholesterol', 'Food Allergies', 'Digestive Issues', 'None'].map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => vm.toggleHealthCondition(c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: vm.healthConditions.contains(c) ? AppColors.brand.withValues(alpha: 0.15) : colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: vm.healthConditions.contains(c) ? AppColors.brand : colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        vm.healthConditions.contains(c) ? Icons.check_circle : Icons.circle_outlined,
                        color: vm.healthConditions.contains(c) ? AppColors.brand : colors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(c, style: AppTextStyles.bodyLarge),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _goalsStep(OnboardingViewModel vm, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          Text('Daily Calorie Goal', style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text('Set your daily calorie target.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Text('${vm.calorieGoal.toStringAsFixed(0)}', style: AppTextStyles.numericLarge.copyWith(color: AppColors.brand)),
                const SizedBox(height: 4),
                Text('kcal per day', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 24),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.brand,
                    inactiveTrackColor: colors.surfaceAlt,
                    thumbColor: AppColors.brand,
                    overlayColor: AppColors.brand.withValues(alpha: 0.1),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: vm.calorieGoal,
                    min: 1200,
                    max: 4000,
                    divisions: 28,
                    label: '${vm.calorieGoal.toStringAsFixed(0)} kcal',
                    onChanged: vm.setCalorieGoal,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1,200', style: AppTextStyles.bodySmall),
                    Text('4,000', style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _preferencesStep(OnboardingViewModel vm, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dietary Preferences', style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text('Select your dietary patterns.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          ...['Balanced', 'High Protein', 'Low Carb', 'Vegetarian', 'Vegan', 'Mediterranean', 'Keto', 'No Preference'].map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => vm.toggleDietaryPreference(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: vm.dietaryPreferences.contains(p) ? AppColors.brand.withValues(alpha: 0.15) : colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: vm.dietaryPreferences.contains(p) ? AppColors.brand : colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        vm.dietaryPreferences.contains(p) ? Icons.check_circle : Icons.circle_outlined,
                        color: vm.dietaryPreferences.contains(p) ? AppColors.brand : colors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(p, style: AppTextStyles.bodyLarge),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _stepIndicator(OnboardingViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(vm.totalSteps, (i) {
        final isActive = i <= vm.currentStep;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.brand : colors.textTertiary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildBottomBar(OnboardingViewModel vm, BuildContext context) {
    final isLast = vm.currentStep == vm.totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.scaffold.withValues(alpha: 0), colors.scaffold],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (vm.currentStep > 0)
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: vm.previousStep,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              ),
            if (vm.currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      vm.completeOnboarding().then((_) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/model-setup', (_) => false);
                      });
                    } else {
                      vm.nextStep();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: colors.textOnBrand,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(isLast ? 'Get Started' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


