import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ThemeData dimTheme = ThemeData(
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: Colors.white)
    ),
    colorScheme: ColorScheme.dark(
      background: Colors.blueGrey.shade700,
      primary: Colors.grey.shade300,
      secondary: Colors.grey.shade400,
      tertiary: Colors.white,
      onTertiary: Colors.black,
    )
);