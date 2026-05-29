// lib/data/models/message_model.dart

class Message {
  final int id;
  final int bookingId;
  final int senderId;
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      bookingId: json['booking_id'],
      senderId: json['sender_id'],
      content: json['content'],
      // PostgreSQL renvoie souvent la date sous forme de String, on la convertit en DateTime
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'sender_id': senderId,
      'content': content,
    };
  }
}
