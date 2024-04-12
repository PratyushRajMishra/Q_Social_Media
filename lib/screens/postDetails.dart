import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/audioPlayerWidget.dart';
import '../widgets/imageTextWidget.dart';
import '../widgets/videoPlayerWidget.dart';
import 'comments.dart';

class PostDetailsPage extends StatefulWidget {
  final String username;
  final String text;
  final String profilePictureUrl;
  final String postId;
  final List<dynamic> comments;
  final Timestamp postTime;
  final List<dynamic> likedData;
  final String userIDs;
  final String mediaUrl;
  final String fileType;

  const PostDetailsPage({
    Key? key,
    required this.username,
    required this.text,
    required this.profilePictureUrl,
    required this.postId,
    required this.comments,
    required this.postTime,
    required this.likedData,
    required this.userIDs,
    required this.mediaUrl,
    required this.fileType,
  }) : super(key: key);

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  late bool isLiked;
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    isLiked = widget.likedData.contains(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Post',
          style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(widget.profilePictureUrl),
            ),
            title: Text(
              widget.username,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            subtitle: Text(
              _formatDateTime(widget.postTime),
            ),
            trailing: Icon(Icons.more_vert, color: Colors.black26, size: 20),
          ),


          if (widget.text != null)
            Padding(
              padding: EdgeInsets.only(left: 18, top: 0, bottom: 10),
              child: Text(
                widget.text, // Use postText if not null
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),


          if (widget.mediaUrl != null && widget.fileType == 'audio')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: AudioPlayerWidget(audioFile: File(widget.mediaUrl!)),
            ),

          // Check if mediaUrl is provided and fileType is 'video'
          if (widget.mediaUrl != null && widget.fileType == 'video')
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: VideoPlayWidget(videoUrl: widget.mediaUrl!),
              ),
            ),

          // Check if mediaUrl is provided and fileType is 'image'
          if (widget.mediaUrl != null && widget.fileType == 'image')
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ImageOrText(mediaUrl: widget.mediaUrl!, postText: widget.text),
                ),
              ),
            ),

          // if (widget.mediaUrl != null) // Show media section only if mediaUrl is provided
          //   widget.mediaUrl!.contains('.mp4')
          //       ? Center(
          //         child: Container(
          //     constraints: BoxConstraints(
          //         maxHeight: MediaQuery.of(context).size.height * 0.5,
          //         maxWidth: MediaQuery.of(context).size.width * 0.7,
          //     ),
          //     child: VideoPlayWidget(videoUrl: widget.mediaUrl!),
          //   ),
          //       )
          //       : ImageOrText(mediaUrl: widget.mediaUrl!, postText: widget.postText),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Likes icon and count
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        try {
                          setState(() {
                            isLiked = !isLiked;
                          });
                          await toggleLikeStatus(widget.postId, widget.userIDs);
                        } catch (e) {
                          print("Error toggling like status: $e");
                        }
                      },
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Theme.of(context).colorScheme.secondary,
                        size: 23,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      widget.likedData.length.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10),
                // Comments icon and count
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentsPage(
                              username: widget.username,
                              postText: widget.text,
                              profilePictureUrl: widget.profilePictureUrl,
                              postId: widget.postId,
                            ),
                          ),
                        );
                      },
                      child: Icon(
                        CupertinoIcons.chat_bubble_text,
                        size: 23,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      '${widget.comments.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10),
                // Share icon
                Icon(Icons.share_outlined, size: 23, color: Theme.of(context).colorScheme.secondary),
                SizedBox(width: 10),
                // Bookmark icon
                Icon(Icons.bookmark_border_outlined, size: 23, color: Theme.of(context).colorScheme.secondary),
              ],
            ),
          ),
          Divider(),
          // Comments section
          Column(
            children: widget.comments.map<Widget>((comment) {
              return Column(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(comment['userId']).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text('User not found');
                      }

                      String profilePictureUrl = snapshot.data!.get('profile') ?? '';
                      String username = snapshot.data!.get('name') ?? ''; // Adding null check for username
                      return ListTile(
                        title: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: CircleAvatar(
                                backgroundImage: profilePictureUrl.isNotEmpty
                                    ? NetworkImage(profilePictureUrl)
                                    : Icon(Icons.account_circle) as ImageProvider,
                              ),
                            ),
                            SizedBox(width: 10,),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(username,  style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.tertiary,
                                          ),),
                                          SizedBox(width: 8),
                                          Text(
                                            _formatDateTime(comment['timestamp']),
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.secondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Icon(Icons.more_vert, color: Colors.black26, size: 17),
                                    ],
                                  ),
                                  SizedBox(height: 5,),
                                  Text(comment['text'],style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.tertiary,
                                  ),),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Divider(),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    String formattedDateTime = DateFormat('MMM d, HH:mm').format(dateTime);
    return formattedDateTime;
  }

  Future<void> toggleLikeStatus(String postId, String userIDs) async {
    try {
      // Get the document reference for the post
      DocumentReference postRef = FirebaseFirestore.instance.collection('users').doc(userIDs).collection('posts').doc(widget.postId);

      // Get the current document snapshot
      DocumentSnapshot postSnapshot = await postRef.get();

      if (postSnapshot.exists) {
        // Cast the data to a map of type Map<String, dynamic>
        Map<String, dynamic>? postData = postSnapshot.data() as Map<String, dynamic>?;

        // Check if postData is not null
        if (postData != null) {
          // Get the current likedBy list from the document
          List<dynamic>? likedBy = postData['likedBy'];

          if (likedBy != null && likedBy.contains(userId)) {
            // If the user already liked the post, remove their ID from the likedBy list
            await postRef.update({
              'likedBy': FieldValue.arrayRemove([userId]),
            });
          } else {
            // If the user has not liked the post, add their ID to the likedBy list
            await postRef.update({
              'likedBy': FieldValue.arrayUnion([userId]),
            });
          }

          // Update the UI after Firestore update is completed
          setState(() {});
        } else {
          print('Post data is null');
        }
      } else {
        print('Post does not exist');
      }
    } catch (e) {
      print("Error toggling like status: $e");
    }
  }
}
