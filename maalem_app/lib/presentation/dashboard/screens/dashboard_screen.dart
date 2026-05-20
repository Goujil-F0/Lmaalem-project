import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/data/services/dashboard_service.dart';
import 'package:maalem_app/presentation/dashboard/widgets/star_rating_widget.dart';
import 'package:maalem_app/presentation/dashboard/widgets/stats_card.dart';

class DashboardScreen extends StatefulWidget {
  final int artisanId;
  final String token;

  const DashboardScreen({
    super.key,
    required this.artisanId,
    required this.token,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final service = DashboardService(token: widget.token);
      final dashboardData = await service.getArtisanDashboard(widget.artisanId);
      if (mounted) {
        setState(() {
          _dashboardData = dashboardData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Mon Dashboard'),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal))
          : _dashboardData == null
              ? const Center(child: Text('Erreur de chargement'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              icon: Icons.star,
                              title: 'Note Moyenne',
                              value: '${_dashboardData!['averageRating'] ?? 0}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              icon: Icons.rate_review,
                              title: 'Total Avis',
                              value: '${_dashboardData!['totalReviews'] ?? 0}',
                              color: AppColors.lightBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Derniers avis reçus',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_dashboardData!['recentReviews'] != null)
                        ...(_dashboardData!['recentReviews'] as List).map(
                          (review) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        review['client_name'] ?? 'Client',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                      StarRatingWidget(
                                        rating: (review['rating'] ?? 0).toDouble(),
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  if (review['comment'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      review['comment'],
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
