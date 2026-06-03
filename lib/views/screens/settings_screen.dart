import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/model_status.dart';
import '../../services/model_manager.dart';
import '../../services/local_db_service.dart';
import '../../models/user_profile.dart';
import '../../viewmodels/theme_view_model.dart';
import 'model_download_screen.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<UserProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = LocalDbService.instance.getProfile();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = LocalDbService.instance.getProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<UserProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              _sectionHeader(colors, 'Profile'),
              const SizedBox(height: 12),
              _profileCard(context, colors, profile),
              const SizedBox(height: 28),
              _sectionHeader(colors, 'AI Model'),
              const SizedBox(height: 12),
              Consumer<ModelManager>(
                builder: (context, mm, _) => _menuItem(context, colors,
                  icon: Icons.psychology,
                  label: 'Model Status',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: mm.isReady ? AppColors.success.withValues(alpha: 0.15) : AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mm.isReady ? 'Ready' : mm.status == ModelStatus.notDownloaded ? 'Not Downloaded' : mm.status.name,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: mm.isReady ? AppColors.success : AppColors.warning),
                    ),
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelDownloadSetupScreen())),
                ),
              ),
              const SizedBox(height: 28),
              _sectionHeader(colors, 'Preferences'),
              const SizedBox(height: 12),
              Consumer<ThemeViewModel>(
                builder: (context, themeVm, _) {
                  final isDark = themeVm.effectiveIsDark(MediaQuery.of(context).platformBrightness);
                  return _menuItem(context, colors,
                    icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                    label: 'Dark Mode',
                    trailing: Switch(
                      value: isDark,
                      onChanged: (val) => themeVm.setDark(val),
                      activeThumbColor: AppColors.brand,
                      activeColor: AppColors.brand,
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              _sectionHeader(colors, 'Data'),
              const SizedBox(height: 12),
              _menuItem(context, colors,
                icon: Icons.delete_outline,
                label: 'Clear All Data',
                iconColor: AppColors.error,
                onTap: () => _confirmClearData(context, colors),
              ),
              _menuItem(context, colors,
                icon: Icons.refresh,
                label: 'Reset Onboarding',
                onTap: () async {
                  await LocalDbService.instance.saveProfile(const UserProfile(name: ''));
                  Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (_) => false);
                },
              ),
              const SizedBox(height: 28),
              _sectionHeader(colors, 'About'),
              const SizedBox(height: 12),
              _menuItem(context, colors,
                icon: Icons.info_outline,
                label: 'Version',
                trailing: Text('2.0.0', style: AppTextStyles.bodyMedium),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(AppColorSet colors, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title,
        style: AppTextStyles.labelMedium.copyWith(color: colors.textTertiary, letterSpacing: 1)),
    );
  }

  Widget _profileCard(BuildContext context, AppColorSet colors, UserProfile? profile) {
    if (profile == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: colors.surfaceAlt, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.person, color: colors.textTertiary),
            ),
            const SizedBox(width: 16),
            Text('No profile', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }
    return InkWell(
      onTap: () async {
        final updated = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
        );
        if (updated == true) _refreshProfile();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.brandGradient),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(Icons.person, size: 28, color: colors.textOnBrand),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name, style: AppTextStyles.heading3),
                  const SizedBox(height: 4),
                  Text('${profile.dailyCalorieGoal.toStringAsFixed(0)} kcal daily goal  •  ${profile.age ?? '-'} yrs',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, AppColorSet colors, {
    required IconData icon,
    required String label,
    Widget? trailing,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? colors.textSecondary, size: 22),
        title: Text(label, style: AppTextStyles.bodyLarge),
        trailing: trailing ?? Icon(Icons.chevron_right, color: colors.textTertiary, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: colors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _confirmClearData(BuildContext context, AppColorSet colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: const Text('Clear All Data'),
        content: const Text('This will delete all your saved data including food logs and profile. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ModelManager>().clearModel();
              Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (_) => false);
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
