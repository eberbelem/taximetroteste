import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'core/models/fare_table.dart';
import 'core/taximeter_algorithm.dart';
import 'services/location_service.dart';
import 'services/database_service.dart';
import 'services/background_service.dart';
import 'services/sync_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final databaseService = DatabaseService();
  final locationService = LocationService();
  final fareTable = FareTable.padrao();
  final taximeter = TaximeterAlgorithm(fareTable: fareTable);
  final syncService = SyncService(databaseService);

  await BackgroundService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<LocationService>.value(value: locationService),
        Provider<TaximeterAlgorithm>.value(value: taximeter),
        Provider<SyncService>.value(value: syncService),
      ],
      child: const TaximetroApp(),
    ),
  );
}

class TaximetroApp extends StatelessWidget {
  const TaximetroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxímetro Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.farePrimary,
          secondary: AppColors.statusGold,
          surface: AppColors.surface,
        ),
        useMaterial3: true,
        fontFamily: '',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w200,
              letterSpacing: 3.0,
              color: AppColors.farePrimary),
          headlineMedium: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w300,
              letterSpacing: 2.0,
              color: AppColors.textPrimary),
          titleLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary),
          titleSmall: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.textTertiary),
          bodyLarge: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary),
          bodySmall: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
