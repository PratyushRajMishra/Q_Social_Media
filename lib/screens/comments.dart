import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentsPage extends StatefulWidget {
  final String username;
  final String postText;
  final String profilePictureUrl;
  final String postId; // Add postId property

  const CommentsPage({
    Key? key,
    required this.username,
    required this.postText,
    required this.profilePictureUrl,
    required this.postId, // Pass postId when creating an instance of CommentsPage
  }) : super(key: key);

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  late TextEditingController _commentTextController;
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _commentTextController = TextEditingController();
    _commentTextController.addListener(() {
      setState(() {
        isButtonEnabled = _commentTextController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _commentTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Reply',
          style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.close,
            size: 28,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            child: ElevatedButton(
              onPressed:
              isButtonEnabled ? () => postComment(currentUser) : null,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.grey; // Change color when disabled
                    }
                    return Colors.blue; // Default color
                  },
                ),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
              ),
              child: Text(
                'Post',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(widget.profilePictureUrl),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 20, right: 5),
                                  child: Container(
                                    height: MediaQuery.of(context).size.height *
                                        (0.1 * (widget.postText.length / 100)), // Adjust height dynamically based on post text length
                                    width: 2,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.username}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.tertiary,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.7,
                                  child: Text(
                                    '${widget.postText}',
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
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser?.uid)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Text('User not found');
                        }

                        Map<String, dynamic> userData =
                        snapshot.data!.data() as Map<String, dynamic>;

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(userData['profile']),
                          ),
                          title: TextField(
                            autofocus: true,
                            controller: _commentTextController,
                            maxLines: null,
                            style: const TextStyle(fontSize: 18),
                            onChanged: (_) {
                              setState(() {}); // Trigger a rebuild on TextField change
                            },
                            decoration: InputDecoration(
                              hintText: 'Reply to ${widget.username}',
                              hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              InkWell(
                                onTap: () {},
                                child: const Icon(
                                  Icons.photo_library,
                                  color: Colors.grey,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(
                                width: 18,
                              ),
                              InkWell(
                                onTap: () {},
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.grey,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              InkWell(
                                onTap: () {},
                                child: const Icon(
                                  Icons.mic_none_outlined,
                                  color: Colors.grey,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              InkWell(
                                onTap: () {},
                                child: const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.grey,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void postComment(User? currentUser) async {
    String commentText = _commentTextController.text.trim();

    if (commentText.isNotEmpty) {
      await FirebaseFirestore.instance.collection('comments').add({
        'userId': currentUser?.uid,
        'username': currentUser?.displayName,
        'text': commentText,
        'postId': widget.postId, // Include postId in the comment data
        'timestamp': Timestamp.now(),
      });

      // Clear the text field after posting the comment
      _commentTextController.clear();
    }
  }
}





// Expanded(
//   child: StreamBuilder<QuerySnapshot>(
//     stream: FirebaseFirestore.instance
//         .collection('comments')
//         .where('postId',
//             isEqualTo: widget.postId) // Filter comments by postId
//         .snapshots(),
//     builder: (context, snapshot) {
//       // if (snapshot.connectionState == ConnectionState.waiting) {
//       //   return Center(child: CircularProgressIndicator());
//       // }
//
//       if (snapshot.hasError) {
//         return Center(child: Text('Error: ${snapshot.error}'));
//       }
//
//       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//         return Center(child: Text('No comments yet'));
//       }
//
//       return ListView.builder(
//         itemCount: snapshot.data!.docs.length,
//         itemBuilder: (context, index) {
//           DocumentSnapshot commentDoc = snapshot.data!.docs[index];
//           Map<String, dynamic> commentData =
//           commentDoc.data() as Map<String, dynamic>;
//
//           return FutureBuilder<DocumentSnapshot>(
//             future: FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(commentData['userId'])
//                 .get(),
//             builder: (context, userSnapshot) {
//               // if (userSnapshot.connectionState ==
//               //     ConnectionState.waiting) {
//               //   return CircularProgressIndicator();
//               // }
//
//               if (userSnapshot.hasError) {
//                 return Text('Error: ${userSnapshot.error}');
//               }
//
//               if (!userSnapshot.hasData ||
//                   !userSnapshot.data!.exists) {
//                 return Text('User not found');
//               }
//
//               Map<String, dynamic> userData =
//               userSnapshot.data!.data() as Map<String, dynamic>;
//
//               return ListTile(
//                 leading: CircleAvatar(
//                   // Use the commenter's profile picture
//                   backgroundImage: NetworkImage(
//                       userData['profile'] ?? ''),
//                 ),
//                 title: Text(commentData['username'] ?? ''),
//                 subtitle: Text(commentData['text'] ?? ''),
//                 // Additional information like timestamp can be added here
//               );
//             },
//           );
//         },
//       );
//
//     },
//   ),
// ),
