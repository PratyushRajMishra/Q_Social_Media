import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/dark_theme.dart';
import '../../theme/dim_theme.dart';
import '../../theme/light_theme.dart';
import '../../theme/theme_manager.dart';

class ThemesPage extends StatefulWidget {
  const ThemesPage({Key? key}) : super(key: key);

  @override
  State<ThemesPage> createState() => _ThemesPageState();
}

class _ThemesPageState extends State<ThemesPage> {
  late String _selectedMode = 'light'; // Initialize with default value

  @override
  void initState() {
    super.initState();
    _loadThemePreference(); // Load theme preference when the widget initializes
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMode = prefs.getString('selectedTheme') ?? 'light';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          'Themes',
          style: TextStyle(
            letterSpacing: 0.5,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Themes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            GestureDetector(
              onTap: () {
                _showThemeSelector(context);
              },
              child: ListTile(
                title: Text('Choose theme'),
                subtitle: Text('Select any theme as your preference'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedMode, style: TextStyle(fontWeight: FontWeight.bold),),
                    SizedBox(width: 5,),
                    Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.tertiary,),
                  ],
                ),
              ),
            )

          ],
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.onTertiary,
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              RadioListTile(
                title: const Text('Light Theme'),
                value: 'light',
                groupValue: _selectedMode,
                onChanged: (value) {
                  setState(() {
                    _selectedMode = value!;
                  });
                  themeManager.setTheme(lightTheme);
                  _saveThemePreference('light');
                  Navigator.pop(context);
                },
                activeColor: Colors.blue,
              ),
              RadioListTile(
                title: const Text('Dark Theme'),
                value: 'dark',
                groupValue: _selectedMode,
                onChanged: (value) {
                  setState(() {
                    _selectedMode = value!;
                  });
                  themeManager.setTheme(darkTheme);
                  _saveThemePreference('dark');
                  Navigator.pop(context);
                },
                activeColor: Colors.blue,
              ),
              RadioListTile(
                title: const Text('Dim Theme'),
                value: 'dim',
                groupValue: _selectedMode,
                onChanged: (value) {
                  setState(() {
                    _selectedMode = value!;
                  });
                  themeManager.setTheme(dimTheme);
                  _saveThemePreference('dim');
                  Navigator.pop(context);
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveThemePreference(String theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedTheme', theme);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }
}
