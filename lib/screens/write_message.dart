import 'package:flutter/material.dart';

class WriteMessagePage extends StatefulWidget {
  const WriteMessagePage({Key? key}) : super(key: key);

  @override
  State<WriteMessagePage> createState() => _WriteMessagePageState();
}

class _WriteMessagePageState extends State<WriteMessagePage> {
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
            color: Theme.of(context).colorScheme.tertiary
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: TextField(
            decoration:
            InputDecoration(
              hintText: 'Search...',
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
      body: ListView(
        children: [
          ListTile(
            onTap: () {},
            leading: Container(
              height: 35,
              width: 35,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.blue,
                  width: 1.0,
                ),
              ),
              child: Icon(
                Icons.groups_2_outlined,
                color: Colors.blue,
                size: 22,
              ),
            ),
            title: Text(
              'Create a group',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
          for (int index = 1; index < 21; index++)
            ListTile(
              onTap: () {
                // Handle item tap
              },
              leading: Icon(
                Icons.account_circle_sharp,
                size: 35,
              ),
              title: Text('Item $index', style: TextStyle(fontWeight: FontWeight.w600),),
              subtitle: Text('@subtitle $index'),
            ),
        ],
      ),
    );
  }
}
