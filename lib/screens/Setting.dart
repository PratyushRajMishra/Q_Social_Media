import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:q/screens/settings/themes.dart';
import 'package:q/screens/settings/yourAccount.dart';


class SettingPage extends StatelessWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(
          'Settings',
          style: TextStyle(
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.tertiary
          ),
        ),
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(48.0),
            child: TextField(
              decoration:
              InputDecoration(
                  hintText: 'Search settings',
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: Icon(
                    Icons.search,
                    size: 27,
                  ),
                  border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.zero
                  )
              ),
            )
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10.0),
          child: Column(
            children: [
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => const YourAccountPage()),
                  );
                },
                leading: Icon(Icons.person_outline),
                title: Text('Your account'),
                subtitle: Text('See information about your account and learn about your account deactivation options.'),
              ),
              SizedBox(height: 20,),

              ListTile(
                leading: Icon(Icons.local_activity_outlined),
                title: Text('Your activity'),
                subtitle: Text('See information about your posts, comments, tags and likes on your account.'),
              ),
              SizedBox(height: 20,),

              ListTile(
                leading: Icon(Icons.lock_outlined),
                title: Text('Security and account access'),
                subtitle: Text("Manage your account's security and keep track of your account's usages, including apps that you have connected to your account."),
              ),
              SizedBox(height: 20,),

              ListTile(
                leading: Icon(Icons.workspace_premium_outlined),
                title: Text('Premium'),
                subtitle: Text("See what's included in Premium and manage your settings."),
              ),
              SizedBox(height: 20,),
              ListTile(
                leading: Icon(Icons.privacy_tip_outlined),
                title: Text('Privacy and safety'),
                subtitle: Text("Manage what information you see and share on Q to others."),
              ),
              SizedBox(height: 20,),
              ListTile(
                leading: Icon(Icons.notifications_active_outlined),
                title: Text('Notifications'),
                subtitle: Text("Select the kinds of nitification you get about your activities, interests and recommendations."),
              ),
              SizedBox(height: 20,),
              ListTile(
                leading: Icon(Icons.language_outlined),
                title: Text('Languages'),
                subtitle: Text("Choose languages as per your preferences and compatibility"),
              ),

              SizedBox(height: 20,),
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => const ThemesPage()),
                  );
                },
                leading: Icon(Icons.light_mode_outlined),
                title: Text('Themes'),
                subtitle: Text("Choose themes as per your preferences and compatibility"),
              ),

              SizedBox(height: 20,),
              ListTile(
                leading: Icon(Icons.settings_suggest_outlined),
                title: Text('Additional settings'),
                subtitle: Text("Check out other places for helpful settings about Q products and services."),
              ),
              SizedBox(height: 20,),
              ListTile(
                leading: Icon(Icons.help_outline_outlined),
                title: Text('Help centre'),
                subtitle: Text("Get answer to some common questions related to Q and get 24*7 assistance."),
              )
            ],
          ),
        ),
      ),
    );
  }
}
