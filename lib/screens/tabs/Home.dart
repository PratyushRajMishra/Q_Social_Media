import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q/widgets/audioPlayerWidget.dart';
import 'package:q/widgets/videoPlayerWidget.dart';
import '../Setting.dart';
import '../UserProfile.dart';
import '../comments.dart';
import '../postDetails.dart';
import '../target_profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user = FirebaseAuth.instance.currentUser;
  bool _showAppBar = true;
  String? _userName;
  String? _userProfilePic;
  bool _isLoading = true;
  TextEditingController _shareTextController =
      TextEditingController(); // Controller to capture text from TextField

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Function to fetch user data from Firestore
  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch user data from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        setState(() {
          _userName = userDoc['name']; // Assuming 'name' field exists
          _userProfilePic =
              userDoc['profile']; // Assuming 'profilePic' field exists
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              floating: false,
              pinned: false,
              snap: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              leading: GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UserProfilePage()));
                },
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Icon(Icons.error);
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Icon(Icons.account_circle,
                            size: 30,
                            color: Theme.of(context).colorScheme.tertiary);
                      }

                      Map<String, dynamic>? userData =
                          snapshot.data!.data() as Map<String, dynamic>?;

                      if (userData != null &&
                          userData.containsKey('profile') &&
                          userData['profile'] != null) {
                        return CircleAvatar(
                          radius: 25,
                          backgroundImage:
                              CachedNetworkImageProvider(userData['profile']),
                          backgroundColor: Colors.transparent,
                        );
                      } else {
                        return Icon(Icons.account_circle,
                            size: 30,
                            color: Theme.of(context).colorScheme.tertiary);
                      }
                    },
                  ),
                ),
              ),
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
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingPage()));
                  },
                  icon: const Icon(
                    Icons.settings_outlined,
                    size: 23,
                  ),
                ),
              ],
              expandedHeight: _showAppBar ? 60.0 : 0.0,
            ),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('posts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Icon(Icons.error)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text('No posts available')),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      DocumentSnapshot postDoc = snapshot.data!.docs[index];
                      Map<String, dynamic> postData =
                          postDoc.data() as Map<String, dynamic>;
                      String userId = postData['userId'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.hasError) {
                            return Container(); // or Error Widget
                          }

                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return ListTile(
                              title: Text('Unknown user'),
                              subtitle: Text(postData['text'] ?? ''),
                            );
                          }

                          Map<String, dynamic>? userData = userSnapshot.data!
                              .data() as Map<String, dynamic>?;

                          if (userData == null) {
                            return Container();
                          }

                          bool isLiked = (postData['likedBy'] as List<dynamic>?)
                                  ?.contains(_user?.uid) ??
                              false;

                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  );

                                  try {
                                    final commentsSnapshotFuture =
                                        FirebaseFirestore
                                            .instance
                                            .collection('comments')
                                            .where('postId',
                                                isEqualTo: postData['id'])
                                            .get();

                                    final likedSnapshotFuture =
                                        FirebaseFirestore.instance
                                            .collection('posts')
                                            .doc(postData['id'])
                                            .get();

                                    final List<dynamic> comments =
                                        (await commentsSnapshotFuture)
                                            .docs
                                            .map((commentDoc) =>
                                                commentDoc.data())
                                            .toList();

                                    final DocumentSnapshot likedSnapshot =
                                        await likedSnapshotFuture;
                                    final Map<String, dynamic>? likedData =
                                        likedSnapshot.data()
                                            as Map<String, dynamic>?;

                                    final List<dynamic> likedUsers =
                                        (likedData != null &&
                                                likedData['likedBy']
                                                    is List<dynamic>)
                                            ? likedData['likedBy']
                                            : [];

                                    Navigator.pop(context);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PostDetailsPage(
                                          username: userData['name'] ?? '',
                                          text: postData['text'] ?? '',
                                          profilePictureUrl:
                                              userData['profile'] ?? '',
                                          mediaUrl: postData['mediaUrl'] ?? '',
                                          postId: postData['id'] ?? '',
                                          comments: comments,
                                          postTime: postData['timestamp'],
                                          likedData: likedUsers,
                                          userIDs: userData['uid'] ?? '',
                                          fileType: postData['fileType'],
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    print("Error fetching data: $e");
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              String clickedUserId = userId;
                                              String currentUserId =
                                                  FirebaseAuth.instance
                                                          .currentUser?.uid ??
                                                      '';

                                              if (clickedUserId ==
                                                  currentUserId) {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            UserProfilePage()));
                                              } else {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            TargetProfilePage(
                                                                userId:
                                                                    clickedUserId)));
                                              }
                                            },
                                            child: CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                  userData['profile'] ?? ''),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Text(
                                                              userData[
                                                                      'name'] ??
                                                                  '',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .tertiary,
                                                              ),
                                                            ),
                                                            SizedBox(width: 10),
                                                            Text(
                                                              DateFormat(
                                                                      'dd MMM')
                                                                  .format(postData[
                                                                          'timestamp']
                                                                      .toDate()),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .secondary,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 5),
                                                        Container(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.7,
                                                          child: Text(
                                                            postData['text'] ??
                                                                '',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .tertiary,
                                                            ),
                                                          ),
                                                        ),
                                                        if (postData[
                                                                'mediaUrl'] !=
                                                            null)
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              SizedBox(
                                                                  height: 10),
                                                              if (postData[
                                                                      'fileType'] ==
                                                                  'video')
                                                                Container(
                                                                  constraints:
                                                                      BoxConstraints(
                                                                    maxHeight: MediaQuery.of(context)
                                                                            .size
                                                                            .height *
                                                                        0.5,
                                                                    maxWidth: MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        0.7,
                                                                  ),
                                                                  child:
                                                                      VideoPlayWidget(
                                                                    videoUrl: postData[
                                                                            'mediaUrl']
                                                                        .toString(),
                                                                  ),
                                                                )
                                                              else if (postData[
                                                                      'fileType'] ==
                                                                  'image')
                                                                ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                  child:
                                                                      Container(
                                                                    constraints:
                                                                        BoxConstraints(
                                                                      maxHeight:
                                                                          MediaQuery.of(context).size.height *
                                                                              0.5,
                                                                      maxWidth:
                                                                          MediaQuery.of(context).size.width *
                                                                              0.7,
                                                                    ),
                                                                    child:
                                                                        CachedNetworkImage(
                                                                      imageUrl:
                                                                          postData[
                                                                              'mediaUrl'],
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width *
                                                                          0.7,
                                                                      errorWidget: (context,
                                                                              url,
                                                                              error) =>
                                                                          Icon(Icons
                                                                              .error),
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                                  ),
                                                                )
                                                              else if (postData[
                                                                      'fileType'] ==
                                                                  'audio')
                                                                ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10),
                                                                  child: AudioPlayerWidget(
                                                                      audioFile:
                                                                          File(postData[
                                                                              'mediaUrl'])),
                                                                ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        // Like button
                                                        GestureDetector(
                                                          onTap: () async {
                                                            if (isLiked) {
                                                              await FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      'posts')
                                                                  .doc(postDoc
                                                                      .id)
                                                                  .update({
                                                                'likedBy':
                                                                    FieldValue
                                                                        .arrayRemove([
                                                                  _user?.uid
                                                                ])
                                                              });
                                                            } else {
                                                              await FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      'posts')
                                                                  .doc(postDoc
                                                                      .id)
                                                                  .update({
                                                                'likedBy':
                                                                    FieldValue
                                                                        .arrayUnion([
                                                                  _user?.uid
                                                                ])
                                                              });
                                                            }
                                                            setState(() {});
                                                          },
                                                          child: Icon(
                                                            isLiked
                                                                ? Icons.favorite
                                                                : Icons
                                                                    .favorite_border,
                                                            color: isLiked
                                                                ? Colors.red
                                                                : Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .secondary,
                                                            size: 20,
                                                          ),
                                                        ),
                                                        SizedBox(width: 5),
                                                        Visibility(
                                                          visible: (postData[
                                                                          'likedBy']
                                                                      as List<
                                                                          dynamic>?)
                                                                  ?.isNotEmpty ??
                                                              false,
                                                          child: Text(
                                                            '${(postData['likedBy'] as List<dynamic>?)?.length ?? 0}',
                                                            style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .secondary,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(width: 10),
                                                    // Comments button
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                CommentsPage(
                                                              username: userData[
                                                                      'name'] ??
                                                                  '',
                                                              postText: postData[
                                                                      'text'] ??
                                                                  '',
                                                              profilePictureUrl:
                                                                  userData[
                                                                          'profile'] ??
                                                                      '',
                                                              postId: postData[
                                                                      'id'] ??
                                                                  '',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Icon(
                                                        CupertinoIcons
                                                            .chat_bubble_text,
                                                        size: 20,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    // Share button
                                                    GestureDetector(
                                                      onTap: () async {
                                                        // Show the bottom sheet to confirm share action
                                                        showModalBottomSheet(
                                                          context: context,
                                                          isScrollControlled:
                                                              true,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.vertical(
                                                                    top: Radius
                                                                        .circular(
                                                                            20)),
                                                          ),
                                                          builder: (BuildContext
                                                              context) {
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(
                                                                      16.0),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  SizedBox(
                                                                      height:
                                                                          10),
                                                                  // Container with border for main content
                                                                  Column(
                                                                    children: [
                                                                      Row(
                                                                        children: [
                                                                          // Display current user's profile picture from Firestore
                                                                          CircleAvatar(
                                                                            backgroundImage:
                                                                                NetworkImage(_userProfilePic ?? ''),
                                                                            radius:
                                                                                20,
                                                                          ),
                                                                          SizedBox(
                                                                              width: 10),
                                                                          Expanded(
                                                                            child:
                                                                                Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                // Display current user's name from Firestore
                                                                                Text(
                                                                                  _userName ?? 'Unknown User',
                                                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                ),
                                                                                // Display current date
                                                                                Text(
                                                                                  DateFormat('yMMMd').format(DateTime.now()), // Current date formatted
                                                                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      TextField(
                                                                        controller:
                                                                            _shareTextController, // Attach the controller
                                                                        maxLength:
                                                                            50,
                                                                        maxLines:
                                                                            2,
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                18),
                                                                        onChanged:
                                                                            (_) {
                                                                          setState(
                                                                              () {});
                                                                        },
                                                                        decoration:
                                                                            InputDecoration(
                                                                          hintText:
                                                                              'Say something about this...',
                                                                          hintStyle: TextStyle(
                                                                              fontSize: 15,
                                                                              color: Colors.grey.shade500,
                                                                              letterSpacing: 1.0),
                                                                          border:
                                                                              InputBorder.none,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            12.0),
                                                                    child:
                                                                        Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        border: Border.all(
                                                                            color:
                                                                                Colors.grey.shade400), // Border color
                                                                        borderRadius:
                                                                            BorderRadius.circular(8.0), // Rounded corners
                                                                      ),
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              15.0), // Padding inside the border
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              CircleAvatar(
                                                                                backgroundImage: NetworkImage(userData['profile'] ?? ''),
                                                                                radius: 18,
                                                                              ),
                                                                              SizedBox(width: 10),
                                                                              Expanded(
                                                                                child: Column(
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    Text(
                                                                                      userData['name'] ?? 'Unknown User',
                                                                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                    Text(
                                                                                      postData['timestamp'] != null ? DateFormat('yMMMd').format((postData['timestamp'] as Timestamp).toDate()) : 'Unknown Date',
                                                                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          SizedBox(
                                                                              height: 10),
                                                                          Visibility(
                                                                            visible:
                                                                                postData['text'] != null && postData['text'].isNotEmpty,
                                                                            child:
                                                                                Padding(
                                                                              padding: const EdgeInsets.only(bottom: 10.0),
                                                                              child: Text(
                                                                                postData['text'] ?? '',
                                                                                style: TextStyle(fontSize: 16),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                              height: 0),
                                                                          if (postData['mediaUrl'] != null &&
                                                                              postData['mediaUrl'].isNotEmpty)
                                                                            Padding(
                                                                              padding: const EdgeInsets.symmetric(vertical: 0),
                                                                              child: ClipRRect(
                                                                                borderRadius: BorderRadius.circular(8.0),
                                                                                child: Stack(
                                                                                  children: [
                                                                                    Container(
                                                                                      width: double.infinity,
                                                                                      height: 100,
                                                                                      color: Colors.grey.shade300,
                                                                                      child: Center(
                                                                                        child: CircularProgressIndicator(strokeWidth: 2.0),
                                                                                      ),
                                                                                    ),
                                                                                    Image.network(
                                                                                      postData['mediaUrl'],
                                                                                      width: double.infinity,
                                                                                      height: 100,
                                                                                      fit: BoxFit.cover,
                                                                                      loadingBuilder: (context, child, loadingProgress) {
                                                                                        if (loadingProgress == null) return child;
                                                                                        return Container();
                                                                                      },
                                                                                      errorBuilder: (context, error, stackTrace) {
                                                                                        return Container(
                                                                                          height: 100,
                                                                                          width: double.infinity,
                                                                                          color: Colors.black,
                                                                                          child: IconButton(
                                                                                            onPressed: () {
                                                                                              Fluttertoast.showToast(
                                                                                                msg: '⚠️  Media can not play here!',
                                                                                                toastLength: Toast.LENGTH_SHORT,
                                                                                                gravity: ToastGravity.TOP,
                                                                                                backgroundColor: Colors.black87,
                                                                                                textColor: Colors.white,
                                                                                                fontSize: 16.0,
                                                                                              );
                                                                                            },
                                                                                            icon: Icon(Icons.play_circle, color: Colors.white),
                                                                                          ),
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                      height:
                                                                          20),
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceAround,
                                                                    children: [
                                                                      // Share now button
                                                                      ElevatedButton(
                                                                        onPressed:
                                                                            () async {
                                                                          // Update post data with sharedBy
                                                                          await FirebaseFirestore
                                                                              .instance
                                                                              .collection('posts')
                                                                              .doc(postDoc.id)
                                                                              .update({
                                                                            'sharedBy':
                                                                                FieldValue.arrayUnion([
                                                                              _user?.uid
                                                                            ]),
                                                                          });

                                                                          // Save shared post information (postId, userId, and shared text)
                                                                          await FirebaseFirestore
                                                                              .instance
                                                                              .collection('users')
                                                                              .doc(_user?.uid)
                                                                              .collection('sharedPosts') // Subcollection to keep track of shared posts
                                                                              .add({
                                                                            'postId':
                                                                                postDoc.id,
                                                                            'userId':
                                                                                _user?.uid,
                                                                            'sharedText':
                                                                                _shareTextController.text, // Save the entered text
                                                                            'timestamp':
                                                                                FieldValue.serverTimestamp(),
                                                                          });

                                                                          // Optionally, update the current user's shared posts field
                                                                          await FirebaseFirestore
                                                                              .instance
                                                                              .collection('users')
                                                                              .doc(_user?.uid)
                                                                              .update({
                                                                            'sharedPosts':
                                                                                FieldValue.arrayUnion([
                                                                              postDoc.id
                                                                            ]),
                                                                          });
                                                                          _shareTextController
                                                                              .clear();

                                                                          setState(
                                                                              () {});
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        style: ElevatedButton
                                                                            .styleFrom(
                                                                          backgroundColor:
                                                                              Colors.blue, // Set background color
                                                                          onPrimary:
                                                                              Colors.white, // Text color
                                                                          shape:
                                                                              RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(12), // Rounded corners
                                                                          ),
                                                                          padding: EdgeInsets.symmetric(
                                                                              horizontal: 30,
                                                                              vertical: 5), // Custom padding
                                                                          elevation:
                                                                              5, // Shadow for the button
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          'Repost now',
                                                                          style: TextStyle(
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.bold),
                                                                        ),
                                                                      ),
                                                                      // Cancel button
                                                                      OutlinedButton(
                                                                        onPressed:
                                                                            () {
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        style: OutlinedButton
                                                                            .styleFrom(
                                                                          primary: Theme.of(context)
                                                                              .colorScheme
                                                                              .secondary, // Text color
                                                                          side:
                                                                              BorderSide(
                                                                            color:
                                                                                Theme.of(context).colorScheme.secondary, // Border color
                                                                            width:
                                                                                2, // Border width
                                                                          ),
                                                                          shape:
                                                                              RoundedRectangleBorder(
                                                                            borderRadius:
                                                                                BorderRadius.circular(12), // Rounded corners
                                                                          ),
                                                                          padding: EdgeInsets.symmetric(
                                                                              horizontal: 30,
                                                                              vertical: 5), // Custom padding
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          'Cancel',
                                                                          style: TextStyle(
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.bold),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                              CupertinoIcons
                                                                  .arrow_2_squarepath,
                                                              size: 20,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .secondary),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: GestureDetector(
                                              onTap: () => _showPostOptions(postData), // Pass the specific post data
                                              child: Icon(
                                                Icons.more_vert,
                                                color: Colors.black26,
                                                size: 17,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Divider(),
                            ],
                          );
                        },
                      );
                    },
                    childCount: snapshot.data!.docs.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Method to show bottom sheet options
  void _showPostOptions(Map<String, dynamic> postData) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to view options.')),
      );
      return;
    }

    // Fetch the saved status dynamically
    final savedStatus = await _checkIfPostSaved(postData['id'], userId);

    postData['isBookmarked'] = savedStatus; // Update the postData state

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                postData['isBookmarked'] == true
                    ? Icons.bookmark_remove
                    : Icons.bookmark,
              ),
              title: Text(
                postData['isBookmarked'] == true ? 'Unsave Post' : 'Save Post',
              ),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                _savePosts(postData);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Post'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                // Handle edit post logic
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete Post'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                // Handle delete post logic
              },
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share Post'),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
                // Handle share post logic
              },
            ),
          ],
        );
      },
    );
  }

// Check if the post is already saved
  Future<bool> _checkIfPostSaved(String postId, String userId) async {
    try {
      final savedPostsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedPosts');

      final existingPost =
      await savedPostsRef.where('postId', isEqualTo: postId).get();

      return existingPost.docs.isNotEmpty;
    } catch (e) {
      print('Error checking saved status: $e');
      return false; // Assume not saved if an error occurs
    }
  }

// Save/Unsave post logic
  void _savePosts(Map<String, dynamic> postData) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to save posts.')),
      );
      return;
    }

    try {
      // Reference to the saved posts collection
      final savedPostsRef =
      firestore.collection('users').doc(userId).collection('savedPosts');

      // Check if the post is already saved
      final existingPost =
      await savedPostsRef.where('postId', isEqualTo: postData['id']).get();

      if (existingPost.docs.isNotEmpty) {
        // Post already saved, remove it
        await existingPost.docs.first.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post removed from saved posts.')),
        );

        // Update the icon state for this specific post
        setState(() {
          postData['isBookmarked'] = false; // Mark this post as unbookmarked
        });
      } else {
        // Save the post
        await savedPostsRef.add({
          'postId': postData['id'],
          'userId': postData['userId'],
          'text': postData['text'],
          'mediaUrl': postData['mediaUrl'],
          'timestamp': postData['timestamp'],
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post saved successfully!')),
        );

        // Update the icon state for this specific post
        setState(() {
          postData['isBookmarked'] = true; // Mark this post as bookmarked
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save post: $e')),
      );
    }
  }


}
