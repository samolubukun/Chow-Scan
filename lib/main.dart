import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/model_manager.dart';
import 'services/image_service.dart';
import 'services/local_db_service.dart';
import 'viewmodels/chat_view_model.dart';
import 'viewmodels/scan_view_model.dart';
import 'viewmodels/daily_intake_view_model.dart';
import 'viewmodels/onboarding_view_model.dart';
import 'viewmodels/describe_meal_view_model.dart';
import 'viewmodels/theme_view_model.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'views/screens/home_page.dart';
import 'views/screens/onboarding_screen.dart';
import 'views/screens/model_download_screen.dart';
import 'views/screens/describe_meal_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  FlutterGemma.initialize(maxDownloadRetries: 10);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: true,
  ));

  final hasProfile = await LocalDbService.instance.hasProfile();
  final modelExists = await _checkModelOnDisk();

  runApp(ChowScanApp(
    initialRoute: !hasProfile
        ? '/onboarding'
        : modelExists
            ? '/home'
            : '/model-setup',
  ));
}

Future<bool> _checkModelOnDisk() async {
  try {
    final dir = await _docDir();
    final gemma4File = File('$dir/gemma-4-E2B-it.litertlm');
    final gemma3File = File('$dir/gemma-3n-E2B-it-int4.litertlm');
    return (gemma4File.existsSync() && await gemma4File.length() > 100000) ||
           (gemma3File.existsSync() && await gemma3File.length() > 100000);
  } catch (_) {
    return false;
  }
}

Future<String> _docDir() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

class ChowScanApp extends StatelessWidget {
  final String initialRoute;
  const ChowScanApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => ModelManager()),
        Provider(create: (_) => ImageService()),
        Provider.value(value: LocalDbService.instance),
        ChangeNotifierProxyProvider<ModelManager, ChatViewModel>(
          create: (ctx) => ChatViewModel(
            ctx.read<ModelManager>(),
            ctx.read<ImageService>(),
          ),
          update: (_, mm, prev) => prev!,
        ),
        ChangeNotifierProvider(
          create: (ctx) => DescribeMealViewModel(
            ctx.read<ModelManager>(),
            ctx.read<LocalDbService>(),
          ),
        ),
        ChangeNotifierProvider<ScanViewModel>(
          create: (ctx) => ScanViewModel(
            ctx.read<ModelManager>(),
            ctx.read<ImageService>(),
            ctx.read<LocalDbService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => DailyIntakeViewModel(ctx.read<LocalDbService>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) => OnboardingViewModel(ctx.read<LocalDbService>()),
        ),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVm, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ChowScan',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeVm.themeMode,
            initialRoute: initialRoute,
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/home': (context) => const HomePage(),
              '/model-setup': (context) => const ModelDownloadSetupScreen(),
              '/describe-meal': (context) => const DescribeMealScreen(),
            },
          );
        },
      ),
    );
  }
}
