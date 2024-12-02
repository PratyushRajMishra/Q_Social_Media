import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final List<String> participants;
  final String? text;
  final String? mediaUrl;
  final MediaType mediaType;
  final String? postId; // Optional post ID for messages containing posts
  final Timestamp timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.participants,
    this.text,
    this.mediaUrl,
    required this.mediaType,
    this.postId, // Optional post ID
    required this.timestamp,
  });

  // Convert Message to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'participants': participants,
      'text': text ?? '',
      'mediaUrl': mediaUrl ?? '',
      'mediaType': mediaType.index, // Store enum index in Firestore
      'postId': postId ?? '', // Store postId if available
      'timestamp': timestamp,
    };
  }

  // Create Message from Map fetched from Firestore
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      text: map['text'],  // This could be null
      mediaUrl: map['mediaUrl'], // This could be null
      mediaType: MediaType.values[map['mediaType'] ?? 0], // Default to `MediaType.text`
      postId: map['postId'], // Retrieve postId if available
      timestamp: map['timestamp'] ?? Timestamp.now(), // Default to current timestamp
    );
  }
}

enum MediaType {
  text,
  image,
  video,
}
