import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:q/models/customCircularProgress.dart';
import 'package:q/screens/settings/edit_profile.dart';

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
  late UserModel _fetchedUserData = UserModel();
  bool _isLoading = true;
  String? _userProfilePictureUrl;

  StreamSubscription<DocumentSnapshot>? _userSnapshotSubscription;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      // User is authenticated
      try {
        await _user!.reload(); // Reload user data to ensure it's up to date
        await _fetchUserData(); // Fetch user data asynchronously
        // Subscribe to real-time updates
        _userSnapshotSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            // If the document exists, extract user data
            Map<String, dynamic>? userData =
                snapshot.data() as Map<String, dynamic>?;

            if (userData != null && userData.isNotEmpty) {
              // Check if user data is not empty and contains required fields
              _fetchedUserData = UserModel.fromMap(userData);
              // Check if the user logged in via Google
              if (_user!.providerData.isNotEmpty &&
                  _user!.providerData[0].providerId == 'google.com') {
                _userProfilePictureUrl = _user!.photoURL;
              } else {
                // Get the profile picture URL from user data
                _userProfilePictureUrl = _fetchedUserData.profile;
              }
              print('User profile picture URL: $_userProfilePictureUrl');
            } else {
              print('User data is empty or does not contain required fields');
            }
          } else {
            print('User document does not exist');
          }
        });
        setState(() {
          _isLoading = false; // Set loading state to false when data is loaded
        });
      } catch (e) {
        print('Error refreshing user: $e');
        setState(() {
          _isLoading = false; // Set loading state to false in case of error
        });
      }
    } else {
      print('User not authenticated');
      setState(() {
        _isLoading =
            false; // Set loading state to false if user is not authenticated
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    // Cancel the subscription when the widget is disposed
    _userSnapshotSubscription?.cancel();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userSnapshot.exists) {
          // If the document exists, extract user data
          Map<String, dynamic>? userData =
              userSnapshot.data() as Map<String, dynamic>?;

          if (userData != null && userData.isNotEmpty) {
            // Check if user data is not empty and contains required fields
            _fetchedUserData = UserModel.fromMap(userData);
            // Get the profile picture URL from user data in Firestore
            _userProfilePictureUrl = _fetchedUserData.profile;
            print('User profile picture URL: $_userProfilePictureUrl');
          } else {
            print('User data is empty or does not contain required fields');
          }
        } else {
          print('User document does not exist');
        }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BottomNavbarPage(
                    userModel: UserModel(phoneNumber: '', name: '')),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.power_settings_new_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fetchedUserData.name ?? '',
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                const Text(
                                  '500',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  "Followers",
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                const Text(
                                  '50',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  'Following',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary),
                                ),
                                const SizedBox(
                                    width: 20), // Adjust the width here
                              ],
                            ),
                            const SizedBox(
                              height: 7,
                            ),
                            Text(
                              _user?.email ??
                                  _fetchedUserData.phoneNumber ??
                                  '',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary),
                            ),
                            SizedBox(height: 10,),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 15, color: Theme.of(context).colorScheme.secondary,),
                                SizedBox(width: 2,),
                                Text(_fetchedUserData.location.toString(), style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16),),
                              ],
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.transparent,
                        child: _userProfilePictureUrl != null
                            ? _userProfilePictureUrl!.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: _userProfilePictureUrl!,
                                    imageBuilder: (context, imageProvider) =>
                                        CircleAvatar(
                                      backgroundImage: imageProvider,
                                      radius: 50,
                                    ),
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  )
                                : (_userProfilePictureUrl ==
                                            'DEFAULT_IMAGE_URL' ||
                                        _userProfilePictureUrl!.isEmpty)
                                    ? Icon(
                                        Icons.account_circle,
                                        size: 100,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                      )
                                    : CircleAvatar(
                                        backgroundImage: NetworkImage(
                                            _userProfilePictureUrl!),
                                        radius: 50,
                                      )
                            : Icon(
                                Icons.account_circle,
                                size: 100,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10,),
                  Row(
                    children: [
                      Icon(Icons.link_outlined, color: Theme.of(context).colorScheme.secondary, size: 16,),
                      SizedBox(width: 5,),
                      Text(_fetchedUserData.website.toString(), style: TextStyle(color: Colors.blue, fontSize: 16, letterSpacing: 0.7),),
                    ],
                  ),
                  SizedBox(height: 10,),
                  Text(_fetchedUserData.bio.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.secondary),),
                  const SizedBox(height: 20),
                  Container(
                    height: 30, // Set the desired height here
                    width: double.infinity, // Make the button full width
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10), // Set the border radius
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfilePage(), // Replace EditProfilePage() with your actual EditProfilePage constructor
                            ),
                          );
                        },
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // Same as ClipRRect borderRadius
                            ),
                          ),
                        ),
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
