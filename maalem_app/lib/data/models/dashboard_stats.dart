class DashboardStats {
  final int totalBookings;
  final int completedBookings;
  final int pendingBookings;
  final int cancelledBookings;
  final double averageRating;
  final int totalReviews;
  final double totalRevenue;
  final int totalComplaints;
  final List<MonthlyData> monthlyRevenue;
  final List<MonthlyData> monthlyBookings;

  DashboardStats({
    required this.totalBookings,
    required this.completedBookings,
    required this.pendingBookings,
    required this.cancelledBookings,
    required this.averageRating,
    required this.totalReviews,
    required this.totalRevenue,
    required this.totalComplaints,
    required this.monthlyRevenue,
    required this.monthlyBookings,
  });

  factory DashboardStats.empty() => DashboardStats(
    totalBookings: 0,
    completedBookings: 0,
    pendingBookings: 0,
    cancelledBookings: 0,
    averageRating: 0,
    totalReviews: 0,
    totalRevenue: 0,
    totalComplaints: 0,
    monthlyRevenue: [],
    monthlyBookings: [],
  );
}

class MonthlyData {
  final String month;  // ex: "Jan", "Fév", etc.
  final double value;

  MonthlyData({required this.month, required this.value});
}