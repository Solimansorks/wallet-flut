import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_wallet/core/services/database_service.dart';
import 'package:personal_wallet/core/services/storage_service.dart';
import 'package:personal_wallet/core/services/service_providers.dart';
import 'package:personal_wallet/core/theme/app_theme.dart';
import 'package:personal_wallet/routes/app_router.dart';
import 'package:personal_wallet/features/settings/presentation/controllers/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  StorageService? storageService;
  DatabaseService? databaseService;
  String? initError;

  try {
    // Initialize SharedPreferences
    final sharedPrefs = await SharedPreferences.getInstance();
    storageService = StorageService(sharedPrefs);
    await storageService.initDefaults();

    // Initialize Isar Database
    databaseService = DatabaseService();
    await databaseService.init();
  } catch (e, stack) {
    initError = 'Error during initialization:\n$e\n\nStacktrace:\n$stack';
    debugPrint(initError);
  }

  if (initError != null) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                    const SizedBox(height: 20),
                    const Text(
                      'App Initialization Failed',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This screen helps debug issues in production builds (e.g., database schema changes or R8 code shrinking issues).',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: SelectableText(
                        initError,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  } else {
    runApp(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storageService!),
          databaseServiceProvider.overrideWithValue(databaseService!),
        ],
        child: const MainApp(),
      ),
    );
  }
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp.router(
      title: 'Personal Wallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: router,
      locale: settings.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final isRtl = settings.locale.languageCode == 'ar';
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
