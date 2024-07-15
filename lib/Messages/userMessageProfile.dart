import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:video_player/video_player.dart';
import 'package:q/screens/target_profile.dart'; // Ensure this is your correct import path

class UserMessageProfilePage extends StatefulWidget {
  final String userId;
  final String profileUrl;
  final String currentUserId;

  const UserMessageProfilePage({
    required this.userId,
    required this.profileUrl,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  _UserMessageProfilePageState createState() => _UserMessageProfilePageState();
}

class _UserMessageProfilePageState extends State<UserMessageProfilePage> {
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _checkIfBlocked();
  }

  Future<void> _checkIfBlocked() async {
    try {
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).get();

      // Safely cast the data to Map<String, dynamic>?
      Map<String, dynamic>? userData = currentUserDoc.data() as Map<String, dynamic>?;

      // If the userData is not null, get the blockedUsers list
      List<dynamic> blockedUsers = userData?['blockedUsers'] ?? [];

      setState(() {
        _isBlocked = blockedUsers.contains(widget.userId);
      });
    } catch (e) {
      print('Error checking if user is blocked: $e');
    }
  }

  Future<void> _blockUser() async {
    try {
      // Fetch the username of the user being blocked
      DocumentSnapshot userToBlockDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      Map<String, dynamic>? userToBlockData = userToBlockDoc.data() as Map<String, dynamic>?;
      String blockedUsername = userToBlockData?['name'] ?? 'User';

      // Show confirmation dialog
      bool? confirmBlock = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Block $blockedUsername?'),
          content: Text('Are you sure you want to block this user? They will no longer be able to send you messages.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Block'),
            ),
          ],
        ),
      );

      if (confirmBlock == true) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.onTertiary,
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Blocking $blockedUsername...',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        );

        // Update the user's blocked list
        await FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).update({
          'blockedUsers': FieldValue.arrayUnion([widget.userId]),
        });

        // Update the blocked user's blockedBy list
        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
          'blockedBy': FieldValue.arrayUnion([widget.currentUserId]),
        });

        // Update state and dismiss dialogs
        setState(() {
          _isBlocked = true;
        });

        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$blockedUsername has been blocked.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error blocking user: $e');

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error blocking user.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }



  Future<void> _unblockUser() async {
    String unblockedUsername;

    try {
      // Fetch the username of the user being unblocked
      DocumentSnapshot userToUnblockDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      Map<String, dynamic>? userToUnblockData = userToUnblockDoc.data() as Map<String, dynamic>?;
      unblockedUsername = userToUnblockData?['name'] ?? 'User';
    } catch (e) {
      // Handle error fetching username
      print('Error fetching unblocked user data: $e');
      unblockedUsername = 'User';
    }

    // Show the dialog with a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.onTertiary,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'Unblocking $unblockedUsername...',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Remove the user from the blocked list of the current user
      await FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).update({
        'blockedUsers': FieldValue.arrayRemove([widget.userId]),
      });

      // Optionally, remove the current user from the blocked list of the user being unblocked
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'blockedBy': FieldValue.arrayRemove([widget.currentUserId]),
      });

      // Update the state to reflect the unblock action
      setState(() {
        _isBlocked = false;
      });

      // Dismiss the dialog
      Navigator.of(context).pop();

      // Show the SnackBar with the username
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$unblockedUsername has been unblocked.'),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Close',
            onPressed: () {
              // Optionally handle any action here if needed
            },
          ),
        ),
      );
    } catch (e) {
      print('Error unblocking user: $e');

      // Dismiss the dialog
      Navigator.of(context).pop();

      // Show error SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unblocking user.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  void _deleteConversation(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Show confirmation dialog
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
      builder: (context) => AlertDialog(
        title: Text('Delete Conversation'),
        content: Text('Are you sure you want to delete the conversation with this user?',),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Return false to indicate cancellation
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Return true to indicate confirmation
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        // Perform the deletion
        final messagesSnapshot = await FirebaseFirestore.instance
            .collection('messages')
            .where('participants', arrayContains: currentUserId)
            .get();

        for (var doc in messagesSnapshot.docs) {
          final participants = List<String>.from(doc['participants']);
          if (participants.contains(userId)) {
            await doc.reference.delete();
          }
        }

        // Show success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversation deleted.'),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Close',
              onPressed: () {
                // Optionally handle any action here if needed
              },
            ),
          ),
        );
      } catch (e) {
        print('Error deleting conversation: $e');
        // Optionally show an error SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting conversation.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('User not found'));
          }

          String name = snapshot.data!['name'] ?? 'No username';
          String bio = snapshot.data!['bio'] ?? 'No bio available';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 25, bottom: 15),
                child: IconButton(
                  icon: Icon(Icons.close_rounded, size: 30),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(widget.profileUrl),
                    ),
                    SizedBox(height: 20),
                    Text(
                      name,
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                    SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                    SizedBox(height: 30),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => TargetProfilePage(userId: widget.userId),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(Icons.person),
                              ),
                              SizedBox(height: 8),
                              Text('Profile'),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(Icons.notifications),
                            ),
                            SizedBox(height: 8),
                            Text('Mute'),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_isBlocked) {
                              _unblockUser();
                            } else {
                              _blockUser();
                            }
                          },
                          child: Column(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  _isBlocked ? CupertinoIcons.nosign : Icons.block,
                                  // color: _isBlocked ? Colors.green : null,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(_isBlocked ? 'Unblock' : 'Block'),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _deleteConversation(widget.userId);
                          },
                          child: Column(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(Icons.delete, color: Colors.redAccent),
                              ),
                              SizedBox(height: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getMediaMessages(widget.currentUserId, widget.userId),
                      builder: (context, mediaSnapshot) {
                        if (mediaSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (mediaSnapshot.hasError) {
                          return Center(child: Text('Error: ${mediaSnapshot.error}'));
                        }

                        if (!mediaSnapshot.hasData || mediaSnapshot.data!.isEmpty) {
                          return Center(child: Text('No media found'));
                        }

                        List<Map<String, dynamic>> mediaMessages = mediaSnapshot.data!;

                        return GridView.builder(
                          shrinkWrap: true,
                          itemCount: mediaMessages.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemBuilder: (context, index) {
                            var mediaMessage = mediaMessages[index];
                            var mediaUrl = mediaMessage['mediaUrl'];
                            var mediaType = mediaMessage['mediaType'];

                            if (mediaType == 2) {
                              return VideoThumbnailWidget(url: mediaUrl);
                            } else {
                              return Image.network(
                                mediaUrl,
                                fit: BoxFit.cover,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userSnapshot.exists) {
      Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
      return userData;
    } else {
      throw Exception('User not found');
    }
  }

  Future<List<Map<String, dynamic>>> _getMediaMessages(String currentUserId, String otherUserId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('participants', arrayContains: currentUserId)
        .get();

    List<Map<String, dynamic>> mediaMessages = [];

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List participants = data['participants'];
      if (participants.contains(otherUserId) && data['mediaUrl'] != null) {
        mediaMessages.add(data);
      }
    }

    return mediaMessages;
  }
}

class VideoThumbnailWidget extends StatefulWidget {
  final String url;

  const VideoThumbnailWidget({Key? key, required this.url}) : super(key: key);

  @override
  _VideoThumbnailWidgetState createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: 16/9,
          child: VideoPlayer(_controller),
        ),
        if (!_isPlaying)
          Icon(IconlyBold.play, size: 24, color: Colors.white),
      ],
    );
  }
}
