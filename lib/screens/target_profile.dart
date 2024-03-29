import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/userModel.dart';

class TargetProfilePage extends StatefulWidget {
  final String userId;

  const TargetProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _TargetProfilePageState createState() => _TargetProfilePageState();
}

class _TargetProfilePageState extends State<TargetProfilePage> {
  late UserModel _userData;
  bool _isLoading = true;
  String? _userProfilePictureUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userSnapshot.exists) {
        Map<String, dynamic>? userData = userSnapshot.data();

        if (userData != null && userData.isNotEmpty) {
          setState(() {
            _userData = UserModel.fromMap(userData);
            _userProfilePictureUrl = _userData.profile;
            _isLoading = false;
          });
        } else {
          print('User data is empty or does not contain required fields');
        }
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isLoading
            ? Text(
          'Loading...',
          style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
        )
            : Text(
          _userData.name.toString(),
          style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData.name ?? '',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 7),
                    Row(
                      children: [
                        Text(
                          '50',
                          //_userData.followers.toString(),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 5),
                        Text(
                          "Followers",
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                        SizedBox(width: 20),
                        Text(
                          '500',
                          //_userData.following.toString(),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Following',
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                        SizedBox(width: 20),
                      ],
                    ),
                    SizedBox(height: 7),
                    Text(
                      _userData.email ?? _userData.phoneNumber ?? '',
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.secondary),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 15, color: Theme.of(context).colorScheme.secondary,),
                        SizedBox(width: 2,),
                        Text(
                          _userData.location.toString(),
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.transparent,
                  child: _userProfilePictureUrl != null
                      ? _userProfilePictureUrl!.startsWith('http')
                      ? CachedNetworkImage(
                    imageUrl: _userProfilePictureUrl!,
                    imageBuilder: (context, imageProvider) => CircleAvatar(
                      backgroundImage: imageProvider,
                      radius: 50,
                    ),
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  )
                      : (_userProfilePictureUrl == 'DEFAULT_IMAGE_URL' ||
                      _userProfilePictureUrl!.isEmpty)
                      ? Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Theme.of(context).colorScheme.tertiary,
                  )
                      : CircleAvatar(
                    backgroundImage: NetworkImage(_userProfilePictureUrl!),
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
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                launchUrl(
                    Uri.parse(_userData.website.toString()),
                    mode: LaunchMode.inAppBrowserView
                );
              },
              child: Row(
                children: [
                  Icon(Icons.link_outlined,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 16),
                  SizedBox(width: 5),
                  Text(
                    _userData.website.toString(),
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        letterSpacing: 0.7),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              _userData.bio.toString(),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.secondary),
            ),
            SizedBox(height: 20),
            Container(
              height: 30,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Handle edit profile button
                },
                child: Text(
                  'Follow',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
