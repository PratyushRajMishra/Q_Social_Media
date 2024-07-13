import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:video_player/video_player.dart';

class UserMessageProfilePage extends StatelessWidget {
  final String userId;
  final String profileUrl;
  final String currentUserId; // Add current user ID

  const UserMessageProfilePage({
    required this.userId,
    required this.profileUrl,
    required this.currentUserId, // Add current user ID
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(userId),
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
                      backgroundImage: NetworkImage(profileUrl),
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
                        Column(
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
                        Column(
                          children: [
                            Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(Icons.block),
                            ),
                            SizedBox(height: 8),
                            Text('Block'),
                          ],
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
                              child: Icon(Icons.delete, color: Colors.redAccent),
                            ),
                            SizedBox(height: 8),
                            Text('Delete'),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getMediaMessages(currentUserId, userId), // Pass currentUserId and userId
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
          aspectRatio: 16/16,
          child: VideoPlayer(_controller),
        ),
        if (!_isPlaying)
         Icon(IconlyBold.play, size: 24, color: Colors.white),
      ],
    );
  }
}
