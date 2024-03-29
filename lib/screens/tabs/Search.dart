import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:q/screens/target_profile.dart';

import '../Profile.dart';
import '../Setting.dart';




class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _searchController = TextEditingController(); // Initialize TextEditingController
  bool isSearchBarVisible = false;
  bool isFollowing = false;
  String _searchQuery = '';
  late Query _usersQuery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: isSearchBarVisible ? buildSearchAppBar() : buildDefaultAppBar(context),
      body: isSearchBarVisible
          ? buildSearchBody()
          : buildDefaultBody(),
    );
  }


  AppBar buildDefaultAppBar(BuildContext context) {
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
            //color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.blueGrey.shade100, width: 0.3),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9.0),
            child: Text(
              'Search Q',
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
          icon: const Icon(Icons.settings_outlined, size: 23),
        ),
      ],
    );
  }

  Widget buildDefaultBody() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('uid', isNotEqualTo: currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var userData = snapshot.data!.docs[index].data() as Map<String, dynamic>; // Cast userData to Map<String, dynamic>
              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(userData['profile'] ?? ''), // Assuming 'profileImageUrl' is the field containing the profile image URL
                ),
                title: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    userData['name'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    userData['email'] != null ? userData['email']! : (userData['phoneNumber'] != null ? userData['phoneNumber']! : ''),
                  ),
                ),
                trailing: SizedBox(
                  height: 30,
                  width: 90,
                  child: OutlinedButton(
                    onPressed: () {
                      // Handle button press
                      setState(() {
                        isFollowing = !isFollowing;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => TargetProfilePage(userId: userData['uid'])),
                  );
                },
              );

            },
          );
        },
      ),
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
        icon: Icon(Icons.arrow_back),
      ),
      title: TextField(
        controller: _searchController,
        onChanged: (value) => searchUsers(value),
        autofocus: true,
        style: TextStyle(),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search Q',
          hintStyle: TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Widget buildSearchBody() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Text(
          'Try searching for people using their names..',
          style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );
    } else {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('name', isGreaterThanOrEqualTo: _searchController.text) // Step 2
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No results found',
                style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var userData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(userData['profile'] ?? ''), // Assuming 'profile' contains the profile image URL
                ),
                title: Text(userData['name'] ?? ''),
                subtitle: Text(
                  userData['email'] != null ? userData['email']! : (userData['phoneNumber'] != null ? userData['phoneNumber']! : ''),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TargetProfilePage(userId: userData['uid'])),
                  );
                },
              );
            },
          );
        },
      );
    }
  }

  // Function to perform search operation based on entered text (Step 2)
  void searchUsers(String query) {
    setState(() {
      _searchQuery = query.trim();
      _usersQuery = FirebaseFirestore.instance.collection('users')
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          .where('name', isLessThan: _searchQuery + 'z');
    });
  }
}
