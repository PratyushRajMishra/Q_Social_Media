import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:q/Messages/userMessageProfile.dart';

import '../models/messageModel.dart';
import '../screens/postDetails.dart';
import '../widgets/fullScreenImageWidget.dart';
import '../widgets/messageVideoPlayWidget.dart';
import '../widgets/videoPlayerWidget.dart';

class UserMessagePage extends StatefulWidget {
  final String userId;
  final String userName;
  final Map<String, dynamic> postData; // Accept post data

  const UserMessagePage({
    Key? key,
    required this.userId,
    required this.userName,
    required this.postData,
  }) : super(key: key);

  @override
  State<UserMessagePage> createState() => _UserMessagePageState();
}

class _UserMessagePageState extends State<UserMessagePage> {
  Future<DocumentSnapshot> _getUserData() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
  }

  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _selectedImage;
  File? _selectedVideo;
  final ValueNotifier<bool> _isSendButtonVisible = ValueNotifier(false);
  bool _isBlocked = false;
  bool _isBlockedBy = false;
  late final String _currentUserId;


  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _messageController.addListener(() {
      _isSendButtonVisible.value = _messageController.text.isNotEmpty;
    });
    _checkIfBlocked();
  }




  void _selectMedia() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: Colors.grey.shade300,
          height: 150,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Media',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: _selectCamera,
                    child: Column(
                      children: [
                        Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onTertiary,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            child: Icon(
                              IconlyBold.camera,
                              size: 30,
                              color: Colors.blueAccent,
                            )),
                        SizedBox(
                          height: 7,
                        ),
                        Text('Camera')
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _selectImage,
                    child: Column(
                      children: [
                        Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onTertiary,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            child: Icon(
                              IconlyBold.image,
                              size: 30,
                              color: Colors.redAccent,
                            )),
                        SizedBox(
                          height: 7,
                        ),
                        Text('Images')
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _selectVideo,
                    child: Column(
                      children: [
                        Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onTertiary,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            child: Icon(
                              IconlyBold.video,
                              size: 30,
                              color: Colors.lightGreen,
                            )),
                        SizedBox(
                          height: 7,
                        ),
                        Text('Videos')
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage({
    String? text,
    String? mediaUrl,
    MediaType mediaType = MediaType.text,
  }) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String senderId = currentUser?.uid ?? '';
    String receiverId = widget.userId;

    if (text == null && mediaUrl == null) {
      return;
    }

    final message = Message(
      id: _firestore.collection('messages').doc().id,
      senderId: senderId,
      receiverId: receiverId,
      participants: [senderId, receiverId],
      text: text,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      timestamp: Timestamp.now(),
    );

    try {
      // Clear message controller and selected media
      _messageController.clear();
      setState(() {
        _selectedImage = null;
        _selectedVideo = null;
        _isSendButtonVisible.value = false; // Hide send button after sending media
      });

      // Save message to Firestore
      await _firestore
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());
    } catch (error) {
      print('Failed to send message: $error');
    }
  }


  Future<String> _uploadMedia(File mediaFile, MediaType mediaType) async {
    String fileName = '${DateTime.now().millisecondsSinceEpoch}';
    String path =
        mediaType == MediaType.video ? 'videos/$fileName' : 'images/$fileName';

    // Upload file to Firebase Storage
    UploadTask uploadTask =
        FirebaseStorage.instance.ref().child(path).putFile(mediaFile);

    // Return a stream of the TaskSnapshot to track upload progress and completion
    return await uploadTask.then((TaskSnapshot snapshot) async {
      // Wait until upload completes to get download URL
      String downloadURL = await snapshot.ref.getDownloadURL();
      return downloadURL;
    }).catchError((error) {
      print('Error uploading file: $error');
      return null;
    });
  }

  void _selectCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _selectedVideo =
            null; // Ensure no video is selected when an image is picked
        _isSendButtonVisible.value =
            true; // Show send button when image is selected
      });
    }
  }

  void _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _selectedVideo =
            null; // Ensure no video is selected when an image is picked
        _isSendButtonVisible.value =
            true; // Show send button when image is selected
      });
    }
  }

  void _selectVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedVideo = File(pickedFile.path);
        _selectedImage =
            null; // Ensure no image is selected when a video is picked
        _isSendButtonVisible.value =
            true; // Show send button when video is selected
      });
    }
  }

  void _deleteMessage(String messageId) async {
    try {
      // Reference to the message document
      DocumentReference messageDoc =
          _firestore.collection('messages').doc(messageId);

      // Delete the message
      await messageDoc.delete();

      // Optionally, show a snackbar or some feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message deleted!')),
      );
    } catch (e) {
      // Handle any errors that occur during deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete message')),
      );
    }
  }

  void _copyMessageText(String messageText) {
    Clipboard.setData(ClipboardData(text: messageText)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message copied to clipboard')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy message')),
      );
    });
  }

  void _onLongPressText(String messageId, String messageText) async {
    showDialog(
      context: context,
      barrierDismissible: true, // Allows closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ListTile(
                title: Text('Delete message for you'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _deleteMessage(messageId); // Call the delete method
                },
              ),
              ListTile(
                title: Text('Report message'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  // Handle report action
                },
              ),
              ListTile(
                title: Text('Copy message text'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _copyMessageText(messageText); // Call the copy method
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteImage(String imageId, String imageUrl) async {
    try {
      // Delete the image document from Firestore
      DocumentReference imageDoc =
      FirebaseFirestore.instance.collection('messages').doc(imageId);
      await imageDoc.delete();
      print('Firestore document deleted');

      // Delete the image file from Firebase Storage
      String imagePath = Uri.parse(imageUrl).path;
      print('Image path: $imagePath'); // Debugging
      Reference storageRef = FirebaseStorage.instance.ref().child(imagePath);
      await storageRef.delete();
      print('Firebase Storage file deleted');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image deleted successfully')),
      );
    } catch (e) {
      print('Error: $e'); // Debugging
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Failed to delete image: $e')),
      // );
    }
  }

  void _onLongPressImage(String imageId, String imageUrl) async {
    showDialog(
      context: context,
      barrierDismissible: true, // Allows closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ListTile(
                title: Text('Delete message for you'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _deleteImage(imageId, imageUrl); // Call the delete method
                },
              ),
              ListTile(
                title: Text('Report this image'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  // Handle report action
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteVideo(String videoId, String mediaUrl) async {
    try {
      // Reference to the document in Firestore
      DocumentReference videoDoc =
      FirebaseFirestore.instance.collection('messages').doc(videoId);

      // Delete the video document from Firestore
      await videoDoc.delete();
      print('Firestore document deleted');


      // Extract the video path from the media URL
      Uri uri = Uri.parse(mediaUrl);
      String videoPath = uri.path; // Extract the path from the URL
      videoPath = videoPath.startsWith('/')
          ? videoPath.substring(1)
          : videoPath; // Clean path if needed
      print('Video path: $videoPath'); // Debugging

      // Reference to the video file in Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref().child(videoPath);

      // Delete the video file from Firebase Storage
      await storageRef.delete();
      print('Firebase Storage file deleted');

      // Notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video deleted successfully')),
      );
    } catch (e) {
      // Handle errors
      print('Error: $e'); // Debugging
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Failed to delete video: $e')),
      // );
    }
  }

  void _onLongPressVideo(String videoId, String mediaUrl) async {
    showDialog(
      context: context,
      barrierDismissible: true, // Allows closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ListTile(
                title: Text('Delete message for you'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _deleteVideo(videoId, mediaUrl); // Call the delete method
                },
              ),
              ListTile(
                title: Text('Report this video'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the dialog
                  // Handle report action
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _checkIfBlocked() async {
    try {
      // Fetch current user's document
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      // Fetch the other user's document
      DocumentSnapshot otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      // Safely cast the data to Map<String, dynamic>
      Map<String, dynamic>? currentUserData = currentUserDoc.data() as Map<String, dynamic>?;
      Map<String, dynamic>? otherUserData = otherUserDoc.data() as Map<String, dynamic>?;

      // Get the blockedUsers and blockedBy lists
      List<dynamic> currentUserBlockedUsers = currentUserData?['blockedBy'] ?? [];
      List<dynamic> otherUserBlockedBy = otherUserData?['blockedUsers'] ?? [];

      List<dynamic> currentUser1BlockedUsers = currentUserData?['blockedUsers'] ?? [];
      List<dynamic> otherUser1BlockedBy = otherUserData?['blockedBy'] ?? [];

      // this show message on other user chats
      bool isBlocked = currentUserBlockedUsers.contains(widget.userId) || otherUserBlockedBy.contains(_currentUserId);


      // this show message on current user chat
      bool isBlockedBY = currentUser1BlockedUsers.contains(widget.userId) || otherUser1BlockedBy.contains(_currentUserId);

      // Update the state
      setState(() {
        _isBlocked = isBlocked;
        _isBlockedBy = isBlockedBY;
      });
    } catch (e) {
      print('Error checking if user is blocked: $e');
    }
  }



  @override
  void dispose() {
    _messageController.dispose();
    _isSendButtonVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 35,
          title: FutureBuilder<DocumentSnapshot>(
            future: _getUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text(
                  'Loading....',
                  style: TextStyle(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.0,
                  ),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Text(
                  'User not found',
                  style: TextStyle(color: Theme
                      .of(context)
                      .colorScheme
                      .primary),
                );
              }

              var userData = snapshot.data!.data() as Map<String, dynamic>;
              var profileUrl =
                  userData['profile'] ?? 'https://via.placeholder.com/150';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserMessageProfilePage(
                            userId: widget.userId,
                            // Make sure this is set correctly
                            profileUrl: profileUrl,
                            currentUserId:
                            FirebaseAuth.instance.currentUser!.uid.toString(),
                          ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(profileUrl),
                    ),
                    SizedBox(width: 10),
                    Text(
                      widget.userName,
                      style:
                      TextStyle(color: Theme
                          .of(context)
                          .colorScheme
                          .primary),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('messages')
                    .where('participants',
                    arrayContains: FirebaseAuth.instance.currentUser?.uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Say, Hi😊.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black38,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    );
                  }

                  var messages = snapshot.data!.docs
                      .map((doc) =>
                      Message.fromMap(doc.data() as Map<String, dynamic>))
                      .toList();

                  var filteredMessages = messages.where((message) {
                    return (message.senderId ==
                        FirebaseAuth.instance.currentUser?.uid &&
                        message.receiverId == widget.userId) ||
                        (message.senderId == widget.userId &&
                            message.receiverId ==
                                FirebaseAuth.instance.currentUser?.uid);
                  }).toList();

                  return ListView.builder(
                    reverse: true,
                    itemCount: filteredMessages.length,
                    itemBuilder: (context, index) {
                      var message = filteredMessages[index];
                      bool isSender = message.senderId == FirebaseAuth.instance.currentUser?.uid;

                      return FutureBuilder<DocumentSnapshot>(
                        future: message.postId != null && message.postId!.isNotEmpty
                            ? FirebaseFirestore.instance.collection('posts').doc(message.postId).get()
                            : null,
                        builder: (context, postSnapshot) {
                          if (postSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          Map<String, dynamic>? postData;
                          if (postSnapshot.hasData && postSnapshot.data != null) {
                            postData = postSnapshot.data!.data() as Map<String, dynamic>;
                          }

                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isSender) Spacer(),
                                    IntrinsicWidth(
                                      child: message.postId != null && postData != null
                                          ? GestureDetector(
                                        onTap: () async {
                                          try {
                                            // Fetch user data from Firestore
                                            final userDoc = await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(postData?['userId']) // Assuming the post includes a 'userId'
                                                .get();

                                            if (userDoc.exists) {
                                              final userData = userDoc.data();

                                              // Fetch comments for the post
                                              final commentsSnapshot = await FirebaseFirestore.instance
                                                  .collection('comments')
                                                  .where('postId', isEqualTo: postData?['id']) // Assuming postId is stored in comments
                                                  .get();

                                              final comments = commentsSnapshot.docs.map((doc) => doc.data()).toList();

                                              // Fetch likes from the post data
                                              final likedData = postData?['likedBy'] ?? []; // Assuming likedData is an array in the post

                                              // Navigate to PostDetailsPage with all required information
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => PostDetailsPage(
                                                    postId: postData?['id'] ?? '', // Post ID
                                                    mediaUrl: postData?['mediaUrl'] ?? '', // Media URL
                                                    text: postData?['text'] ?? '', // Post text
                                                    username: userData?['name'] ?? 'Unknown User', // User name
                                                    profilePictureUrl: userData?['profile'] ?? '', // Profile picture
                                                    comments: comments, // Pass fetched comments
                                                    postTime: postData?['timestamp'] ?? '', // Post time
                                                    likedData: likedData, // Pass fetched likes data
                                                    userIDs: userData?['userId'] ?? '', // User ID
                                                    fileType: postData?['fileType'] ?? '', // File type
                                                  ),
                                                ),
                                              );
                                            } else {
                                              // Handle user data not found
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('User not found')),
                                              );
                                            }
                                          } catch (e) {
                                            // Handle errors
                                            print('Error fetching user data: $e');
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error fetching user details')),
                                            );
                                          }
                                        },


                                        child: Container(
                                          padding: const EdgeInsets.only(top: 0, bottom: 10, left: 10, right: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.grey.shade400, // Border color
                                              width: 1.0, // Border width
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1), // Shadow color
                                                spreadRadius: 0, // How much the shadow spreads
                                                blurRadius: 2, // How soft or sharp the shadow appears
                                                offset: Offset(0, 3), // X and Y offset for the shadow
                                              ),
                                            ],
                                          ),

                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              FutureBuilder<DocumentSnapshot>(
                                                future: postData['userId'] != null
                                                    ? FirebaseFirestore.instance.collection('users').doc(postData['userId']).get()
                                                    : null,
                                                builder: (context, userSnapshot) {
                                                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                                                    return Center(child: CircularProgressIndicator());
                                                  }

                                                  Map<String, dynamic>? userData;
                                                  if (userSnapshot.hasData && userSnapshot.data != null) {
                                                    userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                                  }

                                                  return Padding(
                                                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                                                    child: Row(
                                                      children: [
                                                        if (userData != null && userData['profile'] != null)
                                                          CircleAvatar(
                                                            backgroundImage: NetworkImage(userData['profile']),
                                                            radius: 18,
                                                          )
                                                        else
                                                          CircleAvatar(
                                                            backgroundColor: Colors.grey,
                                                            radius: 18,
                                                            child: Icon(Icons.person, color: Colors.white),
                                                          ),
                                                        SizedBox(width: 8),
                                                        if (userData != null && userData['name'] != null)
                                                          Text(
                                                            userData['name'],
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: isSender ? Theme.of(context).colorScheme.primary : Colors.black,
                                                              fontSize: 15
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                              if (postData['text'] != null && postData['text'].isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.fromLTRB(5, 8, 10, 0),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        postData['text'],
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          color: isSender ? Theme.of(context).colorScheme.primary : Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              SizedBox(height: 8),
                                              if (postData['mediaUrl'] != null && postData['mediaUrl'].isNotEmpty)
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(20),
                                                  child: CachedNetworkImage(
                                                    imageUrl: postData['mediaUrl'],
                                                    fit: BoxFit.cover,
                                                    height: 315,
                                                    width: 250,
                                                    placeholder: (context, url) => Container(
                                                      height: 315,
                                                      width: 250,
                                                      color: Colors.grey.shade200,
                                                      child: Center(
                                                        child: CircularProgressIndicator(),
                                                      ),
                                                    ),
                                                    errorWidget: (context, url, error) => Container(
                                                      height: 315,
                                                      width: 250,
                                                      color: Colors.grey.shade200,
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      )
                                          : message.mediaType == MediaType.text
                                          ? GestureDetector(
                                        onLongPress: () {
                                          _onLongPressText(message.id, message.text.toString());
                                        },
                                        child: Container(
                                          constraints: BoxConstraints(maxWidth: 250),
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isSender
                                                ? Colors.blue
                                                : Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(20),
                                              topLeft: Radius.circular(20),
                                              bottomLeft: Radius.circular(isSender ? 20 : 0),
                                              bottomRight: Radius.circular(isSender ? 0 : 20),
                                            ),
                                          ),
                                          child: Text(
                                            message.text ?? '',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: isSender ? Colors.white : Colors.black,
                                            ),
                                          ),
                                        ),
                                      )
                                          : message.mediaType == MediaType.image
                                          ? GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => FullScreenImage(
                                                imageUrl: message.mediaUrl ?? '',
                                              ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Image.network(
                                            message.mediaUrl ?? '',
                                            fit: BoxFit.cover,
                                            height: 300,
                                            width: 200,
                                          ),
                                        ),
                                      )
                                          : GestureDetector(
                                        onLongPress: () {
                                          _onLongPressVideo(message.id, message.mediaUrl.toString());
                                        },
                                        child: VideoPlayWidget(
                                          videoUrl: message.mediaUrl ?? '',
                                        ),
                                      ),
                                    ),
                                    if (!isSender) Spacer(),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Text(
                                  _formatTimestamp(message.timestamp),
                                  style: TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );

                },
              ),
            ),
            if (_selectedImage != null || _selectedVideo != null)
              Stack(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    height: 100,
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: _selectedImage != null
                          ? DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _selectedVideo != null
                        ? MessageVideoPlayerWidget(videoFile: _selectedVideo!)
                        : null,
                  ),
                  Positioned(
                    right: 13,
                    top: 13,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                          _selectedVideo = null;
                          _isSendButtonVisible.value = false;
                        });
                      },
                      child: Container(
                        height: 20,
                        width: 20,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _isBlocked || _isBlockedBy
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isBlocked
                                ? 'You are blocked.'
                                : 'This user has blocked you.',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "You can't send a message to ${widget.userName}.",
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary),
                          ),
                        ],
                      ),
                    )
                        : TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _selectMedia,
                              icon: Icon(CupertinoIcons.link),
                            ),
                          ],
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  SizedBox(width: 5),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isSendButtonVisible,
                    builder: (context, isVisible, child) {
                      return isVisible ||
                          _selectedImage != null ||
                          _selectedVideo != null
                          ? Container(
                        height: 55,
                        width: 55,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onTertiary,
                            size: 25,
                          ),
                          onPressed: () async {
                            if (_selectedImage != null) {
                              String mediaUrl = await _uploadMedia(
                                  _selectedImage!, MediaType.image);
                              _sendMessage(
                                  mediaUrl: mediaUrl,
                                  mediaType: MediaType.image);
                            } else if (_selectedVideo != null) {
                              String mediaUrl = await _uploadMedia(
                                  _selectedVideo!, MediaType.video);
                              _sendMessage(
                                  mediaUrl: mediaUrl,
                                  mediaType: MediaType.video);
                            } else {
                              _sendMessage(text: _messageController.text);
                            }
                          },
                        ),
                      )
                          : Container();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
  }


        String _formatTimestamp(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  return DateFormat('hh:mm a').format(dateTime); // Format time as hh:mm AM/PM
}




// Row(
//   mainAxisAlignment: MainAxisAlignment.center,
//   crossAxisAlignment: CrossAxisAlignment.end,
//   children: [
//     OutlinedButton(
//       onPressed: () {},
//       style: OutlinedButton.styleFrom(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
//       ),
//       child: Text(
//         'Unblock',
//       ),
//     ),
//     SizedBox(width: 30,),
//     OutlinedButton(
//       onPressed: () {},
//       style: OutlinedButton.styleFrom(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         padding: EdgeInsets.symmetric(horizontal: 35, vertical: 10),
//       ),
//       child: Text(
//         'Delete',
//       ),
//     ),
//   ],
// )