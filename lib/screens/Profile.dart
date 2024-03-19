import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/userModel.dart';
import 'auth/dashBoard.dart';
import 'bottom_NavBar.dart';

class ProfilePage extends StatefulWidget {
  final String? title;
  final UserModel? userModel;

  const ProfilePage({Key? key, this.title, this.userModel}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User? _user;
  late UserModel _fetchedUserData = UserModel(); // Initialize with an empty UserModel

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _fetchUserData();
  }

  Future<void> _initializeUser() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      // User is authenticated
      try {
        await _user!.reload(); // Reload user data to ensure it's up to date
        setState(() {}); // Refresh UI
      } catch (e) {
        print('Error refreshing user: $e');
      }
    } else {
      print('User not authenticated');
    }
  }

  Future<void> _fetchUserData() async {
    try {
      // Fetch user data from Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      Map<String, dynamic>? userData = userSnapshot.data() as Map<String, dynamic>?;

      if (userData != null) {
        _fetchedUserData = UserModel.fromMap(userData);
        setState(() {});
      } else {
        print('User data is null');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }


  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    Navigator.popUntil(context, (route) => route.isFirst);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) {
        return const DashBoardPage();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _user?.displayName ?? _fetchedUserData.name ?? '',
          style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
        ),
        leading: BackButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BottomNavbarPage(userModel: UserModel(phoneNumber: '', name: '')),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: Icon(Icons.power_settings_new_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(100.0),
            child: CachedNetworkImage(
              imageUrl: _user?.photoURL ?? 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Unicode_0x0051.svg/1200px-Unicode_0x0051.svg.png',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => CircleAvatar(
                child: Icon(CupertinoIcons.person),
              ),
            ),
          ),
          SizedBox(height: 20),
          // Display fetched user data
          Text('Name: ${_fetchedUserData.name ?? ''}'),
          Text('Phone Number: ${_fetchedUserData.phoneNumber ?? ''}'),
          Text('Date of Birth: ${_fetchedUserData.dob ?? ''}'),
        ],
      ),
    );
  }
}
