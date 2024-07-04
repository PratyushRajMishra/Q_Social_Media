import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:q/firebase_options.dart';
import 'package:q/screens/auth/dashBoard.dart';
import 'package:q/screens/bottom_NavBar.dart';
import 'package:q/theme/dark_theme.dart';
import 'package:q/theme/theme_manager.dart';
import 'models/customCircularProgress.dart';
import 'models/userModel.dart';
import 'models/FirebaseHelper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? selectedTheme = prefs.getString('selectedTheme');

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeManager(selectedTheme),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeManager.currentTheme,
      darkTheme: darkTheme,
      title: 'Q',
      home: FutureBuilder<bool>(
        future: isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          } else {
            final bool loggedIn = snapshot.data ?? false;
            if (loggedIn) {
              return FutureBuilder<UserModel?>(
                future: getUserModel(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(
                        child: CustomCircularProgressIndicator(
                          imagePath: 'assets/logo_dark.png',
                          size: 120.0,
                          darkModeImagePath: 'assets/logo_light.png',
                        ),
                      ),
                    );
                  } else if (userSnapshot.hasError) {
                    return Scaffold(
                      body: Center(
                        child: Text('Error fetching user model: ${userSnapshot.error}'),
                      ),
                    );
                  } else {
                    final userModel = userSnapshot.data;
                    if (userModel != null) {
                      return BottomNavbarPage(userModel: userModel);
                    } else {
                      return const DashBoardPage();
                    }
                  }
                },
              );
            } else {
              return const DashBoardPage();
            }
          }
        },
      ),
    );
  }

  Future<bool> isLoggedIn() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return true;
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool? loggedIn = prefs.getBool('loggedIn');
      return loggedIn ?? false;
    }
  }

  Future<UserModel?> getUserModel() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String uid = currentUser.uid;
      return await FirebaseHelper.getUserModelById(uid);
    } else {
      return null;
    }
  }
}
