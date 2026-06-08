import 'package:flutter/material.dart';
import 'package:weatherx/pages/weather_page.dart';
import 'package:weatherx/utils/colors.dart';
import 'package:weatherx/utils/font.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: AppFont.family,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.background,
        ),
        iconTheme: const IconThemeData(color: AppColors.icon),
      ),
      home: WeatherPage(),
    );
  }
}
