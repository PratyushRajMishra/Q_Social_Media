import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String text;
  final Timestamp timestamp;
  final List<String> likedBy;

  // New properties to track likes
  PostModel({
    required this.id,
    required this.userId,
    required this.text,
    required this.timestamp,
    required this.likedBy,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
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
