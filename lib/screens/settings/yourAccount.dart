import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:q/screens/auth/dashBoard.dart';

class YourAccountPage extends StatefulWidget {
  const YourAccountPage({Key? key}) : super(key: key);

  @override
  State<YourAccountPage> createState() => _YourAccountPageState();
}

class _YourAccountPageState extends State<YourAccountPage> {
  late User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  void _handleLogout() async {
    try {
      // Sign out user from Firebase Authentication and Google
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      print("${_user?.displayName} logged out");

      // Navigate to the dashboard page
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashBoardPage()),
      );
    } catch (e) {
      print("Error logging out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your account'),
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.logout_outlined, color: Colors.red),
            title: Text('Logout'),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }
}
