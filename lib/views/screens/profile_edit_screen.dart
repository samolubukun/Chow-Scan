import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user_profile.dart';
import '../../services/local_db_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  AppColorSet get colors => AppColors.of(context);
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  String? _gender;
  double _calorieGoal = 2000;
  final List<String> _healthConditions = [];
  final List<String> _dietaryPreferences = [];

  final List<String> _allHealthConditions = [
    'Diabetes',
    'High Blood Pressure',
    'High Cholesterol',
    'Food Allergies',
    'Digestive Issues',
    'None'
  ];

  final List<String> _allDietaryPreferences = [
    'Balanced',
    'High Protein',
    'Low Carb',
    'Vegetarian',
    'Vegan',
    'Mediterranean',
    'Keto',
    'No Preference'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await LocalDbService.instance.getProfile();
    if (profile != null) {
      setState(() {
        _nameController.text = profile.name;
        _ageController.text = profile.age?.toString() ?? '';
        _weightController.text = profile.weightKg?.toString() ?? '';
        _heightController.text = profile.heightCm?.toString() ?? '';
        _gender = profile.gender;
        _calorieGoal = profile.dailyCalorieGoal;
        _healthConditions.addAll(profile.healthConditions);
        _dietaryPreferences.addAll(profile.dietaryPreferences);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _toggleHealthCondition(String condition) {
    setState(() {
      if (condition == 'None') {
        _healthConditions.clear();
        _healthConditions.add('None');
      } else {
        _healthConditions.remove('None');
        if (_healthConditions.contains(condition)) {
          _healthConditions.remove(condition);
        } else {
          _healthConditions.add(condition);
        }
      }
    });
  }

  void _toggleDietaryPreference(String pref) {
    setState(() {
      if (pref == 'No Preference') {
        _dietaryPreferences.clear();
        _dietaryPreferences.add('No Preference');
      } else {
        _dietaryPreferences.remove('No Preference');
        if (_dietaryPreferences.contains(pref)) {
          _dietaryPreferences.remove(pref);
        } else {
          _dietaryPreferences.add(pref);
        }
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    final updatedProfile = UserProfile(
      name: _nameController.text.trim(),
      age: age,
      weightKg: weight,
      heightCm: height,
      gender: _gender,
      dailyCalorieGoal: _calorieGoal,
      healthConditions: _healthConditions,
      dietaryPreferences: _dietaryPreferences,
      onboardingComplete: true,
    );

    await LocalDbService.instance.saveProfile(updatedProfile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.brand),
              SizedBox(width: 8),
              Text('Profile updated successfully'),
            ],
          ),
          backgroundColor: colors.surfaceAlt,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _sectionTitle('Personal Details'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'Your name',
                      filled: true,
                      fillColor: colors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.brand),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter your name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          decoration: InputDecoration(
                            labelText: 'Age',
                            hintText: 'e.g. 25',
                            filled: true,
                            fillColor: colors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.border),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              final age = int.tryParse(v);
                              if (age == null || age <= 0 || age > 120) {
                                return 'Invalid age';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            filled: true,
                            fillColor: colors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.border),
                            ),
                          ),
                          dropdownColor: colors.surfaceAlt,
                          items: ['Male', 'Female', 'Other']
                              .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ))
                              .toList(),
                          onChanged: (g) => setState(() => _gender = g),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
                            hintText: 'e.g. 70',
                            filled: true,
                            fillColor: colors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.border),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          decoration: InputDecoration(
                            labelText: 'Height (cm)',
                            hintText: 'e.g. 175',
                            filled: true,
                            fillColor: colors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.border),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _sectionTitle('Daily Calorie Goal'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_calorieGoal.toStringAsFixed(0)} kcal',
                          style: AppTextStyles.heading2.copyWith(color: AppColors.brand),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.brand,
                            inactiveTrackColor: colors.surfaceAlt,
                            thumbColor: AppColors.brand,
                            overlayColor: AppColors.brand.withValues(alpha: 0.1),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _calorieGoal,
                            min: 1200,
                            max: 4000,
                            divisions: 28,
                            onChanged: (val) {
                              setState(() {
                                _calorieGoal = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _sectionTitle('Health Conditions'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allHealthConditions.map((cond) {
                      final selected = _healthConditions.contains(cond);
                      return ChoiceChip(
                        label: Text(cond),
                        selected: selected,
                        onSelected: (_) => _toggleHealthCondition(cond),
                        selectedColor: AppColors.brand.withValues(alpha: 0.15),
                        backgroundColor: colors.card,
                        checkmarkColor: AppColors.brand,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.brand : colors.textSecondary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: selected ? AppColors.brand : colors.border,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  _sectionTitle('Dietary Preferences'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allDietaryPreferences.map((pref) {
                      final selected = _dietaryPreferences.contains(pref);
                      return ChoiceChip(
                        label: Text(pref),
                        selected: selected,
                        onSelected: (_) => _toggleDietaryPreference(pref),
                        selectedColor: AppColors.brand.withValues(alpha: 0.15),
                        backgroundColor: colors.card,
                        checkmarkColor: AppColors.brand,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.brand : colors.textSecondary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: selected ? AppColors.brand : colors.border,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: colors.textOnBrand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Save Changes', style: AppTextStyles.buttonLarge),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading2.copyWith(color: colors.textPrimary),
    );
  }
}


