import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:q/screens/tabs/Home.dart';
import 'package:q/screens/tabs/Message.dart';
import 'package:q/screens/tabs/Notification.dart';
import 'package:q/screens/tabs/Post.dart';
import 'package:q/screens/tabs/Search.dart';

import '../models/userModel.dart';

class BottomNavbarPage extends StatefulWidget {
  final UserModel userModel;

  const BottomNavbarPage({Key? key, required this.userModel}) : super(key: key);

  @override
  State<BottomNavbarPage> createState() => _BottomNavbarPageState();
}

class _BottomNavbarPageState extends State<BottomNavbarPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _tabs = [
    HomePage(),
    const SearchPage(),
    const PostPage(),
    const NotificationPage(),
    const MessagePage(),
  ];

  final List<List<IconData>> _tabIcons = [
    [Icons.home, Icons.home_outlined],
    [Icons.search, Icons.search_outlined],
    [Icons.note_alt, Icons.note_alt_outlined],
    [Icons.notifications, Icons.notifications_outlined],
    [Icons.mail, Icons.mail_outline_outlined],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: Theme.of(context).colorScheme.background,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (index) {
            return IconButton(
              icon: Icon(
                _selectedIndex == index ? _tabIcons[index][0] : _tabIcons[index][1],
                size: 28,
              ),
              onPressed: () {
                if (index == 2) {
                  Navigator.push(context, _customPageRouteBuilder(const PostPage()));
                } else {
                  _onTabTapped(index);
                }
              },
            );
          }),
        ),
      ),
      drawer: Drawer(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Text(
                  'Welcome, ${widget.userModel.name ?? 'Guest'}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              ListTile(
                title: Text('Profile'),
                onTap: () {
                  // Navigate to profile page
                },
              ),
              ListTile(
                title: Text('Settings'),
                onTap: () {
                  // Navigate to settings page
                },
              ),
              ListTile(
                title: Text('Sign Out'),
                onTap: () {
                  // Perform sign out action
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  PageRouteBuilder _customPageRouteBuilder(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var curveTween = CurveTween(curve: curve);
        var tween = Tween(begin: begin, end: end).chain(curveTween);
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}
