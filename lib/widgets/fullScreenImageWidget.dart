import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Center(
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta! > 10) {
                Navigator.of(context).pop();
              }
            },
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: BoxDecoration(
                color: Colors.black,
              ),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),
        ),
      ),
    );
  }
}
