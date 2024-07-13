import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:q/Messages/userMessageProfile.dart';

import '../models/messageModel.dart';
import '../widgets/messageVideoPlayWidget.dart';
import '../widgets/videoPlayerWidget.dart';

class UserMessagePage extends StatefulWidget {
  final String userId;
  final String userName;

  const UserMessagePage({super.key, required this.userId, required this.userName});

  @override
  State<UserMessagePage> createState() => _UserMessagePageState();
}

class _UserMessagePageState extends State<UserMessagePage> {
  Future<DocumentSnapshot> _getUserData() async {
    return await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
  }

  TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _selectedImage;
  File? _selectedVideo;
  ValueNotifier<bool> _isSendButtonVisible = ValueNotifier(false);

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
                                borderRadius: BorderRadius.all(Radius.circular(10))
                            ),
                            child: Icon(IconlyBold.camera, size: 30, color: Colors.blueAccent,)),
                        SizedBox(height: 7,),
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
                                borderRadius: BorderRadius.all(Radius.circular(10))
                            ),
                            child: Icon(IconlyBold.image, size: 30, color: Colors.redAccent,)),
                        SizedBox(height: 7,),
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
                                borderRadius: BorderRadius.all(Radius.circular(10))
                            ),
                            child: Icon(IconlyBold.video, size: 30, color: Colors.lightGreen,)),
                        SizedBox(height: 7,),
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
      await _firestore.collection('messages').doc(message.id).set(message.toMap());
    } catch (error) {
      print('Failed to send message: $error');
    }
  }



  Future<String> _uploadMedia(File mediaFile, MediaType mediaType) async {
    String fileName = '${DateTime.now().millisecondsSinceEpoch}';
    String path = mediaType == MediaType.video ? 'videos/$fileName' : 'images/$fileName';

    // Upload file to Firebase Storage
    UploadTask uploadTask = FirebaseStorage.instance.ref().child(path).putFile(mediaFile);

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
        _selectedVideo = null; // Ensure no video is selected when an image is picked
        _isSendButtonVisible.value = true; // Show send button when image is selected
      });
    }
  }

  void _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _selectedVideo = null; // Ensure no video is selected when an image is picked
        _isSendButtonVisible.value = true; // Show send button when image is selected
      });
    }
  }

  void _selectVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedVideo = File(pickedFile.path);
        _selectedImage = null; // Ensure no image is selected when a video is picked
        _isSendButtonVisible.value = true; // Show send button when video is selected
      });
    }
  }




  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      _isSendButtonVisible.value = _messageController.text.isNotEmpty;
    });
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
      backgroundColor: Theme.of(context).colorScheme.background,
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
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.0,
                ),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text(
                'User not found',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              );
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            var profileUrl = userData['profile'] ?? 'https://via.placeholder.com/150';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserMessageProfilePage(
                      userId: widget.userId, // Make sure this is set correctly
                      profileUrl: profileUrl, currentUserId: FirebaseAuth.instance.currentUser!.uid.toString(),
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
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
              stream: _firestore.collection('messages')
                  .where('participants', arrayContainsAny: [FirebaseAuth.instance.currentUser?.uid, widget.userId])
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
                  return Center(child: Text('No messages found.'));
                }

                var messages = snapshot.data!.docs.map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>)).toList();
                var filteredMessages = messages.where((message) {
                  return (message.senderId == FirebaseAuth.instance.currentUser?.uid && message.receiverId == widget.userId) ||
                      (message.senderId == widget.userId && message.receiverId == FirebaseAuth.instance.currentUser?.uid);
                }).toList();

                if (filteredMessages.isEmpty) {
                  return Center(child: Text('Say, Hi😊.', style: TextStyle(fontSize: 15, color: Colors.black38, fontWeight: FontWeight.w300),));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) {
                    var message = filteredMessages[index];
                    bool isSender = message.senderId == FirebaseAuth.instance.currentUser?.uid;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isSender) Spacer(),
                              if (!isSender) SizedBox(width: 0),
                              IntrinsicWidth(
                                child: message.mediaType == MediaType.text
                                    ? Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSender ? Colors.blue : Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                                  textAlign: isSender ? TextAlign.end : TextAlign.start,
                                ),
                                    )
                                    : message.mediaType == MediaType.image
                                    ?
                                SizedBox(
                                  width: 200, // Adjust width as per your requirement
                                  height: 325, // Adjust height as per your requirement
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20), // Adjust the radius as per your requirement
                                    child: Image.network(
                                      message.mediaUrl ?? '',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                                    : SizedBox(
                                  width: 200, // Adjust width as per your requirement
                                  height: 350, // Adjust height as per your requirement
                                  child: VideoPlayWidget(videoUrl: message.mediaUrl ?? ''),
                                ),
                              ),
                              if (!isSender) Spacer(),
                              if (isSender) SizedBox(width: 0),
                            ],
                          ),

                          SizedBox(height: 5),
                          Text(
                            _formatTimestamp(message.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            textAlign: isSender ? TextAlign.end : TextAlign.start,
                          ),
                        ],
                      ),
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
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(onPressed: _selectMedia, icon: Icon(CupertinoIcons.link)),
                        ],
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 5,),
                ValueListenableBuilder<bool>(
                  valueListenable: _isSendButtonVisible,
                  builder: (context, isVisible, child) {
                    return isVisible || _selectedImage != null || _selectedVideo != null
                        ? Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.onTertiary, size: 25,),
                        onPressed: () async {
                          if (_selectedImage != null) {
                            String mediaUrl = await _uploadMedia(_selectedImage!, MediaType.image);
                            _sendMessage(mediaUrl: mediaUrl, mediaType: MediaType.image);
                          } else if (_selectedVideo != null) {
                            String mediaUrl = await _uploadMedia(_selectedVideo!, MediaType.video);
                            _sendMessage(mediaUrl: mediaUrl, mediaType: MediaType.video);
                          } else {
                            _sendMessage(text: _messageController.text);
                          }
                        },
                      ),
                    )
                        : Container(); // Empty container if not visible
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
  return DateFormat('hh:mm a').format(dateTime);  // Format time as hh:mm AM/PM
}
