import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:q/screens/UserProfile.dart';
import 'package:q/screens/target_profile.dart';

class FollowersListPage extends StatefulWidget {
  final String userId;

  const FollowersListPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<FollowersListPage> createState() => _FollowersListPageState();
}

class _FollowersListPageState extends State<FollowersListPage> {
  late DocumentReference _userRef;

  @override
  void initState() {
    super.initState();
    _userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Followers',
          style: TextStyle(
            letterSpacing: 0.5,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final List<dynamic> followers = userData['followers'] ?? []; // Accessing the followers field
            return ListView.builder(
              itemCount: followers.length,
              itemBuilder: (context, index) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(followers[index]).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      final followerData = snapshot.data!.data() as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () {
                          // Navigate to user profile page when tapped
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TargetProfilePage(userId: followers[index]),
                            ),
                          );
                        },
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          title: Text(
                            followerData['name'] ?? 'No Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            followerData['email'] != null
                                ? followerData['email']
                                : followerData['phoneNumber'] ?? 'No contact info',
                          ),
                          leading: CircleAvatar(
                            radius: 30, // Adjust the radius as needed
                            backgroundImage: NetworkImage(followerData['profile'] ?? ''),
                          ),
                          trailing: SizedBox(
                            height: 25,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                              ),
                              onPressed: () {
                                // Add your onPressed logic here
                              },
                              child: Text(
                                'Remove',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}