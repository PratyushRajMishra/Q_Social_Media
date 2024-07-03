import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:q/screens/postDetails.dart';
import 'package:q/screens/settings/edit_profile.dart';
import 'package:url_launcher/url_launcher.dart';
import '../followersList.dart';
import '../followingList.dart';
import '../models/postModel.dart';
import '../models/userModel.dart';
import '../widgets/audioPlayerWidget.dart';
import '../widgets/videoPlayerWidget.dart';
import 'UserProfile.dart';
import 'comments.dart';

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
  late List<PostModel> _userPosts;
  late bool _isFollowing;
  late User? currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchUserPosts();
    _userPosts = [];
    currentUser = FirebaseAuth.instance.currentUser;
    checkIfFollowing();
  }

  Future<void> checkIfFollowing() async {
    if (currentUser != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      List<dynamic> following = doc['following'];
      setState(() {
        _isFollowing = following.contains(widget.userId);
      });
    }
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

  Future<void> _fetchUserPosts() async {
    try {
      QuerySnapshot<Map<String, dynamic>> postSnapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(widget.userId)
          .collection('posts')
          .get();
      setState(() {
        _userPosts = postSnapshot.docs
            .map((doc) => PostModel.fromMap(doc.data()))
            .toList();
      });
      print('Data fetched');
    } catch (e) {
      print('Error fetching user posts: $e');
    }
  }

  void followUser(String userId, bool isFollowing, String? currentUserId) {
    CollectionReference usersRef =
        FirebaseFirestore.instance.collection('users');

    // Add or remove current user from target user's followers list
    if (!isFollowing) {
      // If not following, add to followers list
      usersRef.doc(userId).update({
        'followers': FieldValue.arrayUnion([currentUserId]),
      });
      // Add target user to current user's following list
      usersRef.doc(currentUserId).update({
        'following': FieldValue.arrayUnion([userId]),
      });
      setState(() {
        _isFollowing = true;
      });
    } else {
      // If following, remove from followers list
      usersRef.doc(userId).update({
        'followers': FieldValue.arrayRemove([currentUserId]),
      });
      // Remove target user from current user's following list
      usersRef.doc(currentUserId).update({
        'following': FieldValue.arrayRemove([userId]),
      });
      setState(() {
        _isFollowing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : _userData != null
          ? DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder:
              (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                titleSpacing: 0,
                title: Text(
                  _userData.name ?? 'Loading...',
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
                              left: 15,
                              right: 15,
                              top: 75,
                              bottom: 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 15),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left: 15),
                                            child: Row(
                                              children: [
                                                Column(
                                                  children: [
                                                    Text(
                                                      _userPosts.length.toString(),
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      'Posts',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Theme.of(context).colorScheme.tertiary,
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
                                                        builder: (context) => FollowersListPage(
                                                          userId: _userData.uid.toString(),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        _userData.followers!.length.toString(),
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        "Followers",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Theme.of(context).colorScheme.tertiary,
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
                                                        builder: (context) => FollowingListPage(
                                                          userId: _userData.uid.toString(),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        _userData.following!.length.toString(),
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        'Following',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Theme.of(context).colorScheme.tertiary,
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
                                            padding: const EdgeInsets.only(left: 3),
                                            child: Text(
                                              _userData?.email ?? _userData.phoneNumber ?? '',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 15,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                              SizedBox(width: 2),
                                              Text(
                                                _userData.location.toString(),
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.secondary,
                                                  fontSize: 16,
                                                ),
                                              ),
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
                                        imageUrl: _userProfilePictureUrl.toString(),
                                        imageBuilder: (context, imageProvider) => CircleAvatar(
                                          backgroundImage: imageProvider,
                                          radius: 50,
                                        ),
                                        placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) => Icon(Icons.error),
                                      )
                                          : (_userProfilePictureUrl == 'DEFAULT_IMAGE_URL' || _userProfilePictureUrl!.isEmpty)
                                          ? Icon(
                                        Icons.account_circle,
                                        size: 100,
                                        color: Theme.of(context).colorScheme.tertiary,
                                      )
                                          : CircleAvatar(
                                        backgroundImage: NetworkImage(_userProfilePictureUrl.toString()),
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
                                    launchUrl(Uri.parse(_userData.website.toString()), mode: LaunchMode.inAppBrowserView);
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.link_outlined,
                                        color: Theme.of(context).colorScheme.secondary,
                                        size: 16,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        _userData.website.toString(),
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 16,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  _userData.bio.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                SizedBox(height: 20),
                                SizedBox(
                                  height: 30,
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      followUser(widget.userId, _isFollowing, currentUser?.uid);
                                    },
                                    child: Text(
                                      _isFollowing ? 'Unfollow' : 'Follow',
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
                    unselectedLabelColor: Theme.of(context).colorScheme.secondary,
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
              _buildPostsTab(), // Implement _buildPostsTab(), _buildRepliesTab(), _buildSavedTab() methods
              _buildRepliesTab(),
              _buildSavedTab(),
            ],
          ),
        ),
      )
          : Center(
        child: Text('User data not available'),
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
                            final likedSnapshotFuture = FirebaseFirestore.instance.collection('users').doc(_userData.uid).collection('posts').doc(_userPosts[index].id).get();

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
                                backgroundImage: _userProfilePictureUrl != null && _userProfilePictureUrl!.isNotEmpty
                                    ? NetworkImage(_userProfilePictureUrl!)
                                    : null,
                                backgroundColor: Colors.transparent,
                                child: _userProfilePictureUrl == null || _userProfilePictureUrl!.isEmpty
                                    ? Icon(Icons.account_circle, size: 45, color: Theme.of(context).colorScheme.tertiary)
                                    : null,
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
          child: VideoPlayWidget(videoUrl: post.mediaUrl!));
    }
    else if (post.fileType == 'audio') {
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
          .collection('comments') // Query across all comment collections
          .where('userId', isEqualTo: _userData!.uid) // Filter comments by current user
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No replied posts'));
        } else {
          // Extract postIds from comments
          List postIds = snapshot.data!.docs.map((commentDoc) {
            return commentDoc['postId'];
          }).toList();

          return Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemCount: postIds.length,
              itemBuilder: (context, index) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_userData.uid)
                      .collection('posts')
                      .doc(postIds[index])
                      .get(),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (!postSnapshot.hasData ||
                        !postSnapshot.data!.exists) {
                      return SizedBox.shrink(); // Post not found or deleted
                    } else {
                      // Post exists, build ListTile
                      PostModel post = PostModel.fromMap(postSnapshot.data!.data()! as Map<String, dynamic>);
                      return Column(
                        children: [
                          ListTile(
                            title: Text(post.text),
                            subtitle: Text(post.timestamp.toString()),
                            // You can add more details if needed
                          ),
                          Divider(),
                        ],
                      );
                    }
                  },
                );
              },
            ),
          );
        }
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
