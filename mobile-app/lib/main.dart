import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/notification_provider.dart';
import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data for scheduling notifications
  tz.initializeTimeZones();
  
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final languageState = ref.watch(languageProvider);
    final router = ref.watch(routerProvider);

    // Initialize notifications when app starts
    ref.listen<AsyncValue<bool>>(notificationInitializedProvider, (_, state) {
      state.when(
        data: (initialized) {
          if (initialized) {
            print('Notifications initialized successfully');
          }
        },
        loading: () => print('Initializing notifications...'),
        error: (error, stack) => print('Error initializing notifications: $error'),
      );
    });

    return MaterialApp.router(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      
      // Localization configuration
      locale: languageState.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('id', 'ID'),
      ],
      
      // Theme configuration with dynamic colors
      theme: AppTheme.lightTheme(themeState.primaryColor),
      darkTheme: AppTheme.darkTheme(themeState.primaryColor),
      themeMode: ref.read(themeProvider.notifier).materialThemeMode,
      
      routerConfig: router,
    );
  }
}
