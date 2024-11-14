import 'dart:async';
import 'dart:io';


import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';
import 'package:q/followersList.dart';
import 'package:q/screens/comments.dart';
import 'package:q/screens/postDetails.dart';
import 'package:q/screens/settings/edit_profile.dart';
import 'package:q/screens/tabs/Post.dart';
import 'package:url_launcher/url_launcher.dart';

import '../followingList.dart';
import '../models/customCircularProgress.dart';
import '../models/postModel.dart';
import '../models/userModel.dart';
import '../widgets/audioPlayerWidget.dart';
import '../widgets/videoPlayerWidget.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late User? _user;
  late UserModel _userData = UserModel();
  bool _isLoading = true;
  String? _userProfilePictureUrl;
  List<PostModel> _userPosts = [];
  late TabController? _tabController;
  int followersCount = 0; // Define variable to hold followers count
  int followingCount = 0; // Define variable to hold following count

  StreamSubscription<DocumentSnapshot>? _userSnapshotSubscription;

  @override
  void initState() {
    super.initState();
    _userPosts = [];
    _tabController = TabController(vsync: this, length: 3);
    _initializeUser();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController?.dispose();
    _userSnapshotSubscription?.cancel();
  }

  Future<void> _initializeUser() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      try {
        await _user!.reload();
        await _fetchUserDataAndPosts();
        _userSnapshotSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            Map<String, dynamic>? userData =
                snapshot.data() as Map<String, dynamic>?;
            if (userData != null && userData.isNotEmpty) {
              _userData = UserModel.fromMap(userData);
              _userProfilePictureUrl = userData['profile'] ?? _user!.photoURL;
            } else {
              print('User data is empty or does not contain required fields');
            }
          } else {
            print('User document does not exist');
          }
        });
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        print('Error refreshing user: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('User not authenticated');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserDataAndPosts() async {
    try {
      // Fetch user posts
      QuerySnapshot postSnapshot = await FirebaseFirestore.instance
          // .collection('users')
          // .doc(_user?.uid)
          .collection('posts')
          .where('userId', isEqualTo: _user!.uid)
          .get();

      _userPosts.clear(); // Clear the list before populating it

      if (postSnapshot.docs.isNotEmpty) {
        _userPosts = postSnapshot.docs.map((doc) {
          if (doc.exists) {
            return PostModel.fromMap(doc.data() as Map<String, dynamic>);
          } else {
            throw Exception('Document does not exist');
          }
        }).toList();
      } else {
        print('No posts');
      }

      // Fetch user data including followers and following
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user?.uid)
              .get();
      if (userSnapshot.exists) {
        Map<String, dynamic>? userData = userSnapshot.data();

        if (userData != null && userData.isNotEmpty) {
          _userData = UserModel.fromMap(userData);
          _userProfilePictureUrl = _userData.profile;
        } else {
          print('User data is empty or does not contain required fields');
        }
      } else {
        print('User document does not exist');
      }

      setState(() {});
    } catch (e, stackTrace) {
      print('Error fetching user data and posts: $e');
      print(stackTrace);
    }
  }


  Future<List<Map<String, dynamic>>> getRepostedPosts() async {
    // Fetch the user's shared post IDs
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_user?.uid).get();
    List<String> sharedPostIds = List<String>.from(userDoc['sharedPosts'] ?? []);

    // Fetch the shared post data from the 'posts' collection
    List<Map<String, dynamic>> repostedPosts = [];
    for (var postId in sharedPostIds) {
      var postDoc = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
      if (postDoc.exists) {
        repostedPosts.add(postDoc.data() as Map<String, dynamic>);
      }
    }

    return repostedPosts;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _userData != null && _userProfilePictureUrl != null
          ? DefaultTabController(
              length: 4,
              child: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      titleSpacing: 0,
                      title: Text(
                        _userData.name.toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.0,
                        ),
                      ),
                      stretch: true,
                      backgroundColor: Theme.of(context).colorScheme.background,
                      elevation: 0,
                      pinned: true,
                      expandedHeight: MediaQuery.of(context).size.height * 0.34,
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.parallax,
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 15, right: 15, top: 75, bottom: 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 15),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 15),
                                                  child: Row(
                                                    children: [
                                                      Column(
                                                        children: [
                                                          Text(
                                                            _userPosts.length
                                                                .toString(),
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 5),
                                                          Text(
                                                            'Posts',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .tertiary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(width: 30),
                                                      InkWell(
                                                        onTap: () {
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          FollowersListPage(userId: _userData.uid.toString(),)));
                                                        },
                                                        child: Column(
                                                          children: [
                                                            Text(
                                                              _userData
                                                                  .followers!
                                                                  .length
                                                                  .toString(),
                                                              style: TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 5),
                                                            Text(
                                                              'Followers',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .tertiary,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 30),
                                                      InkWell(
                                                        onTap: () {
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                      FollowingListPage(userId: _userData.uid.toString(),)));
                                                        },
                                                        child: Column(
                                                          children: [
                                                            Text(
                                                              _userData.following!
                                                                  .length
                                                                  .toString(),
                                                              style: TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 5),
                                                            Text(
                                                              'Following',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .tertiary,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 3),
                                                  child: Text(
                                                    _user?.email ??
                                                        _userData.phoneNumber ??
                                                        '',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .location_on_outlined,
                                                      size: 15,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                    ),
                                                    SizedBox(
                                                      width: 2,
                                                    ),
                                                    Text(
                                                      _userData.location
                                                          .toString(),
                                                      style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .secondary,
                                                          fontSize: 16),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          CircleAvatar(
                                            radius: 50,
                                            backgroundColor: Colors.transparent,
                                            child: _userProfilePictureUrl !=
                                                    null
                                                ? _userProfilePictureUrl!
                                                        .startsWith('http')
                                                    ? CachedNetworkImage(
                                                        imageUrl:
                                                            _userProfilePictureUrl!,
                                                        imageBuilder: (context,
                                                                imageProvider) =>
                                                            CircleAvatar(
                                                          backgroundImage:
                                                              imageProvider,
                                                          radius: 50,
                                                        ),
                                                        placeholder: (context,
                                                                url) =>
                                                            Center(
                                                                child:
                                                                    const CircularProgressIndicator()),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            const Icon(
                                                                Icons.error),
                                                      )
                                                    : (_userProfilePictureUrl ==
                                                                'DEFAULT_IMAGE_URL' ||
                                                            _userProfilePictureUrl!
                                                                .isEmpty)
                                                        ? Icon(
                                                            Icons
                                                                .account_circle,
                                                            size: 100,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .tertiary,
                                                          )
                                                        : CircleAvatar(
                                                            backgroundImage:
                                                                NetworkImage(
                                                                    _userProfilePictureUrl!),
                                                            radius: 50,
                                                          )
                                                : Icon(
                                                    Icons.account_circle,
                                                    size: 100,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .tertiary,
                                                  ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          launchUrl(
                                              Uri.parse(
                                                  _userData.website.toString()),
                                              mode:
                                                  LaunchMode.inAppBrowserView);
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.link_outlined,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              size: 16,
                                            ),
                                            SizedBox(
                                              width: 5,
                                            ),
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
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        _userData.bio.toString(),
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 30,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      CupertinoPageRoute(
                                                        builder: (context) => PostPage(audioPath: ''),
                                                      ),
                                                    );
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor: MaterialStateProperty.all(Colors.blue),
                                                    foregroundColor: MaterialStateProperty.all(Colors.white),
                                                    shape: MaterialStateProperty.all(
                                                      RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center, // Center icon and text
                                                    children: [
                                                      Icon(CupertinoIcons.add_circled, size: 18),
                                                      SizedBox(width: 8), // Add spacing between icon and text if needed
                                                      Text(
                                                        'Add to Post',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 20,
                                          ),
                                          Expanded(
                                            child: Container(
                                              height: 30,
                                              child: ClipRRect(
                                                borderRadius:
                                                BorderRadius.circular(10),
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            EditProfilePage(),
                                                      ),
                                                    );
                                                  },
                                                  style: ButtonStyle(
                                                    shape: MaterialStateProperty
                                                        .all(
                                                      RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(10),
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Edit Profile',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: MySliverPersistentHeaderDelegate(
                        TabBar(
                          labelColor: Theme.of(context).colorScheme.tertiary,
                          unselectedLabelColor:
                              Theme.of(context).colorScheme.secondary,
                          indicatorColor: Colors.blue,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorWeight: 2.5,
                          tabs: const [
                            Tab(
                              child: Text(
                                'Posts',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Tab(
                              child: Text(
                                'Replies',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Tab(
                              child: Text(
                                'Reposted',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Tab(
                              child: Text(
                                'Saved',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    _buildPostsTab(),
                    _buildRepliesTab(),
                    _buildRepostedTab(),
                    _buildSavedTab(),
                  ],
                ),
              ),
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Widget _buildPostsTab() {
    _userPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort posts by timestamp in descending order

    return Column(
      children: [
        Visibility(
          visible: _userPosts.isEmpty,
          child: FutureBuilder(
            future: Future.delayed(Duration(milliseconds: 0)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else {
                return Center(child: Text('No posts'));
              }
            },
          ),
        ),
        Visibility(
          visible: _userPosts.isNotEmpty,
          child: Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10.0),
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _userPosts.length,
              itemBuilder: (context, index) {
                bool isLiked = _userPosts[index]
                    .likedBy
                    .contains(FirebaseAuth.instance.currentUser?.uid);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: ListTile(
                        onTap: () async {
                          showDialog(
                            barrierDismissible: false, // Prevent user from dismissing the dialog
                            context: context,
                            builder: (BuildContext context) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          );

                          try {
                            // Fetch comments data and liked data simultaneously
                            final commentsSnapshotFuture = FirebaseFirestore.instance.collection('comments').where('postId', isEqualTo: _userPosts[index].id).get();
                            final likedSnapshotFuture = FirebaseFirestore.instance.
                           // collection('users').doc(_userData.uid).
                            collection('posts').doc(_userPosts[index].id).get();

                            // Wait for both futures to complete
                            final List<dynamic> comments = (await commentsSnapshotFuture).docs.map((commentDoc) => commentDoc.data()).toList();
                            final DocumentSnapshot likedSnapshot = await likedSnapshotFuture;
                            final Map<String, dynamic> likedData = likedSnapshot.data() as Map<String, dynamic>;
                            // If 'likedData' contains a list of liked users, you can extract it accordingly
                            final List<dynamic> likedUsers = likedData['likedBy'] ?? [];

                            // Close the progress dialog
                            Navigator.pop(context);

                            // Navigate to PostDetailsPage with post details, comments, and liked data
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailsPage(
                                  username: _userData.name.toString(),
                                  text: _userPosts[index].text,
                                  profilePictureUrl: _userData.profile ?? '',
                                  postId: _userPosts[index].id,
                                  comments: comments,
                                  postTime: _userPosts[index].timestamp,
                                  likedData: likedUsers,
                                  userIDs: _userData.uid.toString(),
                                  mediaUrl: _userPosts[index].mediaUrl.toString(),  // Pass the liked data here
                                  fileType: _userPosts[index].fileType.toString(),
                                ),
                              ),
                            );
                          } catch (e) {
                            print("Error fetching data: $e");
                            // Handle the error appropriately
                          }
                        },
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: CircleAvatar(
                                backgroundImage:
                                NetworkImage(_userProfilePictureUrl ?? ''),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                _userData.name.toString(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .tertiary,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                _formatDate(
                                                    _userPosts[index].timestamp),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width *
                                                0.7,
                                            child: Text(
                                              _userPosts[index].text,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .tertiary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  // Display media if available
                                  if (_userPosts[index].mediaUrl != null)
                                    _buildMediaWidget(_userPosts[index]), // Add this line
                                  SizedBox(height: 15,),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              // Your like functionality here
                                            },
                                            child: Icon(
                                              isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isLiked
                                                  ? Colors.red
                                                  : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              size: 20,
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          Visibility(
                                            visible: _userPosts[index]
                                                .likedBy
                                                .isNotEmpty,
                                            child: Text(
                                              '${_userPosts[index].likedBy.length}',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CommentsPage(
                                                username: _userData.name.toString(),
                                                postText: _userPosts[index].text,
                                                profilePictureUrl: _userData.profile ?? '',
                                                postId: _userPosts[index].id, // Pass the postId here
                                              ),
                                            ),
                                          );
                                        },
                                        child: Icon(
                                          CupertinoIcons.chat_bubble_text,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      InkWell(
                                        onTap: () {
                                          // Handle share functionality
                                        },
                                        child: Icon(
                                          Icons.share_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      InkWell(
                                        onTap: () {
                                          // Handle save functionality
                                        },
                                        child: Icon(
                                          Icons.bookmark_border_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Icon(Icons.more_vert,
                                  color: Colors.black26, size: 17),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaWidget(PostModel post) {
    if (post.fileType == 'image') {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            post.mediaUrl!,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (post.fileType == 'video') {
      // For video, you can use the video_player package
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: VideoPlayWidget(videoUrl: post.mediaUrl!),
      );
    } else if (post.fileType == 'audio') {
      // Check if the filetype is 'audio'
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AudioPlayerWidget(audioFile: File(post.mediaUrl!)),
      );
    }
    return SizedBox.shrink(); // Return an empty widget if media type is not supported
  }



  Widget _buildRepliesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comments')
          .where('userId', isEqualTo: _user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No replied posts'));
        } else {
          List<String> postIds = snapshot.data!.docs
              .map((commentDoc) => commentDoc['postId'] as String)
              .toList();

          return ListView.builder(
            padding: EdgeInsets.all(10.0),
            itemCount: postIds.length,
            itemBuilder: (context, index) {
              String postId = postIds[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .get(),
                builder: (context, postSnapshot) {
                  if (postSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (postSnapshot.hasError) {
                    return Center(child: Text('Error: ${postSnapshot.error}'));
                  } else if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
                    return SizedBox.shrink();
                  } else {
                    Map<String, dynamic>? postData = postSnapshot.data!.data() as Map<String, dynamic>?;
                    if (postData == null) {
                      return SizedBox.shrink();
                    }

                    PostModel post = PostModel.fromMap(postData);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(post.userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (userSnapshot.hasError) {
                          return Center(child: Text('Error: ${userSnapshot.error}'));
                        } else if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                          return ListTile(
                            title: Text('Unknown User: ${post.text}'),
                            subtitle: Text(post.timestamp.toString()),
                          );
                        } else {
                          Map<String, dynamic>? userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                          if (userData == null) {
                            return ListTile(
                              title: Text('Unknown User: ${post.text}'),
                              subtitle: Text(post.timestamp.toString()),
                            );
                          }

                          UserModel user = UserModel.fromMap(userData);

                          return ListTile(
                            onTap: () async {
                              showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (BuildContext context) {
                                  return Center(child: CircularProgressIndicator());
                                },
                              );

                              try {
                                final commentsSnapshotFuture = FirebaseFirestore.instance
                                    .collection('comments')
                                    .where('postId', isEqualTo: post.id)
                                    .get();
                                final likedSnapshotFuture = FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(post.id)
                                    .get();

                                final List<dynamic> comments = (await commentsSnapshotFuture).docs.map((commentDoc) => commentDoc.data()).toList();
                                final DocumentSnapshot likedSnapshot = await likedSnapshotFuture;
                                final Map<String, dynamic> likedData = likedSnapshot.data() as Map<String, dynamic>;
                                final List<dynamic> likedUsers = likedData['likedBy'] ?? [];

                                Navigator.pop(context);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailsPage(
                                      username: user.name.toString(),
                                      text: post.text,
                                      profilePictureUrl: user.profile ?? '',
                                      postId: post.id,
                                      comments: comments,
                                      postTime: post.timestamp,
                                      likedData: likedUsers,
                                      userIDs: user.uid.toString(),
                                      mediaUrl: post.mediaUrl ?? '',
                                      fileType: post.fileType ?? '',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                print("Error fetching data: $e");
                              }
                            },
                            title: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(user.profile ?? ''),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name.toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.tertiary,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            _formatDate(post.timestamp),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        post.text,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context).colorScheme.tertiary,
                                        ),
                                      ),
                                      if (post.mediaUrl != null) _buildMediaWidget(post),
                                      SizedBox(height: 15),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () async {
                                                  // Your like functionality here
                                                },
                                                child: Icon(
                                                  post.likedBy.contains(FirebaseAuth.instance.currentUser?.uid)
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: post.likedBy.contains(FirebaseAuth.instance.currentUser?.uid)
                                                      ? Colors.red
                                                      : Theme.of(context).colorScheme.secondary,
                                                  size: 20,
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              if (post.likedBy.isNotEmpty)
                                                Text(
                                                  '${post.likedBy.length}',
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.secondary,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => CommentsPage(
                                                    username: user.name.toString(),
                                                    postText: post.text,
                                                    profilePictureUrl: user.profile ?? '',
                                                    postId: post.id,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Icon(
                                              CupertinoIcons.chat_bubble_text,
                                              size: 20,
                                              color: Theme.of(context).colorScheme.secondary,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              // Handle share functionality
                                            },
                                            child: Icon(
                                              Icons.share_outlined,
                                              size: 20,
                                              color: Theme.of(context).colorScheme.secondary,
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              // Handle save functionality
                                            },
                                            child: Icon(
                                              Icons.bookmark_border_outlined,
                                              size: 20,
                                              color: Theme.of(context).colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }


  Widget _buildRepostedTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getRepostedPosts(), // Fetch shared posts
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No reposts found.'));
        }

        List<Map<String, dynamic>> repostedPosts = snapshot.data!;

        return ListView.builder(
          itemCount: repostedPosts.length,
          itemBuilder: (context, index) {
            var postData = repostedPosts[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(postData['profile'] ?? ''),
                          radius: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                postData['name'] ?? 'Unknown User',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                DateFormat('yMMMd').format((postData['timestamp'] as Timestamp).toDate()),
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      postData['text'] ?? 'No content available',
                      style: TextStyle(fontSize: 16),
                    ),
                    if (postData['mediaUrl'] != null && postData['mediaUrl'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Image.network(
                          postData['mediaUrl'],
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }




  Widget _buildSavedTab() {
    return Center(
      child: Text('Saved Tab'),
    );
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    String formattedDate = DateFormat('dd MMM').format(date);
    return formattedDate;
  }
}

class MySliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  MySliverPersistentHeaderDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
