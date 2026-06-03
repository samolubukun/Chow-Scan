import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/model_status.dart';
import '../../services/model_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'scan_label_screen.dart';
import 'scan_food_screen.dart';
import 'daily_intake_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'model_download_screen.dart';
import 'describe_meal_screen.dart';
import '../../viewmodels/scan_view_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final _screens = const [
    ScanLabelScreen(),
    ScanFoodScreen(),
    DailyIntakeScreen(),
    ChatScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScanViewModel>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelManager>(
      builder: (context, mm, _) {
        if (mm.status == ModelStatus.notDownloaded) {
          return const ModelDownloadSetupScreen();
        }
        return _buildMainScaffold(context);
      },
    );
  }

  Widget _buildMainScaffold(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      extendBody: true,
      backgroundColor: colors.scaffold,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _screens[_currentIndex],
          ),
          if (_currentIndex != 3)
            Positioned(
              top: 8,
              right: 20,
              child: SafeArea(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _showQuickActions,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: colors.card.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.add, color: AppColors.brand, size: 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: colors.card.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                        ),
                        child: Icon(Icons.settings, color: colors.textSecondary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(colors),
    );
  }

  void _showQuickActions() {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: colors.textTertiary, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Text('Quick Actions', style: AppTextStyles.heading2),
              const SizedBox(height: 20),
              _quickActionTile(ctx, colors,
                icon: Icons.edit_note,
                label: 'Describe a Meal',
                desc: 'Type a meal description for nutrition analysis',
                color: AppColors.info,
                onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const DescribeMealScreen())); },
              ),
              const SizedBox(height: 8),
              _quickActionTile(ctx, colors,
                icon: Icons.camera_alt_rounded,
                label: 'Scan Label',
                desc: 'Capture a nutrition label',
                color: AppColors.brand,
                onTap: () { Navigator.pop(ctx); setState(() => _currentIndex = 0); },
              ),
              const SizedBox(height: 8),
              _quickActionTile(ctx, colors,
                icon: Icons.restaurant,
                label: 'Scan Food',
                desc: 'Take a photo of your meal',
                color: AppColors.accent,
                onTap: () { Navigator.pop(ctx); setState(() => _currentIndex = 1); },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionTile(BuildContext ctx, AppColorSet colors, {
    required IconData icon, required String label, required String desc,
    required Color color, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(desc, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(AppColorSet colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() => _currentIndex = i);
            if (i == 0 || i == 1) {
              context.read<ScanViewModel>().loadHistory();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.brand,
          unselectedItemColor: colors.textTertiary,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w400, fontSize: 10),
          items: [
            _navItem(Icons.document_scanner_outlined, Icons.document_scanner, 'Label', 0),
            _navItem(Icons.restaurant_outlined, Icons.restaurant, 'Food', 1),
            _navItem(Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded, 'Intake', 2),
            _navItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chat', 3),
          ].toList(),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData outline, IconData filled, String label, int index) {
    return BottomNavigationBarItem(
      icon: Icon(_currentIndex == index ? filled : outline, size: 22),
      label: label,
    );
  }
}
