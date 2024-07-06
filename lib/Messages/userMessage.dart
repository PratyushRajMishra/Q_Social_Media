import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  File? _selectedImage;

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



  void _sendMessage() {
    String messageText = _messageController.text.trim();
    // Implement your logic to send the message
    if (messageText.isNotEmpty) {
      print('Sending message: $messageText');
      // Clear the text field after sending message
      _messageController.clear();
    }
  }

  void _selectCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _selectVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path); // Assuming you're storing video in `_selectedImage` as per your usage
      });
    }
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

            return Row(
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
            );
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Placeholder for incoming and outgoing messages
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Incoming message example',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Outgoing message example',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                  _selectedImage != null
                      ? Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                      : SizedBox.shrink(),
                ],
              ),
            ),
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
                Container(
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(50)
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.onTertiary, size: 25,),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
