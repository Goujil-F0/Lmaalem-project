import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DashboardStats> getArtisanStats(String artisanId) async {
    // Récupérer les réservations
    final bookingsSnap = await _firestore
        .collection('bookings')
        .where('artisanId', isEqualTo: artisanId)
        .get();

    final bookings = bookingsSnap.docs;
    final total = bookings.length;
    final completed = bookings.where((d) => d['status'] == 'completed').length;
    final pending = bookings.where((d) => d['status'] == 'pending').length;
    final cancelled = bookings.where((d) => d['status'] == 'cancelled').length;

    // Revenu total (uniquement les réservations complétées)
    double totalRevenue = 0;
    for (final b in bookings.where((d) => d['status'] == 'completed')) {
      totalRevenue += (b['amount'] ?? 0).toDouble();
    }

    // Récupérer les avis
    final reviewsSnap = await _firestore
        .collection('reviews')
        .where('artisanId', isEqualTo: artisanId)
        .get();

    double avgRating = 0;
    if (reviewsSnap.docs.isNotEmpty) {
      final sum = reviewsSnap.docs.fold<double>(
        0, (prev, d) => prev + (d['rating'] ?? 0).toDouble());
      avgRating = sum / reviewsSnap.docs.length;
    }

    // Réclamations
    final complaintsSnap = await _firestore
        .collection('complaints')
        .where('targetId', isEqualTo: artisanId)
        .get();

    // Données mensuelles (6 derniers mois)
    final monthlyRevenue = _buildMonthlyRevenue(bookings);
    final monthlyBookings = _buildMonthlyBookings(bookings);

    return DashboardStats(
      totalBookings: total,
      completedBookings: completed,
      pendingBookings: pending,
      cancelledBookings: cancelled,
      averageRating: double.parse(avgRating.toStringAsFixed(1)),
      totalReviews: reviewsSnap.docs.length,
      totalRevenue: totalRevenue,
      totalComplaints: complaintsSnap.docs.length,
      monthlyRevenue: monthlyRevenue,
      monthlyBookings: monthlyBookings,
    );
  }

  List<MonthlyData> _buildMonthlyRevenue(List<QueryDocumentSnapshot> bookings) {
    final now = DateTime.now();
    final months = <String>['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
                            'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    final result = <MonthlyData>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final label = months[month.month - 1];
      double total = 0;

      for (final b in bookings) {
        if (b['status'] != 'completed') continue;
        final ts = b['createdAt'];
        if (ts == null) continue;
        final date = (ts as Timestamp).toDate();
        if (date.year == month.year && date.month == month.month) {
          total += (b['amount'] ?? 0).toDouble();
        }
      }
      result.add(MonthlyData(month: label, value: total));
    }
    return result;
  }

  List<MonthlyData> _buildMonthlyBookings(List<QueryDocumentSnapshot> bookings) {
    final now = DateTime.now();
    final months = <String>['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
                            'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    final result = <MonthlyData>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final label = months[month.month - 1];
      int count = 0;

      for (final b in bookings) {
        final ts = b['createdAt'];
        if (ts == null) continue;
        final date = (ts as Timestamp).toDate();
        if (date.year == month.year && date.month == month.month) count++;
      }
      result.add(MonthlyData(month: label, value: count.toDouble()));
    }
    return result;
  }
}