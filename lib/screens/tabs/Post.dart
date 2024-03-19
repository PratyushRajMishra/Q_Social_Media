import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PostPage extends StatefulWidget {
  const PostPage({Key? key}) : super(key: key);

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  TextEditingController _textController = TextEditingController();
  TextEditingController _questionController = TextEditingController();
  bool askingQuestion = false; // Flag to determine whether to show text field or ask question

  @override
  Widget build(BuildContext context) {
    User? _user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
           setState(() {
             (_textController.text.isEmpty)
                 ? Navigator.pop(context)
                 : _closeDialog();
           });
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
              onPressed: (askingQuestion && _questionController.text.isEmpty) ||
                  (!askingQuestion && _textController.text.isEmpty)
                  ? null // Disable button if question field is empty in ask question mode or text field is empty
                  : _onPostPressed,
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
              child: const Text(
                'Post',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(100.0),
              child: CachedNetworkImage(
                imageUrl: _user!.photoURL.toString(),
                width: 40, // Set the desired width
                height: 40, // Set the desired height
                fit: BoxFit.cover, // Adjust the fit as per your requirement
                errorWidget: (context, url, error) => CircleAvatar(
                  child: Icon(CupertinoIcons.person),
                ),
              ),
            ),
            title: askingQuestion
                ? _buildAskQuestionWidget()
                : _buildTextFieldWidget(),
            subtitle: askingQuestion
                ? null
                : Row(
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
                InkWell(
                  onTap: () {
                    setState(() {
                      askingQuestion = !askingQuestion;
                    });
                  },
                  child: const Icon(
                    Icons.notes_outlined,
                    color: Colors.grey,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        autofocus: true,
        controller: _textController,
        maxLines: null,
        style: const TextStyle(fontSize: 18),
        onChanged: (_) {
          setState(() {}); // Trigger a rebuild on TextField change
        },
        decoration: const InputDecoration(
          hintText: 'Write something...',
          hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAskQuestionWidget() {
    List<TextEditingController> optionControllers =
    List.generate(3, (index) => TextEditingController());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          height: 10,
        ),
        TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Ask a question...',
            hintStyle: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.tertiary),
          ),
          controller: _questionController,
        ),
        for (int i = 0; i < optionControllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CupertinoTextField(
              controller: optionControllers[i],
              placeholder: 'Option ${i + 1}',
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
              onTap: () {
                setState(() {
                  askingQuestion = false;
                });
              },
              child: Text(
                'Remove question',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.secondary),
              )),
        )
      ],
    );
  }

  void _closeDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Discard posts?'),
          actions: [
            Column(
              children: [
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Discard', style: TextStyle(color: Colors.redAccent),),
                ),
                const Divider(
                  thickness: 1.0,
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Close', style: TextStyle(color: Theme.of(context).colorScheme.tertiary),),
                ),
              ],
            ),
          ],
        );
      },
    );
  }



  void _onPostPressed() {
    // Add your logic for the "Post" button onPressed event
  }
}
