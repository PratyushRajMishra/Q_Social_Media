import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:q/screens/auth/createAccount.dart';
import 'package:q/screens/auth/login_screen.dart';

import '../../models/FirebaseHelper.dart';
import '../../models/customCircularProgress.dart';
import '../../models/userModel.dart';
import '../bottom_NavBar.dart';

class DashBoardPage extends StatefulWidget {
  const DashBoardPage({Key? key}) : super(key: key);

  @override
  State<DashBoardPage> createState() => _DashBoardPageState();
}

class _DashBoardPageState extends State<DashBoardPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
      Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Builder(
            builder: (BuildContext context) {
              return Image.asset(
                Theme.of(context).brightness == Brightness.light
                    ? 'assets/logo_dark.png'
                    : 'assets/logo_light.png',
                height: 40,
                width: 40,
              );
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: screenHeight * 0.25, top: screenHeight * 0.25),
                  child: Center(
                    child: Text(
                      "Unleash your thoughts with the power of anonymity!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  width: 300,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => signInWithGoogle(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/google_logo.png',
                          height: 22,
                          width: 22,
                        ),
                        const SizedBox(width: 10,),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Container(
                        height: 1,
                        width: MediaQuery.of(context).size.width * 0.3,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      Text('or', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary,),),
                      Container(
                        height: 1,
                        width: MediaQuery.of(context).size.width * 0.3,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                  width: 300,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateAccountPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Text('Create account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Text("By signing up, you agree to our terms, Privacy Policy, and Cookie use.",
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 25),
                  child: Row(
                    children: [
                      Text('Have an account already? ', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 15),),
                      const SizedBox(width: 3,),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: Text('Log in', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500, fontSize: 15),),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
        if (_isLoading)
          Container(
            color: Theme.of(context).colorScheme.onTertiary,
            child: Center(
              child: CustomCircularProgressIndicator(imagePath: 'assets/logo_dark.png',  size: 120.0, darkModeImagePath: 'assets/logo_light.png',), // Full-screen circular progress indicator
            ),
          ),
            ]
    );
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Sign in with Google
      GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      // Get the Google authentication credentials
      AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Sign in to Firebase with the Google credentials
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      // Check if the user exists in Firestore based on their UID
      bool userExists = await FirebaseHelper.doesUserExist(userCredential.user!.uid);

      if (userExists) {
        // User exists, retrieve user data from Firestore
        UserModel? userModel = await FirebaseHelper.getUserModelById(userCredential.user!.uid);
        if (userModel != null) {
          // Navigate to BottomNavbarPage with the user model
          Navigator.popUntil(context, (route) => route.isFirst);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BottomNavbarPage(
                userModel: userModel,
              ),
            ),
          );
        } else {
          // User model not found, handle accordingly
          print('User model not found');
          // You can handle this case by showing an error message or redirecting to another page
        }
      } else {
        // User is a new user, create a new user account and save data to Firestore
        UserModel userModel = UserModel(
          uid: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? '', // Providing a default value if displayName is null
          email: userCredential.user!.email ?? '', // Providing a default value if email is null
          // You may add more fields to the UserModel here
        );
        await FirebaseHelper.saveUserModel(userModel); // Save user model to Firestore

        // Navigate to BottomNavbarPage as user is new
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavbarPage(
              userModel: userModel,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      // Handle sign-in errors
    } finally {
      // Hide circular progress indicator after sign-in process completes
      setState(() {
        _isLoading = false;
      });
    }
  }

}
