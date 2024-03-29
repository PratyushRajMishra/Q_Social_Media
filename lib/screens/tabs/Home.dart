import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q/screens/UserProfile.dart';
import 'package:shimmer/shimmer.dart';

import '../Setting.dart';
import '../target_profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfilePage()));
          },
          child: Padding(
            padding: const EdgeInsets.all(13.0),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(_user?.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Icon(Icons.error);
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Icon(Icons.account_circle, size: 30, color: Theme.of(context).colorScheme.tertiary);
                }

                Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;

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
        title: Builder(
          builder: (BuildContext context) {
            return Image.asset(
              Theme.of(context).brightness == Brightness.light ? 'assets/logo_dark.png' : 'assets/logo_light.png',
              height: 40,
              width: 40,
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingPage()));
            },
            icon: const Icon(
              Icons.settings_outlined,
              size: 23,
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Center(child: Icon(Icons.error));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No posts available'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot userDoc = snapshot.data!.docs[index];
              String userId = userDoc.id;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('posts').snapshots(),
                builder: (context, postSnapshot) {
                  if (postSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (postSnapshot.hasError) {
                    return Icon(Icons.error);
                  }

                  if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
                    return ListTile(
                      title: Text('No posts available'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: postSnapshot.data!.docs.length,
                    itemBuilder: (context, postIndex) {
                      DocumentSnapshot postDoc = postSnapshot.data!.docs[postIndex];
                      Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
                      bool isLiked = postData['likedBy'].contains(FirebaseAuth.instance.currentUser?.uid);

                      return Column(
                        children: [
                          ListTile(
                            title: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    String clickedUserId = userDoc.id;
                                    String currentUserId = _user?.uid ?? '';

                                    if (clickedUserId == currentUserId) {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfilePage()));
                                    } else {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => TargetProfilePage(userId: clickedUserId)));
                                    }
                                  },
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(userDoc['profile'] ?? ''),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '${userDoc['name']}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).colorScheme.tertiary,
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    DateFormat('dd MMM').format(postData['timestamp'].toDate()),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context).colorScheme.secondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Container(
                                                width: MediaQuery.of(context).size.width * 0.7,
                                                child: Text(
                                                  postData['text'],
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Theme.of(context).colorScheme.tertiary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () async {
                                                  if (isLiked) {
                                                    await FirebaseFirestore.instance.collection('users').doc(userId).collection('posts').doc(postDoc.id).update({
                                                      'likedBy': FieldValue.arrayRemove([FirebaseAuth.instance.currentUser?.uid]),
                                                    });
                                                  } else {
                                                    await FirebaseFirestore.instance.collection('users').doc(userId).collection('posts').doc(postDoc.id).update({
                                                      'likedBy': FieldValue.arrayUnion([FirebaseAuth.instance.currentUser?.uid]),
                                                    });
                                                  }
                                                  setState(() {});
                                                },
                                                child: Icon(
                                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                                  color: isLiked ? Colors.red : Theme.of(context).colorScheme.secondary,
                                                  size: 20,
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Visibility(
                                                visible: postData['likedBy'].isNotEmpty,
                                                child: Text(
                                                  '${postData['likedBy'].length}',
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.secondary,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: 10),
                                          Icon(CupertinoIcons.chat_bubble_text, size: 20, color: Theme.of(context).colorScheme.secondary),
                                          SizedBox(width: 10),
                                          Icon(Icons.share_outlined, size: 20, color: Theme.of(context).colorScheme.secondary),
                                          SizedBox(width: 10),
                                          Icon(Icons.bookmark_border_outlined, size: 20, color: Theme.of(context).colorScheme.secondary),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Icon(Icons.more_vert, color: Colors.black26, size: 17),
                                ),
                              ],
                            ),
                          ),
                          Divider(),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
