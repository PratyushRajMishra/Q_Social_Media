import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:q/models/customCircularProgress.dart';
import 'package:video_player/video_player.dart';

class VideoPlayWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayWidgetState createState() => _VideoPlayWidgetState();
}

class _VideoPlayWidgetState extends State<VideoPlayWidget> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  bool _isVideoLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      // You can customize the controls here
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.blue,
        handleColor: Colors.blue,
        backgroundColor: Colors.blueGrey,
        bufferedColor: Colors.blueGrey,
      ),
    );

    _videoPlayerController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isVideoLoaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isVideoLoaded
          ? AspectRatio(
        aspectRatio: _videoPlayerController.value.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10), // Set the border radius
          child: Chewie(
            controller: _chewieController,
          ),
        ),
      )
          : PlaceholderWidget(), // Show placeholder while video is loading
    );
  }

  @override
  void dispose() {
    super.dispose();
    _videoPlayerController.dispose();
    _chewieController.dispose();
  }
}

class PlaceholderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the aspect ratio of the video
    double aspectRatio = MediaQuery.of(context).size.width / MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Center(
            child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.play_arrow, color: Colors.white, size: 40,),
                  SizedBox(
                     height: 60,
                      width: 60,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ))
            ]),
          ),
        ),
      ),
    );
  }
}
