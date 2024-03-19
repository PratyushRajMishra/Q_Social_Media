import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:q/models/userModel.dart';
import 'package:q/screens/auth/dashBoard.dart';
import 'package:q/screens/bottom_NavBar.dart';

import '../../models/FirebaseHelper.dart';

class GoogleAuth extends StatelessWidget {
  const GoogleAuth({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while checking the authentication state
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          // Show an error message if there's an error
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else {
          // Check if the user is logged in
          if (snapshot.data == null) {
            // User not logged in, show the DashboardPage
            return const DashBoardPage();
          } else {
            // User logged in
            final User user = snapshot.data!;
            // Check if the user is logged in with Google
            if (user.providerData.any((userInfo) => userInfo.providerId == 'google.com')) {
              // User logged in with Google, navigate to BottomNavbarPage
              return FutureBuilder<UserModel?>(
                future: getUserModel(user.uid),
                builder: (context, userModelSnapshot) {
                  if (userModelSnapshot.connectionState == ConnectionState.waiting) {
                    // Show loading indicator while fetching user model
                    return Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else {
                    final userModel = userModelSnapshot.data;
                    if (userModel != null) {
                      // Navigate to BottomNavbarPage with the user model
                      return BottomNavbarPage(userModel: userModel);
                    } else {
                      // User model not found, handle accordingly
                      return const DashBoardPage(); // Example redirection to dashboard page
                    }
                  }
                },
              );
            } else {
              // User not logged in with Google, show the DashboardPage
              return const DashBoardPage();
            }
          }
        }
      },
    );
  }

  Future<UserModel?> getUserModel(String uid) async {
    return await FirebaseHelper.getUserModelById(uid);
  }
}
