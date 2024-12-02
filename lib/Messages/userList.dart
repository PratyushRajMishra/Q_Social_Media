  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/cupertino.dart';
  import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth to get the current user

  import 'package:q/Messages/userMessage.dart';

import '../models/messageModel.dart';

  class MessageUserListPage extends StatefulWidget {
    final Map<String, dynamic> postData; // Accept post data

    const MessageUserListPage({Key? key, required this.postData}) : super(key: key);

    @override
    State<MessageUserListPage> createState() => _MessageUserListPageState();
  }

  class _MessageUserListPageState extends State<MessageUserListPage> {
    TextEditingController _searchController = TextEditingController();
    String _searchQuery = "";
    String? _currentUserId;
    final Set<String> _selectedUsers = {}; // Set to hold selected user IDs

    @override
    void initState() {
      super.initState();

      // Get the current user's ID
      _currentUserId = FirebaseAuth.instance.currentUser?.uid;

      _searchController.addListener(() {
        setState(() {
          _searchQuery = _searchController.text;
        });
      });
    }

    @override
    void dispose() {
      _searchController.dispose();
      super.dispose();
    }

    void _sendPostToSelectedUsers() async {
      if (_selectedUsers.isEmpty) return;

      // Get the sender's user ID
      String? senderId = _currentUserId;

      if (senderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get sender information')),
        );
        return;
      }

      // Assuming postId is passed via widget
      String postId = widget.postData['id'];

      for (String receiverId in _selectedUsers) {
        // Create a unique message ID
        String messageId = FirebaseFirestore.instance.collection('messages').doc().id;

        // Create participants list
        List<String> participants = [senderId, receiverId];

        // Construct message data
        Message message = Message(
          id: messageId,
          senderId: senderId,
          receiverId: receiverId,
          participants: participants,
          text: null, // No text, as this is a post-sharing message
          mediaUrl: null, // No media URL for this example
          mediaType: MediaType.text, // Assuming text for post-sharing
          postId: postId, // Include postId
          timestamp: Timestamp.now(),
        );

        // Save message to Firestore
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(messageId)
            .set(message.toMap());
      }

      // Clear selection and notify user
      setState(() {
        _selectedUsers.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post sent to selected users')),
      );
    }



    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(),
          title: Text(
            'Direct Message',
            style: TextStyle(
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(48.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: Icon(
                    Icons.search,
                    size: 27,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No users found.'));
                  }

                  // Filter users based on the search query and exclude current user
                  var filteredUsers = snapshot.data!.docs.where((doc) {
                    var userData = doc.data() as Map<String, dynamic>;
                    var userId = doc.id;
                    var userName = userData['name']?.toLowerCase() ?? '';
                    var userEmail = userData['email']?.toLowerCase() ?? '';
                    var userPhoneNumber = userData['phoneNumber']?.toLowerCase() ?? '';
                    var searchLower = _searchQuery.toLowerCase();

                    return userId != _currentUserId &&
                        (userName.contains(searchLower) || userEmail.contains(searchLower) || userPhoneNumber.contains(searchLower));
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      var userData = filteredUsers[index].data() as Map<String, dynamic>;
                      String userId = filteredUsers[index].id;
                      String userName = userData['name'] ?? '';

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(
                            userData['profile'] ?? 'https://via.placeholder.com/150',
                          ),
                        ),
                        title: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            userName,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            userData['email'] ?? userData['phoneNumber'] ?? '',
                          ),
                        ),
                        trailing: widget.postData.isNotEmpty && _selectedUsers.contains(userId)
                            ? Icon(
                          Icons.check_circle,
                          color: Colors.blue,
                          size: 18, // Blue color for the tick icon
                        )
                            : null, // No trailing icon if not selected
                        selected: widget.postData.isNotEmpty && _selectedUsers.contains(userId),
                        selectedTileColor: Colors.grey[200],
                        onTap: () {
                          if (widget.postData.isNotEmpty) {
                            // Toggle user selection
                            setState(() {
                              if (_selectedUsers.contains(userId)) {
                                _selectedUsers.remove(userId);
                              } else {
                                _selectedUsers.add(userId);
                              }
                            });
                          } else {
                            // Navigate to UserMessagePage if no post data
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserMessagePage(
                                  userId: userId,
                                  userName: userName,
                                  postData: widget.postData,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
            if (_selectedUsers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _sendPostToSelectedUsers,
                  child: Text('Send Post', style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold)  ,),
                  style: ElevatedButton
                      .styleFrom(
                    foregroundColor: Colors
                        .white,
                    backgroundColor:
                    Colors.blue, // Text color
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12), // Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 5), // Custom padding
                    elevation:
                    5, // Shadow for the button
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }
