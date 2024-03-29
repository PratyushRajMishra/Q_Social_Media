import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:q/screens/write_message.dart';

import '../Profile.dart';
import '../Setting.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({Key? key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  bool isSearchBarVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: isSearchBarVisible ? buildSearchAppBar() : buildDefaultAppBar(),
      body: isSearchBarVisible
          ? buildSearchBody()
          : buildDefaultBody(), // Show either search or default body
    );
  }

  Widget buildDefaultBody() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to your inbox!',
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Drop a line, share posts and more with private\n'
                  'conversations between you and others on Q.',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 35),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const WriteMessagePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 13),
                child: Text(
                  'Write a message',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }


  Widget buildSearchBody() {
    return Center(
        child: Text('Try searching for people, groups or messages',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w600),));
  }

  AppBar buildDefaultAppBar() {
    User? _user = FirebaseAuth.instance.currentUser;
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => const ProfilePage()));
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
      title: InkWell(
        onTap: () {
          setState(() {
            isSearchBarVisible = true;
          });
        },
        child: Container(
          height: 35,
          width: double.maxFinite,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.blueGrey.shade100, width: 0.3),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9.0),
            child: Text(
              'Search Direct Messages',
              style: TextStyle(
                fontSize: 15,
                color: Colors.blueGrey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const SettingPage()),
            );
          },
          icon: Icon(Icons.settings_outlined, size: 23),
        ),
      ],
    );
  }

  AppBar buildSearchAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        onPressed: () {
          setState(() {
            isSearchBarVisible = false;
          });
        },
        icon: Icon(Icons.arrow_back,),
      ),
      title: TextField(
        autofocus: true,
        style: TextStyle(),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search Direct Messages',
          hintStyle: TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}
