import 'dart:io';

import 'package:audioplayers/audioplayers.dart' as audioplayers;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:q/screens/tabs/Post.dart';
import 'package:record/record.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RecordSoundPage extends StatefulWidget {
  const RecordSoundPage({Key? key}) : super(key: key);

  @override
  State<RecordSoundPage> createState() => _RecordSoundPageState();
}

class _RecordSoundPageState extends State<RecordSoundPage> {
  late Record audioRecord;
  late AudioPlayer audioPlayer;
  bool _isRecording = false;
  bool _isPlaying = false;
  late String audioPath = '';

  @override
  void initState() {
    audioPlayer = AudioPlayer();
    audioRecord = Record();
    super.initState();
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            if (_isRecording) {
              stopRecording();
            }
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.close,
            size: 30,
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onTap: () {
                      showTemporaryMessage(context);
                    },
                    onLongPress: () {
                      startRecording();
                    },
                    onLongPressEnd: (_) {
                      stopRecording();
                    },
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        if (!_isRecording && audioPath.isEmpty)
                          Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                              child: Icon(Icons.circle_outlined, size: 80, color: Colors.white),
                          ),

                        if (_isRecording)
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade300,
                            ),
                            child: Icon(Icons.square, size: 40, color: Colors.red),
                          ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (audioPath.isNotEmpty && !_isRecording)
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        audioPath = ''; // Clear audio path
                      });
                    },
                    child: Icon(CupertinoIcons.arrow_turn_up_left, size: 30,),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_isPlaying) {
                        pauseRecording();
                      } else {
                        playRecording();
                      }
                    },
                    child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow_rounded, size: 70,),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => PostPage(audioPath: audioPath)),
                      );
                    },
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> startRecording() async {
    if (_isRecording) return;

    try {
      if (await audioRecord.hasPermission()) {
        final appDocDir = await getApplicationDocumentsDirectory();
        audioPath = '${appDocDir.path}/recording.aac';

        await audioRecord.start(path: audioPath, encoder: AudioEncoder.AAC);
        setState(() {
          _isRecording = true;
        });
      } else {
        print('No permission for audio recording');
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      String? path = await audioRecord.stop();
      setState(() {
        _isRecording = false;
        audioPath = path!;
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> playRecording() async {
    try {
      final audioplayers.UrlSource urlSource = audioplayers.UrlSource(audioPath);
      await audioPlayer.play(urlSource);
      setState(() {
        _isPlaying = true; // Set playing state to true when audio starts playing
      });
    } catch (e) {
      print('Error playing recording : $e');
    }
  }

  Future<void> pauseRecording() async {
    try {
      await audioPlayer.pause();
      setState(() {
        _isPlaying = false; // Set playing state to false when audio is paused
      });
    } catch (e) {
      print('Error pausing recording : $e');
    }
  }

  void showTemporaryMessage(BuildContext context) {
    final RenderBox buttonBox = context.findRenderObject() as RenderBox;
    final buttonPosition = buttonBox.localToGlobal(Offset.zero);

    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom + 60,
        left: 60,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            alignment: Alignment.bottomRight,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Text(
                  'Hold to record, release to stop',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(overlayEntry);

    Future.delayed(Duration(milliseconds: 1500), () {
      overlayEntry.remove();
    });
  }
}
