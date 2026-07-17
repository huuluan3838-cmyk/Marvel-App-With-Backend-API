import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/home/screens/home_screen.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FcmService.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const MarvelTravelApp());
}

class MarvelTravelApp extends StatelessWidget {
  const MarvelTravelApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marvel Travel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: AppTextStyles.fontFamily,
        fontFamilyFallback: const ['Arial', 'Roboto'],
        textTheme: Theme.of(context)
            .textTheme
            .apply(fontFamily: AppTextStyles.fontFamily),
        primaryTextTheme: Theme.of(context)
            .primaryTextTheme
            .apply(fontFamily: AppTextStyles.fontFamily),
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
