import 'package:flutter/material.dart';

class ImageOrText extends StatelessWidget {
  final String mediaUrl;
  final String postText;

  const ImageOrText({required this.mediaUrl, required this.postText});

  @override
  Widget build(BuildContext context) {
    return mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://') || mediaUrl.startsWith('www.')
        ? Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            mediaUrl,
            fit: BoxFit.cover,
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
              return Container(
                color: Colors.grey[200], // Placeholder color
                child: Icon(Icons.error),
              );
            },
          ),
        ),
      ),
    )
        : Container();
  }
}
