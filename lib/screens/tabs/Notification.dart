import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Profile.dart';
import '../Setting.dart';
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
            Navigator.push(context, CupertinoPageRoute(builder: (context) => const ProfilePage()),);
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.transparent, // Match with the background color
              child: _user?.photoURL != null // Check if user has a photoURL
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(100.0),
                child: CachedNetworkImage(
                  imageUrl: _user!.photoURL!,
                  width: 100, // Set the desired width
                  height: 100, // Set the desired height
                  fit: BoxFit.cover, // Adjust the fit as per your requirement
                  placeholder: (context, url) => CircularProgressIndicator(), // Placeholder widget while loading
                  errorWidget: (context, url, error) => Icon(Icons.error), // Error widget if image fails to load
                ),
              )
                  : Icon(Icons.account_circle, size: 30, color: Theme.of(context).colorScheme.tertiary,), // Display an icon if no photoURL is available
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
