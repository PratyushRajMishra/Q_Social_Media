import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:q/screens/target_profile.dart';

class FollowingListPage extends StatefulWidget {
  final String userId;

  const FollowingListPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<FollowingListPage> createState() => _FollowingListPageState();
}

class _FollowingListPageState extends State<FollowingListPage> {
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Following',
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
            final List<dynamic> followers = userData['following'] ?? []; // Accessing the followers field
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          title: Text(followerData['name'] ?? 'No Name', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            followerData['email'] != null ? followerData['email'] : followerData['phoneNumber'] ?? 'No contact info',
                          ),
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(followerData['profile'] ?? ''),
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              _showUserProfileBottomSheet(context, followerData);
                            },
                            child: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.tertiary, size: 20),
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

  void _showUserProfileBottomSheet(BuildContext context, Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(top: 20, left: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(userData['profile'] ?? ''),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        userData['name'] ?? 'No Name',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(height: 5,),
                      Text(
                        userData['email'] != null ? userData['email'] : userData['phoneNumber'] ?? 'No contact info',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10,),
              Divider(),
              SizedBox(height: 10,),
              Text('Send message', style: TextStyle(fontSize: 18),),
              SizedBox(height: 25,),
              Text('View profile', style: TextStyle(fontSize: 18),),
              SizedBox(height: 25,),
              Text('Restrict and block', style: TextStyle(color: Colors.red, fontSize: 18),),
              SizedBox(height: 10,),
            ],
          ),
        );
      },
    );
  }
}
