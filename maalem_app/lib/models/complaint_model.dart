import 'package:cloud_firestore/cloud_firestore.dart';

enum ComplaintStatus { pending, inProgress, resolved, rejected }

enum ComplaintType { service, payment, behavior, other }

class ComplaintModel {
  final String id;
  final String reporterId;    // celui qui fait la réclamation
  final String reporterName;
  final String targetId;      // artisan ou client visé
  final String targetName;
  final ComplaintType type;
  final String description;
  final ComplaintStatus status;
  final DateTime createdAt;
  final String? bookingId;
  final String? adminNote;    // réponse de l'admin

  ComplaintModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.targetId,
    required this.targetName,
    required this.type,
    required this.description,
    this.status = ComplaintStatus.pending,
    required this.createdAt,
    this.bookingId,
    this.adminNote,
  });

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComplaintModel(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reporterName: data['reporterName'] ?? '',
      targetId: data['targetId'] ?? '',
      targetName: data['targetName'] ?? '',
      type: ComplaintType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ComplaintType.other,
      ),
      description: data['description'] ?? '',
      status: ComplaintStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ComplaintStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      bookingId: data['bookingId'],
      adminNote: data['adminNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      'targetId': targetId,
      'targetName': targetName,
      'type': type.name,
      'description': description,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'bookingId': bookingId,
      'adminNote': adminNote,
    };
  }

  static String typeLabel(ComplaintType type) {
    switch (type) {
      case ComplaintType.service: return 'Qualité du service';
      case ComplaintType.payment: return 'Problème de paiement';
      case ComplaintType.behavior: return 'Comportement inapproprié';
      case ComplaintType.other: return 'Autre';
    }
  }

  static String statusLabel(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending: return 'En attente';
      case ComplaintStatus.inProgress: return 'En cours';
      case ComplaintStatus.resolved: return 'Résolu';
      case ComplaintStatus.rejected: return 'Rejeté';
    }
  }
}