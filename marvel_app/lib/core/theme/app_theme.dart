import 'package:flutter/material.dart';

class AuroraColors {
  static const Color deepSpace = Color(0xFF020817);
  static const Color auroraGreen = Color(0xFF00FFB2);
  static const Color auroraBlue = Color(0xFF00C2FF);
  static const Color auroraPurple = Color(0xFF8B5CF6);
  static const Color auroraPink = Color(0xFFEC4899);
  static const Color auroraTeal = Color(0xFF06B6D4);
}

class AppColors {
  static const Color primary = Color(0xFF00AE2C);
  static const Color primaryLight = Color(0xFF32D445);
  static const Color darkBlue = Color(0xFF1F04B3);
  static const Color darkGreen = Color(0xFF004311);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF7C7C7C);
  static const Color cardBg = Color(0xFFFBFFFC);
  static const Color navBarBg = Color(0xF7FFFEFB);
}

const List<Color> marvelTitleColors = [
  Color(0xE323E655),
  Color(0xE3004311),
  Color(0xE31000DA),
];
const List<double> marvelTitleStops = [0.12312, 0.47013, 0.85657];

class AppTextStyles {
  static const String fontFamily = 'BeVietnamPro';
  static const TextStyle heroSubtitle = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w300,
      fontSize: 18,
      color: Color.fromARGB(225, 252, 255, 63),
      height: 1.5);
  static const TextStyle appBarTitle = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w900,
      fontSize: 26,
      color: Colors.white);
  static const TextStyle sectionTitle = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      color: AppColors.black);
  static const TextStyle cardTitle = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w700,
      fontSize: 18,
      color: AppColors.primaryLight);
  static const TextStyle cardSubtitle = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w200,
      fontSize: 12,
      color: AppColors.grey);
  static const TextStyle navLabel = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 10,
      letterSpacing: 0.15);
  static const TextStyle buttonText = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w700,
      fontSize: 22,
      color: Colors.white);
  static const TextStyle taglineSmall = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      color: AppColors.primary);
  static const TextStyle scrollDownText = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 10,
      color: Colors.white,
      letterSpacing: 0.15);
  static const TextStyle seeAllText = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w200,
      fontSize: 12,
      color: AppColors.primaryLight);
  static const TextStyle drawerItem = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 18,
      color: AppColors.black);
  static const TextStyle blogCardTitle = TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w700,
      fontSize: 20,
      color: AppColors.primaryLight);
}
