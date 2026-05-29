import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/data/models/artisan_model.dart';
import 'package:maalem_app/data/services/api_client.dart';
import 'package:maalem_app/data/services/dashboard_service.dart';
import 'package:maalem_app/presentation/dashboard/widgets/star_rating_widget.dart';
import 'package:maalem_app/presentation/dashboard/widgets/stats_card.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  final int artisanId;
  final ArtisanModel? artisan;

  const DashboardScreen({
    super.key,
    required this.artisanId,
    this.artisan,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  String? _resolveImageUrl(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    final value = source.trim();
    if (value.startsWith('http') || value.startsWith('data:')) return value;
    if (value.startsWith('/')) return '${ApiClient.baseUrl}$value';
    return '${ApiClient.baseUrl}/$value';
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }

      final service = DashboardService(token: token);
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
    final authUser = context.watch<AuthProvider>().user;
    final isOwnDashboard = authUser?.id == widget.artisanId;

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: Text(isOwnDashboard ? 'Mon Dashboard' : 'Profil Artisan'),
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
                      _buildProfileHeader(context),
                      const SizedBox(height: 18),
                      _buildStats(isOwnDashboard),
                      if (isOwnDashboard) ...[
                        const SizedBox(height: 24),
                        _buildRecentBookings(),
                      ],
                      const SizedBox(height: 24),
                      _buildRecentReviews(isOwnDashboard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStats(bool isOwnDashboard) {
    return Column(
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
        if (isOwnDashboard) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  icon: Icons.pending_actions,
                  title: 'En attente',
                  value: '${_dashboardData!['pendingBookings'] ?? 0}',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  icon: Icons.check_circle_outline,
                  title: 'Confirmées',
                  value: '${_dashboardData!['confirmedBookings'] ?? 0}',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRecentBookings() {
    final bookings = (_dashboardData!['recentBookings'] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dernières commandes clients',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        if (bookings.isEmpty)
          _buildEmptyBox('Aucune commande pour le moment')
        else
          ...bookings.map(_buildBookingCard),
      ],
    );
  }

  Widget _buildBookingCard(dynamic item) {
    final booking = item is Map ? item : const {};
    final status = '${booking['status'] ?? 'pending'}';
    final price = _toDouble(booking['agreed_price']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${booking['client_name'] ?? 'Client'}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            if ((booking['description'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${booking['description']}',
                style: const TextStyle(color: AppColors.textGrey),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              price == null
                  ? 'Prix non confirmé'
                  : 'Prix confirmé: ${price.toStringAsFixed(0)} MAD',
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReviews(bool isOwnDashboard) {
    final reviews = (_dashboardData!['recentReviews'] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isOwnDashboard ? 'Derniers avis reçus' : 'Avis clients',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          _buildEmptyBox('Aucun avis pour le moment')
        else
          ...reviews.map(_buildReviewCard),
      ],
    );
  }

  Widget _buildReviewCard(dynamic item) {
    final review = item is Map ? item : const {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review['client_name'] ?? 'Client',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                StarRatingWidget(
                  rating: _toDouble(review['rating']) ?? 0,
                  size: 18,
                ),
              ],
            ),
            if (review['comment'] != null &&
                review['comment'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review['comment'],
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textGrey),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final ownProfile =
        authUser?.id == widget.artisanId ? authUser?.profile : null;
    final artisan = widget.artisan;

    final fullName = artisan?.fullName ?? authUser?.fullName ?? 'Artisan';
    final specialty = artisan?.speciality.isNotEmpty == true
        ? artisan!.speciality
        : ownProfile?.specialty ?? 'Specialite non renseignee';
    final description = artisan?.bio?.trim().isNotEmpty == true
        ? artisan!.bio!.trim()
        : ownProfile?.description?.trim().isNotEmpty == true
            ? ownProfile!.description!.trim()
            : 'Aucune description pour le moment.';
    final hourlyRate = artisan?.hourlyRate ?? ownProfile?.hourlyRate;
    final imageUrl = _resolveImageUrl(artisan?.profileImage ?? authUser?.photoUrl);
    final portfolioImages =
        (artisan?.portfolioImages.isNotEmpty == true
                ? artisan!.portfolioImages
                : ownProfile?.portfolioImages ?? const <String>[])
            .map(_resolveImageUrl)
            .whereType<String>()
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.navy,
                backgroundImage:
                    imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null
                    ? Text(
                        _initials(fullName),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textGrey,
              height: 1.4,
            ),
          ),
          if (hourlyRate != null) ...[
            const SizedBox(height: 14),
            Text(
              'Tarif indicatif: ${hourlyRate.toStringAsFixed(0)} MAD / h',
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (portfolioImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: portfolioImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      portfolioImages[index],
                      width: 112,
                      height: 86,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(status);
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    if (status == 'accepted') return 'Confirmée';
    if (status == 'completed') return 'Terminée';
    if (status == 'cancelled') return 'Annulée';
    if (status == 'rejected') return 'Refusée';
    return 'En attente';
  }

  Color _statusColor(String status) {
    if (status == 'accepted') return Colors.green;
    if (status == 'completed') return AppColors.teal;
    if (status == 'cancelled' || status == 'rejected') return Colors.red;
    return Colors.orange;
  }
}
