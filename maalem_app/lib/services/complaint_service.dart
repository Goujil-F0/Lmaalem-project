import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';

class ComplaintService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'complaints';

  // Créer une réclamation
  Future<void> submitComplaint(ComplaintModel complaint) async {
    final docRef = _firestore.collection(_collection).doc();
    await docRef.set(complaint.toMap());
  }

  // Récupérer les réclamations d'un utilisateur (reporter)
  Stream<List<ComplaintModel>> getMyComplaints(String userId) {
    return _firestore
        .collection(_collection)
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ComplaintModel.fromFirestore).toList());
  }

  // Récupérer les réclamations reçues (pour un artisan)
  Stream<List<ComplaintModel>> getComplaintsAgainst(String targetId) {
    return _firestore
        .collection(_collection)
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ComplaintModel.fromFirestore).toList());
  }

  // Toutes les réclamations (admin uniquement)
  Stream<List<ComplaintModel>> getAllComplaints() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ComplaintModel.fromFirestore).toList());
  }

  // Changer le statut d'une réclamation (admin)
  Future<void> updateStatus(String complaintId, ComplaintStatus status, {String? adminNote}) async {
    final update = <String, dynamic>{'status': status.name};
    if (adminNote != null) update['adminNote'] = adminNote;
    await _firestore.collection(_collection).doc(complaintId).update(update);
  }

  // Récupérer le nombre de réclamations par statut pour un artisan
  Future<Map<ComplaintStatus, int>> getComplaintCountByStatus(String artisanId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('targetId', isEqualTo: artisanId)
        .get();

    final counts = <ComplaintStatus, int>{};
    for (final status in ComplaintStatus.values) {
      counts[status] = snap.docs.where((d) => d['status'] == status.name).length;
    }
    return counts;
  }
}