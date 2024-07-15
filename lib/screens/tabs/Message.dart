import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:q/Messages/userList.dart';
import '../../Messages/userMessage.dart';
import '../Setting.dart';
import '../UserProfile.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({Key? key}) : super(key: key);

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  bool isSearchBarVisible = false;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: isSearchBarVisible ? buildSearchAppBar() : buildDefaultAppBar(),
      body: isSearchBarVisible ? buildSearchBody() : buildDefaultBody(),
    );
  }

  Widget buildDefaultBody() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (userSnapshot.hasError) {
          return Center(child: Text('Error: ${userSnapshot.error}'));
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return Center(child: Text('User data not found.'));
        }

        final currentUserData = userSnapshot.data!.data() as Map<String, dynamic>;
        final pinnedConversations = (currentUserData['pinnedConversations'] as List<dynamic>?)?.cast<String>() ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('messages')
              .where('participants', arrayContains: FirebaseAuth.instance.currentUser!.uid)
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to your inbox!',
                      style: TextStyle(fontSize: 35, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Drop a line, share posts and more with private\n'
                          'conversations between you and others on Q.',
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 35),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const MessageUserListPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 13),
                        child: Text(
                          'Write a message',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final messages = snapshot.data!.docs;
            final userIds = messages.map((doc) => doc['participants']).expand((i) => i).toSet();
            userIds.remove(FirebaseAuth.instance.currentUser!.uid);

            final List<String> sortedUserIds = [
              ...pinnedConversations.where(userIds.contains), // Pinned conversations first
              ...userIds.where((id) => !pinnedConversations.contains(id)), // Other conversations
            ];

            return Stack(
              children: [
                ListView.builder(
                  itemCount: sortedUserIds.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(sortedUserIds.elementAt(index)).get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          //return Center(child: CircularProgressIndicator());
                        }

                        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                          return Container();
                        }

                        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        final userId = sortedUserIds.elementAt(index);
                        final userName = userData['name'] ?? 'Unknown User';

                        return FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance.collection('messages')
                              .where('participants', arrayContains: userId)
                              .orderBy('timestamp', descending: true)
                              .limit(1)
                              .get(),
                          builder: (context, messageSnapshot) {
                            String lastMessage = 'Loading...';
                            String lastMessageTime = '';
                            Widget lastMessageWidget = Text(lastMessage);

                            if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
                              final lastDoc = messageSnapshot.data!.docs.first;
                              final mediaType = lastDoc['mediaType'];

                              lastMessageTime = DateFormat('hh:mm a').format(
                                (lastDoc['timestamp'] as Timestamp).toDate(),
                              );

                              if (mediaType == 0) {
                                lastMessage = lastDoc['text'] ?? 'Loading...';
                                lastMessageWidget = _buildTruncatedText(lastMessage);
                              } else if (mediaType == 1) {
                                lastMessageWidget = Text('You sent a photo');
                              } else if (mediaType == 2) {
                                lastMessageWidget = Text('You sent a video');
                              }
                            }

                            final bool isPinned = pinnedConversations.contains(userId);

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 23,
                                backgroundImage: CachedNetworkImageProvider(userData['profile'] ?? ''),
                                backgroundColor: Colors.grey,
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(userName),
                                  if (isPinned)
                                    Icon(CupertinoIcons.pin_fill, color: Colors.orange, size: 16),
                                ],
                              ),
                              subtitle: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  lastMessageWidget,
                                  Text(
                                    lastMessageTime,
                                    style: TextStyle(color: Colors.grey, fontSize: 10),
                                  ),
                                ],
                              ),
                              onTap: () {
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
                              onLongPress: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            title: Text('Delete conversation'),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              _deleteConversation(userId);
                                            },
                                          ),
                                          ListTile(
                                            title: Text(isPinned ? 'Unpin conversation' : 'Pin conversation'),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              _pinConversation(userId);
                                            },
                                          ),
                                          ListTile(
                                            title: Text('Report @$userName'),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              _reportConversation(userId);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                Positioned(
                  bottom: 20,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const MessageUserListPage(),
                        ),
                      );
                    },
                    child: Icon(CupertinoIcons.plus_bubble, size: 25, color: Colors.white),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTruncatedText(String text) {
    // Maximum number of words to display
    const int maxWords = 7;
    final words = text.split(' ');
    final isTextLong = words.length > maxWords;

    return Text(
      isTextLong ? '${words.take(maxWords).join(' ')}...' : text,
      style: TextStyle(color: Colors.grey), // Adjust the style as needed
      maxLines: 2, // Adjust the number of lines as needed
      overflow: TextOverflow.ellipsis,
    );
  }


  void _deleteConversation(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
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
  }

  void _pinConversation(String userId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();

    final pinnedConversations = (userDoc.data()!['pinnedConversations'] as List<dynamic>?) ?? [];
    if (!pinnedConversations.contains(userId)) {
      pinnedConversations.add(userId);
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'pinnedConversations': pinnedConversations,
      });
    } else {
      pinnedConversations.remove(userId);
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'pinnedConversations': pinnedConversations,
      });
    }
  }

  void _reportConversation(String userId) {
    print('Conversation with $userId reported.');
  }




  Widget buildSearchBody() {
    return Column(
      children: [
        // Check if search query is empty
        if (searchQuery.isEmpty)
          Center(
            child: Text(
              'Try searching for people or messages',
              style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          )
        else ...[
          // User Search
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('messages')
                .where('participants', arrayContains: FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, messageSnapshot) {
              if (messageSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (messageSnapshot.hasError) {
                return Center(child: Text('Error: ${messageSnapshot.error}'));
              }

              final messages = messageSnapshot.data!.docs;
              final participantIds = messages
                  .expand((doc) => (doc['participants'] as List)
                  .where((id) => id != FirebaseAuth.instance.currentUser!.uid))
                  .toSet()
                  .toList();

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .where(FieldPath.documentId, whereIn: participantIds)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (userSnapshot.hasError) {
                    return Center(child: Text('Error: ${userSnapshot.error}'));
                  }

                  final users = userSnapshot.data!.docs;
                  final filteredUsers = users.where((doc) {
                    final userData = doc.data() as Map<String, dynamic>;
                    final userId = doc.id;
                    final userName = userData['name'] ?? '';
                    return userName.toLowerCase().contains(searchQuery.toLowerCase()) &&
                        userId != FirebaseAuth.instance.currentUser!.uid; // Exclude current user
                  }).toList();

                  return filteredUsers.isEmpty
                      ? Center(child: Text('No users found.'))
                      : Expanded(
                    child: ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final userData = filteredUsers[index].data() as Map<String, dynamic>;
                        final userId = filteredUsers[index].id;
                        final userName = userData['name'] ?? 'Unknown User';

                        return FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance.collection('messages')
                              .where('participants', arrayContains: userId)
                              .orderBy('timestamp', descending: true)
                              .limit(1)
                              .get(),
                          builder: (context, messageSnapshot) {
                            String lastMessage = 'No messages yet';

                            if (messageSnapshot.connectionState == ConnectionState.waiting) {
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 23,
                                  backgroundImage: CachedNetworkImageProvider(userData['profile'] ?? ''),
                                  backgroundColor: Colors.grey,
                                ),
                                title: Text(userName),
                                subtitle: Text('Loading last message...'),
                              );
                            }

                            if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
                              final lastDoc = messageSnapshot.data!.docs.first;
                              lastMessage = lastDoc['text'] ?? 'No messages yet';
                            }

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 23,
                                backgroundImage: CachedNetworkImageProvider(userData['profile'] ?? ''),
                                backgroundColor: Colors.grey,
                              ),
                              title: Text(userName),
                              subtitle: Text(lastMessage),
                              onTap: () {
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
                  );
                },
              );
            },
          ),

          // Message Search
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('messages')
                .where('participants', arrayContains: FirebaseAuth.instance.currentUser!.uid)
                .get(),
            builder: (context, messageSnapshot) {
              if (messageSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (messageSnapshot.hasError) {
                return Center(child: Text('Error: ${messageSnapshot.error}'));
              }

              final messages = messageSnapshot.data!.docs;
              final filteredMessages = messages.where((doc) {
                final text = doc['text'] ?? '';
                return text.toLowerCase().contains(searchQuery.toLowerCase());
              }).toList();

              return Expanded(
                child: ListView.builder(
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) {
                    final messageData = filteredMessages[index].data() as Map<String, dynamic>;
                    final participants = messageData['participants'] as List;
                    final otherUserId = participants.firstWhere((id) => id != FirebaseAuth.instance.currentUser!.uid);
                    final messageTime = DateFormat('hh:mm a').format((messageData['timestamp'] as Timestamp).toDate());

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return Container();
                        }

                        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        final userName = userData['name'] ?? 'Unknown User';

                        return ListTile(
                          title: Text(messageData['text'] ?? '', style: TextStyle(fontWeight: FontWeight.w500),),
                          subtitle: Text('by: $userName'),
                          trailing: Text(
                            messageTime,
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => UserMessagePage(
                                  userId: otherUserId,
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
              );
            },
          ),
        ],
      ],
    );
  }


  AppBar buildDefaultAppBar() {
    User? _user = FirebaseAuth.instance.currentUser;
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => const UserProfilePage()));
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
      title: InkWell(
        onTap: () {
          setState(() {
            isSearchBarVisible = true;
          });
        },
        child: Container(
          height: 35,
          width: double.maxFinite,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.blueGrey.shade100, width: 0.3),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9.0),
            child: Text(
              'Search Direct Messages',
              style: TextStyle(
                fontSize: 15,
                color: Colors.blueGrey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const SettingPage()),
            );
          },
          icon: Icon(Icons.settings_outlined, size: 23),
        ),
      ],
    );
  }

  AppBar buildSearchAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        onPressed: () {
          setState(() {
            isSearchBarVisible = false;
            searchQuery = ''; // Clear the search query when going back
          });
        },
        icon: Icon(Icons.arrow_back),
      ),
      title: TextField(
        autofocus: true,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        style: TextStyle(),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search Direct Messages',
          hintStyle: TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}
