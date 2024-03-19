import 'package:flutter/material.dart';
import 'package:q/theme/dim_theme.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

class ThemeManager with ChangeNotifier {
  ThemeData _currentTheme = lightTheme;

  ThemeManager(String? selectedTheme) {
    // Set the initial theme based on the selectedTheme preference
    if (selectedTheme != null) {
      switch (selectedTheme) {
        case 'light':
          _currentTheme = lightTheme;
          break;
        case 'dark':
          _currentTheme = darkTheme;
          break;
        case 'dim':
          _currentTheme = dimTheme;
          break;
      // Add more cases for additional themes if needed
      }
    }
  }

  ThemeData get currentTheme => _currentTheme;

  void setTheme(ThemeData theme) {
    _currentTheme = theme;
    notifyListeners();
  }
}
