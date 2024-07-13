import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MessageVideoPlayerWidget extends StatefulWidget {
  final File videoFile;

  const MessageVideoPlayerWidget({Key? key, required this.videoFile}) : super(key: key);

  @override
  _MessageVideoPlayerWidgetState createState() => _MessageVideoPlayerWidgetState();
}

class _MessageVideoPlayerWidgetState extends State<MessageVideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    )
        : Center(child: CircularProgressIndicator());
  }
}
