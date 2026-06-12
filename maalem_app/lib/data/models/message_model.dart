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
      id: _toInt(json['id']),
      bookingId: _toInt(json['booking_id'] ?? json['bookingId']),
      senderId: _toInt(json['sender_id'] ?? json['senderId']),
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

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.parse(value.toString());
  }
}
