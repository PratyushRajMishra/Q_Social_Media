import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String text;
  final String? mediaUrl; // Property to store media URL
  final String? fileType; // Property to store file type
  final Timestamp timestamp;
  final List<String> likedBy;

  PostModel({
    required this.id,
    required this.userId,
    required this.text,
    this.mediaUrl, // Initialize mediaUrl with null
    this.fileType, // Initialize fileType with null
    required this.timestamp,
    required this.likedBy,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      text: map['text'] ?? '',
      mediaUrl: map['mediaUrl'], // Assign mediaUrl from map
      fileType: map['fileType'], // Assign fileType from map
      timestamp: map['timestamp'] ?? Timestamp.now(),
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'mediaUrl': mediaUrl, // Include mediaUrl in map
      'fileType': fileType, // Include fileType in map
      'timestamp': timestamp,
      'likedBy': likedBy,
    };
  }

  void toggleLike(String userId) {
    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
    } else {
      likedBy.add(userId);
    }
  }
}
