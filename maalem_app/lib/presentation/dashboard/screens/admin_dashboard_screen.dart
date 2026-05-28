import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/data/services/dashboard_service.dart';
import 'package:maalem_app/presentation/dashboard/screens/complaint_screen.dart';
import 'package:maalem_app/presentation/dashboard/widgets/stats_card.dart';
import 'package:maalem_app/presentation/dashboard/widgets/star_rating_widget.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }

      final service = DashboardService(token: token);
      final data = await service.getAdminDashboard();

      if (mounted) {
        setState(() => _dashboardData = data);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
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
        title: const Text('Dashboard Admin'),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Erreur de chargement: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.navy),
          ),
        ),
      );
    }

    final data = _dashboardData ?? const <String, dynamic>{};
    final topArtisans = (data['topArtisans'] as List?) ?? const [];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppColors.teal,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  icon: Icons.rate_review,
                  title: 'Avis',
                  value: '${data['totalReviews'] ?? 0}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  icon: Icons.report_problem_outlined,
                  title: 'Réclamations',
                  value: '${data['totalComplaints'] ?? 0}',
                  color: AppColors.lightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StatsCard(
            icon: Icons.pending_actions,
            title: 'Réclamations ouvertes',
            value: '${data['openComplaints'] ?? 0}',
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ComplaintScreen(
                      bookingId: 0,
                      artisanId: 0,
                      isAdmin: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Gérer les réclamations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Top artisans',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (topArtisans.isEmpty)
            const Text(
              'Aucun avis pour le moment',
              style: TextStyle(color: AppColors.textGrey),
            )
          else
            ...topArtisans.map(_buildTopArtisanCard),
        ],
      ),
    );
  }

  Widget _buildTopArtisanCard(dynamic item) {
    final artisan = item is Map ? item : const {};
    final average = double.tryParse('${artisan['average'] ?? 0}') ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${artisan['full_name'] ?? 'Artisan'}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StarRatingWidget(rating: average, size: 18),
                ],
              ),
            ),
            Text(
              '${artisan['review_count'] ?? 0} avis',
              style: const TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
