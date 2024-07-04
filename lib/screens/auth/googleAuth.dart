import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:q/models/userModel.dart';
import 'package:q/screens/auth/dashBoard.dart';
import 'package:q/screens/bottom_NavBar.dart';
import '../../models/FirebaseHelper.dart';
import '../../models/customCircularProgress.dart';

class GoogleAuth extends StatelessWidget {
  const GoogleAuth({Key? key}) : super(key: key);

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      // Sign out from Google and Firebase to ensure fresh login
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().disconnect(); // Ensure the account picker shows up

      // Sign in with Google
      GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return;
      }

      GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Get the Google authentication credentials
      AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Save user data to Firebase Firestore
      if (userCredential.user != null) {
        UserModel userModel = UserModel(
          uid: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? '',
          email: userCredential.user!.email ?? '',
        );
        await FirebaseHelper.saveUserModel(userModel); // Save user model to Firestore
      }

      // Navigate to the BottomNavbarPage after successful authentication
      if (userCredential.user != null) {
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavbarPage(
              userModel: UserModel(
                uid: userCredential.user!.uid,
                name: userCredential.user!.displayName ?? '',
                email: userCredential.user!.email ?? '',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing in with Google: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while checking the authentication state
          return const Scaffold(
            body: Center(
              child: CustomCircularProgressIndicator(
                imagePath: 'assets/logo_dark.png',
                size: 120.0,
                darkModeImagePath: 'assets/logo_light.png',
              ),
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
                        child: CustomCircularProgressIndicator(
                          imagePath: 'assets/logo_dark.png',
                          size: 120.0,
                          darkModeImagePath: 'assets/logo_light.png',
                        ),
                      ),
                    );
                  } else if (userModelSnapshot.hasError) {
                    // Handle error while fetching user model
                    return Scaffold(
                      body: Center(
                        child: Text('Error fetching user model: ${userModelSnapshot.error}'),
                      ),
                    );
                  } else {
                    final userModel = userModelSnapshot.data;
                    if (userModel != null) {
                      // Navigate to BottomNavbarPage with the user model
                      return BottomNavbarPage(userModel: userModel);
                    } else {
                      // User model not found, handle accordingly
                      return const DashBoardPage();
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
