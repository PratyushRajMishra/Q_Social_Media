import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String text;
  final String? mediaUrl; // Nullable, can store media URL if available
  final String? fileType; // Nullable, stores file type if available
  final Timestamp timestamp;
  final List<String> likedBy;

  PostModel({
    required this.id,
    required this.userId,
    required this.text,
    this.mediaUrl,
    this.fileType,
    required this.timestamp,
    required this.likedBy,
  });

  // Factory constructor to convert a map from Firestore into a PostModel
  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '', // Ensure default empty string if 'id' is null
      userId: map['userId'] ?? '', // Ensure default empty string if 'userId' is null
      text: map['text'] ?? '', // Default empty string if 'text' is null
      mediaUrl: map['mediaUrl'], // mediaUrl can be null
      fileType: map['fileType'], // fileType can be null
      timestamp: map['timestamp'] ?? Timestamp.now(), // Default to current timestamp if 'timestamp' is null
      likedBy: List<String>.from(map['likedBy'] ?? []), // Ensure likedBy is a list, default to empty list if null
    );
  }

  // Method to convert PostModel to a map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'mediaUrl': mediaUrl, // Include mediaUrl in the map (can be null)
      'fileType': fileType, // Include fileType in the map (can be null)
      'timestamp': timestamp,
      'likedBy': likedBy, // List of users who liked the post
    };
  }

  // Toggle the like status for a given userId
  void toggleLike(String userId) {
    if (likedBy.contains(userId)) {
      likedBy.remove(userId); // Remove user from the liked list if they already liked it
    } else {
      likedBy.add(userId); // Add user to the liked list if they haven't liked it yet
    }
  }
}
