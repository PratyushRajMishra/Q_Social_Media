import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
                                                    Icon(Icons.share_outlined,
                                                        size: 20,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary),
                                                    SizedBox(width: 10),
                                                    Icon(
                                                        Icons
                                                            .bookmark_border_outlined,
                                                        size: 20,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: Icon(Icons.more_vert,
                                                color: Colors.black26,
                                                size: 17),
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
}
