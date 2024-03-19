import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
      iconTheme: IconThemeData(color: Colors.black)
  ),
    colorScheme: ColorScheme.light(
      background: Colors.grey.shade50,
      primary: Colors.black87,
      secondary: Colors.grey.shade500,
      tertiary: Colors.black,
      onTertiary: Colors.white
    )
);