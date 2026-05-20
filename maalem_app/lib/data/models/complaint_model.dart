class ComplaintModel {
  final int? id;
  final int bookingId;
  final int clientId;
  final int artisanId;
  final String description;
  final String status;
  final String? clientName;
  final String? artisanName;
  final DateTime? createdAt;

  ComplaintModel({
    this.id,
    required this.bookingId,
    required this.clientId,
    required this.artisanId,
    required this.description,
    required this.status,
    this.clientName,
    this.artisanName,
    this.createdAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'],
      bookingId: json['booking_id'],
      clientId: json['client_id'],
      artisanId: json['artisan_id'],
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      clientName: json['client_name'],
      artisanName: json['artisan_name'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'artisan_id': artisanId,
      'description': description,
    };
  }
}
