import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth to get the current user

import 'package:q/Messages/userMessage.dart';

class MessageUserListPage extends StatefulWidget {
  const MessageUserListPage({super.key});

  @override
  State<MessageUserListPage> createState() => _MessageUserListPageState();
}

class _MessageUserListPageState extends State<MessageUserListPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _currentUserId;

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
          // ListTile(
          //   onTap: () {},
          //   leading: Container(
          //     height: 35,
          //     width: 35,
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(50),
          //       border: Border.all(
          //         color: Colors.blue,
          //         width: 1.0,
          //       ),
          //     ),
          //     child: Icon(
          //       Icons.groups_2_outlined,
          //       color: Colors.blue,
          //       size: 22,
          //     ),
          //   ),
          //   title: Text(
          //     'Create a group',
          //     style: TextStyle(
          //       color: Colors.blue,
          //       fontWeight: FontWeight.w900,
          //       fontSize: 15,
          //     ),
          //   ),
          // ),
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
                    bool isFollowing = userData['followers'] != null &&
                        userData['followers'].contains(_currentUserId);

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
                      onTap: () {
                        // Navigate to the target user's message
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => UserMessagePage(
                              userId: userId,
                              userName: userName,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
