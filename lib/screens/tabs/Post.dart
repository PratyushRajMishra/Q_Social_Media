import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart' as audioplayers;
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:video_player/video_player.dart';

import '../../models/postModel.dart';
import '../../widgets/audioPlayerWidget.dart';
import '../UserProfile.dart';
import '../recordSound.dart';

class PostPage extends StatefulWidget {
  final String audioPath;

  const PostPage({Key? key, required this.audioPath}) : super(key: key);

  @override
  State<PostPage> createState() => _PostPageState();
}


class _PostPageState extends State<PostPage> {
  TextEditingController _textController = TextEditingController();
  TextEditingController _questionController = TextEditingController();
  bool askingQuestion = false;
  bool _isPosting = false;
  File? _image;
  File? _video;
  late AudioPlayer audioPlayer;
  bool _isPlaying = false;
  final ImagePicker _picker = ImagePicker();
  late VideoPlayerController _videoPlayerController;

  Timer? _timer; // Declare Timer
  late double _sliderValue = 0.0;
  late Duration _audioDuration = Duration();
  bool _isAudioComplete = false; // Add this variable

  @override
  void initState() {
    audioPlayer = AudioPlayer();
    _isPlaying = false;
    super.initState();
    if (_video != null) {
      _initializeVideoPlayer();
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }

  void _initializeVideoPlayer() {
    _videoPlayerController = VideoPlayerController.file(_video!)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    User? _user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            setState(() {
              (_textController.text.isEmpty &&
                  _image == null &&
                  _video == null)
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
              onPressed: _isPosting
                  ? null
                  : (_textController.text.isEmpty &&
                  _image == null &&
                  _video == null
                  && widget.audioPath.isEmpty
              )
                  ? null
                  : _onPostPressed,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.grey;
                    }
                    return Colors.blue;
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
                _isPosting ? 'Posting...' : 'Post',
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              leading: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const UserProfilePage()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Icon(Icons.error);
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Icon(Icons.account_circle, size: 30, color: Theme
                            .of(context)
                            .colorScheme
                            .tertiary);
                      }

                      Map<String, dynamic> userData =
                      snapshot.data!.data() as Map<String, dynamic>;

                      if (userData.containsKey('profile') &&
                          userData['profile'] != null) {
                        return CircleAvatar(
                          radius: 25,
                          backgroundImage:
                          CachedNetworkImageProvider(userData['profile']),
                          backgroundColor: Colors.transparent,
                        );
                      } else {
                        return Icon(Icons.account_circle, size: 30, color: Theme
                            .of(context)
                            .colorScheme
                            .tertiary);
                      }
                    },
                  ),
                ),
              ),
              title: askingQuestion
                  ? null
              // _buildAskQuestionWidget()
                  : _buildTextFieldWidget(),
              subtitle: askingQuestion
                  ? null
                  : Row(
                children: [
                  InkWell(
                    onTap: _getImageFromGallery,
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
                    onTap: _getVideoFromGallery,
                    child: const Icon(
                      Icons.video_library,
                      color: Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(
                    width: 18,
                  ),
                  InkWell(
                    onTap: _getImageFromCamera,
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
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => RecordSoundPage()),
                      );
                    },
                    child: const Icon(
                      Icons.mic_none_outlined,
                      color: Colors.grey,
                      size: 22,
                    ),
                  ),
                  // const SizedBox(
                  //   width: 15,
                  // ),
                  // InkWell(
                  //   onTap: () {
                  //     setState(() {
                  //       askingQuestion = !askingQuestion;
                  //     });
                  //   },
                  //   child: const Icon(
                  //     Icons.notes_outlined,
                  //     color: Colors.grey,
                  //     size: 22,
                  //   ),
                  // ),
                ],
              ),
            ),
            if (_image != null)
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery
                      .of(context)
                      .size
                      .height * 0.7,
                  maxWidth: double.infinity,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.only(top: 10, right: 20, left: 50),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _image!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (_video != null)
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery
                      .of(context)
                      .size
                      .height * 0.7,
                  maxWidth: double.infinity,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.only(top: 10, right: 20, left: 50),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _videoPlayerController.value.aspectRatio,
                        child: VideoPlayer(_videoPlayerController),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_videoPlayerController.value.isPlaying) {
                            _videoPlayerController.pause();
                          } else {
                            _videoPlayerController.play();
                          }
                          setState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _videoPlayerController.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.audioPath.isNotEmpty)
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery
                      .of(context)
                      .size
                      .height * 0.1,
                  maxWidth: double.infinity,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.only(top: 30, right: 20, left: 70),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme
                                .of(context)
                                .colorScheme
                                .tertiary,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () {
                                  if (_isPlaying) {
                                    pauseRecording();
                                  } else {
                                    playRecording();
                                  }
                                },
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 40,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: _sliderValue,
                                min: 0.0,
                                max: _audioDuration.inSeconds.toDouble(),
                                onChanged: (double value) {
                                  setState(() {
                                    _sliderValue = value;
                                    // Seek the audio player to the new position
                                    audioPlayer.seek(
                                        Duration(seconds: value.toInt()));
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> playRecording() async {
    try {
      final audioplayers.UrlSource urlSource = audioplayers.UrlSource(
          widget.audioPath);
      await audioPlayer.play(urlSource);
      setState(() {
        _isPlaying =
        true; // Set playing state to true when audio starts playing
        _isAudioComplete = false; // Reset audio completion flag
      });

      audioPlayer.onDurationChanged.listen((Duration duration) {
        setState(() {
          _audioDuration = duration;
        });
      });

      audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _isPlaying = false; // Set playing state to false when audio completes
          _isAudioComplete = true; // Set audio completion flag to true
          _sliderValue = 0.0; // Reset slider value to start
        });
      });

      _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
        audioPlayer.getCurrentPosition().then((position) {
          if (position != null &&
              position.inMilliseconds < _audioDuration.inMilliseconds) {
            setState(() {
              _sliderValue = position.inMilliseconds.toDouble() /
                  _audioDuration.inMilliseconds.toDouble();
            });
          } else {
            if (!_isAudioComplete) {
              _timer?.cancel(); // Stop the timer when audio playback finishes
            }
          }
        });
      });
    } catch (e) {
      print('Error playing recording: $e');
    }
  }

// Modify pauseRecording method

  Future<void> pauseRecording() async {
    try {
      await audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
      _timer?.cancel(); // Cancel the timer
    } catch (e) {
      print('Error pausing recording: $e');
    }
  }

  void _getImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _video = null;
      });
    }
  }

  void _getVideoFromGallery() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _video = File(pickedFile.path);
        _image = null;
        _initializeVideoPlayer();
      });
    }
  }

  void _getImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _video = null;
      });
    }
  }

  Widget _buildTextFieldWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        maxLength: 100,
        autofocus: true,
        controller: _textController,
        maxLines: null,
        style: const TextStyle(fontSize: 18),
        onChanged: (_) {
          setState(() {});
        },
        decoration: const InputDecoration(
          hintText: 'Write something...',
          hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }


  //
  // Widget _buildAskQuestionWidget() {
  //   List<TextEditingController> optionControllers =
  //   List.generate(3, (index) => TextEditingController());
  //
  //   return Container(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.end,
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         const SizedBox(
  //           height: 10,
  //         ),
  //         TextField(
  //           decoration: InputDecoration(
  //             border: InputBorder.none,
  //             hintText: 'Ask a question...',
  //             hintStyle: TextStyle(
  //                 fontSize: 18,
  //                 color: Theme
  //                     .of(context)
  //                     .colorScheme
  //                     .tertiary),
  //           ),
  //           controller: _questionController,
  //         ),
  //         for (int i = 0; i < optionControllers.length; i++)
  //           Padding(
  //             padding: const EdgeInsets.only(top: 8),
  //             child: CupertinoTextField(
  //               controller: optionControllers[i],
  //               placeholder: 'Option ${i + 1}',
  //               padding: const EdgeInsets.all(8.0),
  //               decoration: BoxDecoration(
  //                 border: Border.all(
  //                   color: Theme
  //                       .of(context)
  //                       .colorScheme
  //                       .secondary,
  //                   width: 1.0,
  //                 ),
  //                 borderRadius: BorderRadius.circular(8.0),
  //               ),
  //             ),
  //           ),
  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: InkWell(
  //             onTap: () {
  //               setState(() {
  //                 askingQuestion = false;
  //               });
  //             },
  //             child: Text(
  //               'Remove question',
  //               style: TextStyle(
  //                 fontSize: 13,
  //                 fontWeight: FontWeight.w500,
  //                 color: Theme
  //                     .of(context)
  //                     .colorScheme
  //                     .secondary,
  //               ),
  //             ),
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }

  void _closeDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Discard posts?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Discard',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            const Divider(
              thickness: 1.0,
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .tertiary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onPostPressed() async {
    User? _user = FirebaseAuth.instance.currentUser;

    String postText = _textController.text.trim();

    if (postText.isNotEmpty || _image != null || _video != null ||
        widget.audioPath.isNotEmpty) {
      try {
        setState(() {
          _isPosting = true;
        });

        FirebaseFirestore firestore = FirebaseFirestore.instance;

        String mediaUrl = '';
        String fileType = '';

        if (_image != null) {
          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('post_images')
              .child('${_user?.uid}_${DateTime
              .now()
              .millisecondsSinceEpoch}.jpg');
          await storageRef.putFile(_image!);
          mediaUrl = await storageRef.getDownloadURL();
          fileType = 'image';
        } else if (_video != null) {
          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('post_videos')
              .child('${_user?.uid}_${DateTime
              .now()
              .millisecondsSinceEpoch}.mp4');
          await storageRef.putFile(_video!);
          mediaUrl = await storageRef.getDownloadURL();
          fileType = 'video';
        } else if (widget.audioPath.isNotEmpty) {
          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('post_audios')
              .child('${_user?.uid}_${DateTime
              .now()
              .millisecondsSinceEpoch}.mp3');
          await storageRef.putFile(File(widget.audioPath));
          mediaUrl = await storageRef.getDownloadURL();
          fileType = 'audio';
        }

        Map<String, dynamic> postData = {
          'text': postText,
          'timestamp': Timestamp.now(),
          'mediaUrl': mediaUrl,
          'fileType': fileType,
        };

        DocumentReference postRef = await firestore
            // .collection('users')
            // .doc(_user?.uid)
            .collection('posts')
            .add(postData);

        String postId = postRef.id;

        PostModel post = PostModel(
          id: postId,
          userId: _user?.uid ?? '',
          text: postText,
          mediaUrl: mediaUrl,
          timestamp: Timestamp.now(),
          likedBy: [],
          fileType: fileType,
        );

        await firestore
            // .collection('users')
            // .doc(_user?.uid)
            .collection('posts')
            .doc(postId)
            .set(post.toMap());

        _textController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post saved successfully'),
          ),
        );
      } catch (error) {
        print('Error saving post: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save post'),
          ),
        );
      } finally {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }
}