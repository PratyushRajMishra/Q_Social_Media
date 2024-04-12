import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerWidget extends StatefulWidget {
  final File audioFile;

  const AudioPlayerWidget({required this.audioFile});

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isInitialized = false;

  Timer? _timer;
  double _sliderValue = 0.0;
  Duration _audioDuration = Duration.zero;
  bool _isAudioComplete = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _timer?.cancel(); // Cancel the timer when disposing
    super.dispose();
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      if (!mounted) return;

      await _audioPlayer.setSourceUrl(widget.audioFile.path);
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
            // When audio completes, reset slider and stop updating
            if (state == PlayerState.completed) {
              _sliderValue = 0.0;
              _isAudioComplete = true;
              _timer?.cancel();
            }
          });
        }
      });

      // Get audio duration once it's initialized
      _audioPlayer.onDurationChanged.listen((Duration duration) {
        setState(() {
          _audioDuration = duration;
        });
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print("Error initializing audio player: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.06,
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.tertiary,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 40,
            ),
            Expanded(
              child: Container(
                width: double.infinity, // To take full width
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6.0, // Set the height of the slider
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 8.0, // Set the radius of the thumb
                    ),
                  ),
                  child: Slider(
                    value: _sliderValue,
                    min: 0.0,
                    max: _audioDuration.inSeconds.toDouble(),
                    onChanged: _isInitialized && !_isAudioComplete
                        ? (double value) {
                      setState(() {
                        _sliderValue = value;
                        // Seek the audio player to the new position
                        _audioPlayer.seek(Duration(seconds: value.toInt()));
                      });
                    }
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playPause() async {
    if (!_isInitialized) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        _timer?.cancel();
      } else {
        await _audioPlayer.resume();
        // Start timer to update slider position
        _timer = Timer.periodic(Duration(milliseconds: 500), (timer) {
          if (_isPlaying && !_isAudioComplete) {
            _audioPlayer.getCurrentPosition().then((Duration? position) {
              if (position != null) {
                setState(() {
                  _sliderValue = position.inSeconds.toDouble();
                });
              }
            });
          }
        });
      }
    } catch (e) {
      print("Error playing/pausing audio: $e");
    }

    if (mounted) {
      setState(() {
        _isPlaying = !_isPlaying;
        _isAudioComplete = false;
      });
    }
  }
}
