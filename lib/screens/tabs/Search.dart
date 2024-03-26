import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Profile.dart';
import '../Setting.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool isSearchBarVisible = false;
  bool isFollowing = false;

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
      body: ListView.builder(
        itemCount: 21,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.account_circle_sharp, color: Theme.of(context).colorScheme.tertiary, size: 40,),
            title: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Item $index',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subtitle $index', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  const SizedBox(height: 2),
                  Text('Followers $index', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
            trailing: SizedBox(
              height: 30,
              width: 90,
              child: OutlinedButton(
                onPressed: () {
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
              // Handle item tap
              print('Tapped on Item $index');
            },
          );
        },
      ),
    );
  }

  Widget buildSearchBody() {
    return const Center(
        child: Text('Try searching for people, topics or keywords',
          style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w600),));
  }

  AppBar buildDefaultAppBar() {
    User? _user = FirebaseAuth.instance.currentUser;
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      leading: isSearchBarVisible ? null :
      GestureDetector(
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
          hintText: 'Search Q',
          hintStyle: TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}
