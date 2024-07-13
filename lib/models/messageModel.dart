import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final List<String> participants;
  final String? text;
  final String? mediaUrl;
  final MediaType mediaType;
  final Timestamp timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.participants,
    this.text,
    this.mediaUrl,
    required this.mediaType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'participants': participants,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType.index, // assuming MediaType is an enum
      'timestamp': timestamp,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      participants: List<String>.from(map['participants']),
      text: map['text'],
      mediaUrl: map['mediaUrl'],
      mediaType: MediaType.values[map['mediaType']], // assuming MediaType is an enum
      timestamp: map['timestamp'],
    );
  }
}

enum MediaType {
  text,
  image,
  video,
}
