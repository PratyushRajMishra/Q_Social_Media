import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Setting.dart';
import '../UserProfile.dart';
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    User? _user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        //centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => const UserProfilePage()));
          },
          child: Padding(
            padding: const EdgeInsets.all(13.0),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(_user?.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Display a loading indicator while fetching user data
                }

                if (snapshot.hasError) {
                  return Icon(Icons.error); // Display an error icon if there's an error fetching user data
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Icon(Icons.account_circle, size: 30, color: Theme.of(context).colorScheme.tertiary);
                }

                // Access user data from the snapshot
                Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;

                // Check if user has a profile picture URL
                if (userData.containsKey('profile') && userData['profile'] != null) {
                  return CircleAvatar(
                    radius: 25,
                    backgroundImage: CachedNetworkImageProvider(userData['profile']),
                    backgroundColor: Colors.transparent,
                  );
                } else {
                  return Icon(Icons.account_circle, size: 30, color: Theme.of(context).colorScheme.tertiary);
                }
              },
            ),
          ),
        ),
        title: Text('Notifications', style: TextStyle(color: Theme.of(context).colorScheme.tertiary,letterSpacing: 1.0),),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => const SettingPage()),
              );
            },
            icon: Icon(Icons.settings_outlined, size: 23,),
          ),
        ],
      ),
      body: Center(
        child: Text('Notifications Page Content'),
      ),
    );
  }
}
