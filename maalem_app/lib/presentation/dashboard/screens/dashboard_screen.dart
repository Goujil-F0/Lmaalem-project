import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/data/models/artisan_model.dart';
import 'package:maalem_app/data/services/api_client.dart';
import 'package:maalem_app/data/services/dashboard_service.dart';
import 'package:maalem_app/presentation/booking/screens/booking_screen.dart';
import 'package:maalem_app/presentation/dashboard/widgets/star_rating_widget.dart';
import 'package:maalem_app/presentation/dashboard/widgets/stats_card.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isFavorite = false;
  bool _isRechargingWallet = false;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedCalendarDate;
  int _dashboardSectionIndex = 0;

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
    _loadFavoriteStatus();
  }

  String _favoritesKey(int? clientId) =>
      'favorite_artisans_${clientId ?? 'guest'}';

  Future<void> _loadFavoriteStatus() async {
    final clientId = context.read<AuthProvider>().user?.id;
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey(clientId)) ?? const [];
    if (mounted) {
      setState(() => _isFavorite = favorites.contains('${widget.artisanId}'));
    }
  }

  Future<void> _toggleFavorite() async {
    final clientId = context.read<AuthProvider>().user?.id;
    final prefs = await SharedPreferences.getInstance();
    final key = _favoritesKey(clientId);
    final favorites = prefs.getStringList(key) ?? <String>[];
    final artisanId = '${widget.artisanId}';
    final nextValue = !favorites.contains(artisanId);

    if (nextValue) {
      favorites.add(artisanId);
    } else {
      favorites.remove(artisanId);
    }

    await prefs.setStringList(key, favorites);
    if (!mounted) return;

    setState(() => _isFavorite = nextValue);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nextValue
              ? 'Artisan ajouté aux favoris'
              : 'Artisan retiré des favoris',
        ),
      ),
    );
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authUser = context.read<AuthProvider>().user;

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
        });
      }
    } catch (e) {
      if (mounted) {
        if (widget.artisan != null) {
          setState(() {
            _dashboardData = _fallbackDashboardData(widget.artisan!);
            _error = null;
          });
        } else if (authUser != null && authUser.id == widget.artisanId) {
          setState(() {
            _dashboardData = _fallbackDashboardDataFromUser(authUser);
            _error = null;
          });
        } else {
          setState(() => _error = e.toString());
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _fallbackDashboardDataFromUser(dynamic user) {
    final profile = user.profile;
    return {
      'averageRating': profile?.averageRating ?? 0,
      'totalReviews': 0,
      'artisanProfile': {
        'id': user.id,
        'full_name': user.fullName,
        'email': user.email,
        'phone': user.phone,
        'city': user.city,
        'speciality': profile?.specialty ?? 'Artisan général',
        'bio': profile?.description,
        'hourly_rate': profile?.hourlyRate,
        'is_available': profile?.isAvailable ?? true,
        'profile_image': user.photoUrl,
        'portfolio_images': profile?.portfolioImages ?? const <String>[],
      },
      'recentReviews': const [],
      'pendingBookings': 0,
      'confirmedBookings': 0,
      'cancelledBookings': 0,
      'recentBookings': const [],
    };
  }

  Map<String, dynamic> _fallbackDashboardData(ArtisanModel artisan) {
    return {
      'averageRating': artisan.averageRating ?? artisan.rating ?? 0,
      'totalReviews': artisan.reviewCount ?? 0,
      'artisanProfile': {
        'id': artisan.id,
        'full_name': artisan.fullName,
        'email': artisan.email,
        'phone': artisan.phone,
        'city': artisan.city,
        'speciality': artisan.speciality,
        'bio': artisan.bio,
        'hourly_rate': artisan.hourlyRate,
        'is_available': artisan.isAvailable,
        'profile_image': artisan.profileImage,
        'portfolio_images': artisan.portfolioImages,
      },
      'recentReviews': const [],
      'pendingBookings': 0,
      'confirmedBookings': 0,
      'cancelledBookings': 0,
      'recentBookings': const [],
    };
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final isOwnDashboard = authUser?.id == widget.artisanId;

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: Text(isOwnDashboard ? 'Mon Dashboard' : 'Profil Artisan'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.beige,
        foregroundColor: AppColors.navy,
        titleTextStyle: const TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
        actions: [
          if (!isOwnDashboard)
            IconButton(
              tooltip:
                  _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? AppColors.teal : AppColors.navy,
              ),
            ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            )
          : _error != null || _dashboardData == null
              ? _buildErrorState()
              : isOwnDashboard
                  ? _buildOwnDashboard()
                  : _buildClientProfileDashboard(context),
    );
  }

  Widget _buildOwnDashboard() {
    final authUser = context.watch<AuthProvider>().user;
    return RefreshIndicator(
      color: AppColors.teal,
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bonjour,",
              style: TextStyle(
                color: AppColors.textGrey.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              "${authUser?.fullName ?? 'Artisan'}",
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 18),
            _buildDashboardSummary(),
            const SizedBox(height: 18),
            _buildDashboardSections(),
          ],
        ),
      ),
    );
  }

  Widget _buildClientProfileDashboard(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.teal,
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 20),
            _buildStats(false),
            const SizedBox(height: 24),
            _buildRecentReviews(false),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSections() {
    final sections = [
      (
        icon: Icons.calendar_month_rounded,
        label: 'Agenda',
        content: _buildCalendar(),
      ),
      (
        icon: Icons.rate_review_rounded,
        label: 'Avis',
        content: _buildRecentReviews(true),
      ),
      (
        icon: Icons.handyman_rounded,
        label: 'Travaux',
        content: _buildRecentBookings(),
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.beige.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: List.generate(sections.length, (index) {
                final section = sections[index];
                return Expanded(
                  child: _DashboardSectionTab(
                    icon: section.icon,
                    label: section.label,
                    isSelected: _dashboardSectionIndex == index,
                    onTap: () {
                      setState(() => _dashboardSectionIndex = index);
                    },
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
            child: sections[_dashboardSectionIndex].content,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSummary() {
    final wallet = _dashboardData!['wallet'] is Map
        ? _dashboardData!['wallet'] as Map
        : const {};
    final balance = _toDouble(wallet['balance']) ?? 0;
    final expectedCommission = _toDouble(wallet['expectedCommission']) ?? 0;
    final canAcceptBookings = wallet['canAcceptBookings'] == true;
    final pendingBookings = _dashboardData!['pendingBookings'] ?? 0;
    final confirmedBookings = _dashboardData!['confirmedBookings'] ?? 0;
    final totalReviews = _dashboardData!['totalReviews'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF153F6F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tableau de bord',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Suivi rapide de votre activité',
                      style: TextStyle(
                        color: AppColors.lightBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (canAcceptBookings ? AppColors.teal : AppColors.lightBlue)
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  canAcceptBookings ? 'ACTIF' : 'À RECHARGER',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.35,
            children: [
              _SummaryMetricTile(
                label: 'Wallet',
                value: '${balance.toStringAsFixed(0)} MAD',
                icon: Icons.account_balance_wallet_rounded,
              ),
              _SummaryMetricTile(
                label: 'En attente',
                value: '$pendingBookings',
                icon: Icons.pending_actions_rounded,
              ),
              _SummaryMetricTile(
                label: 'Confirmés',
                value: '$confirmedBookings',
                icon: Icons.task_alt_rounded,
              ),
              _SummaryMetricTile(
                label: 'Commission',
                value: '${expectedCommission.toStringAsFixed(0)} MAD',
                icon: Icons.percent_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.rate_review_rounded,
                        color: AppColors.navy,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '$totalReviews avis clients',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _isRechargingWallet ? null : () => _rechargeWallet(100),
                  icon: _isRechargingWallet
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.navy,
                            ),
                          ),
                        )
                      : const Icon(Icons.credit_card_rounded, size: 16),
                  label: const Text('Recharger'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.navy,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Actualiser',
                onPressed: _isLoading ? null : _loadDashboard,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                color: AppColors.white,
                style: IconButton.styleFrom(
                  fixedSize: const Size(46, 46),
                  backgroundColor: AppColors.white.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          if (!canAcceptBookings) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.lightBlue.withValues(alpha: 0.22),
                ),
              ),
              child: const Text(
                'Rechargez votre wallet pour accepter de nouvelles missions.',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
              color: AppColors.teal,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              _error ?? 'Erreur de chargement',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(bool isOwnDashboard) {
    final cards = <Widget>[
      StatsCard(
        icon: Icons.star_rounded,
        title: 'Note Moyenne',
        value: '${_dashboardData!['averageRating'] ?? 0}',
      ),
      StatsCard(
        icon: Icons.rate_review_rounded,
        title: 'Total Avis',
        value: '${_dashboardData!['totalReviews'] ?? 0}',
        color: AppColors.lightBlue,
      ),
      if (isOwnDashboard)
        StatsCard(
          icon: Icons.pending_actions_rounded,
          title: 'En attente',
          value: '${_dashboardData!['pendingBookings'] ?? 0}',
          color: AppColors.lightBlue,
        ),
      if (isOwnDashboard)
        StatsCard(
          icon: Icons.check_circle_outline_rounded,
          title: 'Confirmées',
          value: '${_dashboardData!['confirmedBookings'] ?? 0}',
          color: AppColors.teal,
        ),
      if (isOwnDashboard)
        StatsCard(
          icon: Icons.cancel_outlined,
          title: 'Annulées',
          value: '${_dashboardData!['cancelledBookings'] ?? 0}',
          color: AppColors.textGrey,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOwnDashboard) ...[
          const Text(
            'Vue d\'ensemble',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
        ],
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isOwnDashboard ? 1.28 : 1.55,
          children: cards,
        ),
      ],
    );
  }

  Widget _buildRecentBookings() {
    final bookings = (_dashboardData!['recentBookings'] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.handyman_rounded,
          title: 'Travaux récents',
        ),
        const SizedBox(height: 14),
        if (bookings.isEmpty)
          _buildEmptyBox('Aucune commande pour le moment')
        else
          ...bookings.map(_buildBookingCard),
      ],
    );
  }

  Future<void> _rechargeWallet(double amount) async {
    setState(() => _isRechargingWallet = true);

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }

      final service = DashboardService(token: token);
      await service.rechargeWallet(widget.artisanId, amount);
      await _loadDashboard();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wallet rechargé de ${amount.toStringAsFixed(0)} MAD'),
          backgroundColor: AppColors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRechargingWallet = false);
    }
  }

  Widget _buildWallet() {
    final wallet = _dashboardData!['wallet'] is Map
        ? _dashboardData!['wallet'] as Map
        : const {};
    final balance = _toDouble(wallet['balance']) ?? 0;
    final grossCash = _toDouble(wallet['grossCash']) ?? 0;
    final commissionDebited = _toDouble(wallet['commissionDebited']) ?? 0;
    final expectedCommission = _toDouble(wallet['expectedCommission']) ?? 0;
    final canAcceptBookings = wallet['canAcceptBookings'] == true;
    final statusColor = canAcceptBookings ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF1B4E7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.credit_card_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Wallet Maalem',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  canAcceptBookings ? 'Actif' : 'À recharger',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${balance.toStringAsFixed(0)} MAD',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Crédits disponibles pour accepter les missions',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.65),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _WalletMetric(
                  icon: Icons.payments_outlined,
                  label: 'Cash encaissé',
                  value: '${grossCash.toStringAsFixed(0)} MAD',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WalletMetric(
                  icon: Icons.percent_rounded,
                  label: 'Commissions payées',
                  value: '${commissionDebited.toStringAsFixed(0)} MAD',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WalletMetric(
            icon: Icons.pending_actions_outlined,
            label: 'Commission prévue sur les missions en cours',
            value: '${expectedCommission.toStringAsFixed(0)} MAD',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRechargingWallet
                      ? null
                      : () => _rechargeWallet(100),
                  icon: _isRechargingWallet
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                        )
                      : const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Recharger 100 MAD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Recharger 200 MAD',
                onPressed:
                    _isRechargingWallet ? null : () => _rechargeWallet(200),
                icon: const Icon(Icons.add_rounded),
                color: AppColors.white,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.white.withValues(alpha: 0.12),
                  fixedSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mail_rounded,
                  color: AppColors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Messagerie',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LIVE ACTIVE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              '${_dashboardData?['unreadMessages'] ?? 0} ',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Center(
            child: Text(
              'Messages non lus',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Naviguer vers messagerie (géré par Samir)
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Voir les messages'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final bookings = (_dashboardData!['upcomingBookings'] as List?) ?? const [];
    final markedDays = <DateTime, List<Map<dynamic, dynamic>>>{};

    for (final item in bookings) {
      if (item is! Map) continue;
      final date = DateTime.tryParse('${item['booking_date'] ?? ''}');
      if (date == null) continue;
      final key = DateTime(date.year, date.month, date.day);
      markedDays.putIfAbsent(key, () => []).add(item);
    }

    final days = _calendarDays(_calendarMonth);
    final selectedKey = _selectedCalendarDate == null
        ? null
        : DateTime(
            _selectedCalendarDate!.year,
            _selectedCalendarDate!.month,
            _selectedCalendarDate!.day,
          );
    final selectedBookings = selectedKey == null
        ? const <Map<dynamic, dynamic>>[]
        : markedDays[selectedKey] ?? const <Map<dynamic, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                icon: Icons.calendar_month_rounded,
                title: 'Calendrier',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${bookings.length} RDV',
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.teal.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.03),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Mois précédent',
                      onPressed: () {
                        setState(() {
                          _calendarMonth = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month - 1,
                          );
                          _selectedCalendarDate = null;
                        });
                      },
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: AppColors.navy,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppColors.beige.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _monthLabel(_calendarMonth),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Mois suivant',
                      onPressed: () {
                        setState(() {
                          _calendarMonth = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month + 1,
                          );
                          _selectedCalendarDate = null;
                        });
                      },
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: AppColors.navy,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppColors.beige.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    _WeekdayLabel('L'),
                    _WeekdayLabel('M'),
                    _WeekdayLabel('M'),
                    _WeekdayLabel('J'),
                    _WeekdayLabel('V'),
                    _WeekdayLabel('S'),
                    _WeekdayLabel('D'),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.08,
                  ),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isCurrentMonth = day.month == _calendarMonth.month;
                    final key = DateTime(day.year, day.month, day.day);
                    final dayBookings = markedDays[key] ?? const [];
                    final hasBooking = dayBookings.isNotEmpty;
                    final hasPriority =
                        dayBookings.any((b) => b['status'] == 'accepted');
                    final isSelected = selectedKey == key;

                    return _CalendarDayCell(
                      day: day,
                      isCurrentMonth: isCurrentMonth,
                      hasBooking: hasBooking,
                      hasPriority: hasPriority,
                      isSelected: isSelected,
                      count: dayBookings.length,
                      onTap: hasBooking
                          ? () => setState(() => _selectedCalendarDate = key)
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (bookings.isEmpty)
          _buildEmptyBox('Aucun rendez-vous planifié')
        else if (selectedBookings.isEmpty)
          _buildEmptyBox('Sélectionnez une date avec badge pour voir les rendez-vous')
        else
          ...selectedBookings.map(_buildCalendarAppointment),
      ],
    );
  }

  Widget _buildCalendarAppointment(dynamic item) {
    final booking = item is Map ? item : const {};
    final status = '${booking['status'] ?? 'pending'}';
    final isPriority = status == 'accepted';
    final date = DateTime.tryParse('${booking['booking_date'] ?? ''}');
    final price = _toDouble(booking['agreed_price']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isPriority ? Colors.green : Colors.orange)
              .withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isPriority ? Colors.green : Colors.orange)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPriority ? Icons.priority_high_rounded : Icons.schedule_rounded,
                color: isPriority ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      _StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date == null
                        ? 'Date non définie'
                        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  if ((booking['description'] ?? '')
                      .toString()
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${booking['description']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (price != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.beige.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${price.toStringAsFixed(0)} MAD',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _calendarDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final start = firstDay.subtract(Duration(days: firstDay.weekday - 1));

    return List.generate(42, (index) => start.add(Duration(days: index)));
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildBookingCard(dynamic item) {
    final booking = item is Map ? item : const {};
    final status = '${booking['status'] ?? 'pending'}';
    final price = _toDouble(booking['agreed_price']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: AppColors.teal, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${booking['client_name'] ?? 'Client'}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            if ((booking['description'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '${booking['description']}',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.beige.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                price == null
                    ? 'Prix non confirmé'
                    : 'Montant: ${price.toStringAsFixed(0)} MAD',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
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
        _SectionTitle(
          icon: Icons.rate_review_rounded,
          title: isOwnDashboard ? 'Derniers avis reçus' : 'Avis clients',
        ),
        const SizedBox(height: 14),
        if (reviews.isEmpty)
          _buildEmptyBox('Aucun avis pour le moment')
        else
          ...reviews.map(_buildReviewCard),
      ],
    );
  }

  Widget _buildReviewCard(dynamic item) {
    final review = item is Map ? item : const {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.rate_review_rounded, color: AppColors.teal, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      review['client_name'] ?? 'Client',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.navy,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                StarRatingWidget(
                  rating: _toDouble(review['rating']) ?? 0,
                  size: 16,
                ),
              ],
            ),
            if (review['comment'] != null &&
                review['comment'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.beige.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  review['comment'],
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final isOwnDashboard = authUser?.id == widget.artisanId;
    final ownProfile =
        authUser?.id == widget.artisanId ? authUser?.profile : null;
    final artisan = widget.artisan;
    final dashboardProfile = _dashboardData?['artisanProfile'] is Map
        ? _dashboardData!['artisanProfile'] as Map
        : const {};

    final fullName = artisan?.fullName ??
        dashboardProfile['full_name'] ??
        authUser?.fullName ??
        'Artisan';
    final specialty = artisan?.speciality.isNotEmpty == true
        ? artisan!.speciality
        : dashboardProfile['speciality'] ??
            ownProfile?.specialty ??
            'Spécialité non renseignée';
    final description = artisan?.bio?.trim().isNotEmpty == true
        ? artisan!.bio!.trim()
        : dashboardProfile['bio']?.toString().trim().isNotEmpty == true
            ? dashboardProfile['bio'].toString().trim()
            : ownProfile?.description?.trim().isNotEmpty == true
                ? ownProfile!.description!.trim()
                : 'Aucune description pour le moment.';
    final hourlyRate = artisan?.hourlyRate ??
        _toDouble(dashboardProfile['hourly_rate']) ??
        ownProfile?.hourlyRate;
    final averageRating = _toDouble(_dashboardData?['averageRating']) ??
        artisan?.averageRating ??
        artisan?.rating ??
        0;
    final totalReviews = _dashboardData?['totalReviews'] ?? 0;
    final isAvailable = artisan?.isAvailable ??
        dashboardProfile['is_available'] ??
        ownProfile?.isAvailable ??
        true;
    final phone = dashboardProfile['phone'] ?? authUser?.phone;
    final city = dashboardProfile['city'] ?? authUser?.city;
    final imageUrl = _resolveImageUrl(
      artisan?.profileImage ??
          dashboardProfile['profile_image'] ??
          authUser?.photoUrl,
    );
    final portfolioImages = (artisan?.portfolioImages.isNotEmpty == true
            ? artisan!.portfolioImages
            : _toStringList(dashboardProfile['portfolio_images']).isNotEmpty
                ? _toStringList(dashboardProfile['portfolio_images'])
                : ownProfile?.portfolioImages ?? const <String>[])
        .map(_resolveImageUrl)
        .whereType<String>()
        .toList();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (portfolioImages.isNotEmpty || imageUrl != null)
                  Image.network(
                    portfolioImages.isNotEmpty ? portfolioImages.first : imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.teal.withValues(alpha: 0.16),
                    ),
                  )
                else
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.navy,
                          AppColors.teal,
                        ],
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.navy.withValues(alpha: 0.05),
                        AppColors.navy.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: _AvailabilityBadge(isAvailable: isAvailable),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.white,
                            width: 3.5,
                          ),
                          image: imageUrl == null
                              ? null
                              : DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                ),
                        ),
                        child: imageUrl == null
                            ? Center(
                                child: Text(
                                  _initials(fullName),
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              specialty,
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ProfileInfoTile(
                        icon: Icons.star_rounded,
                        label: 'Note',
                        value: averageRating.toStringAsFixed(1),
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProfileInfoTile(
                        icon: Icons.reviews_rounded,
                        label: 'Avis',
                        value: '$totalReviews',
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProfileInfoTile(
                        icon: Icons.payments_rounded,
                        label: 'Tarif',
                        value: hourlyRate == null
                            ? '--'
                            : '${hourlyRate.toStringAsFixed(0)}',
                        color: AppColors.lightBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    StarRatingWidget(rating: averageRating, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        totalReviews == 0
                            ? 'Nouveau profil artisan'
                            : '$totalReviews avis clients',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (hourlyRate != null)
                      Text(
                        '${hourlyRate.toStringAsFixed(0)} MAD/h',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    height: 1.45,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ProfilePill(
                      icon: Icons.location_on_outlined,
                      label: city?.toString().trim().isNotEmpty == true
                          ? city.toString()
                          : 'Ville non renseignée',
                    ),
                    if (phone?.toString().trim().isNotEmpty == true)
                      _ProfilePill(
                        icon: Icons.call_rounded,
                        label: phone.toString(),
                      ),
                    _ProfilePill(
                      icon: Icons.verified_user_rounded,
                      label:
                          isAvailable ? 'Disponible pour intervention' : 'Non disponible',
                    ),
                  ],
                ),
                if (!isOwnDashboard) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(
                              artisanId: widget.artisanId,
                              artisanName: fullName,
                              hourlyRate: hourlyRate ?? 0,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text('Réserver cet artisan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
                if (portfolioImages.length > 1) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Réalisations',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: portfolioImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              portfolioImages[index],
                              width: 120,
                              height: 96,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
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

  List<String> _toStringList(dynamic value) {
    if (value is List) return value.whereType<String>().toList();
    return const [];
  }
}

class _DashboardSectionTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DashboardSectionTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.navy,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.white, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.64),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfilePill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.teal, size: 14),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.62,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStatItem extends StatelessWidget {
  final String value;
  final String label;

  const _DashboardStatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.72),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CompactStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CompactStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: 17),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.68),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;

  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? AppColors.lightBlue : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        isAvailable ? 'Disponible' : 'Indisponible',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WalletMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WalletMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.white, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.65),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String value;

  const _WeekdayLabel(this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textGrey,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final bool isCurrentMonth;
  final bool hasBooking;
  final bool hasPriority;
  final bool isSelected;
  final int count;
  final VoidCallback? onTap;

  const _CalendarDayCell({
    required this.day,
    required this.isCurrentMonth,
    required this.hasBooking,
    required this.hasPriority,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? AppColors.navy
        : hasPriority
            ? Colors.green.withValues(alpha: 0.12)
            : hasBooking
                ? AppColors.teal.withValues(alpha: 0.08)
                : Colors.transparent;
    final borderColor = isSelected
        ? AppColors.navy
        : hasPriority
            ? Colors.green.withValues(alpha: 0.3)
            : hasBooking
                ? AppColors.teal.withValues(alpha: 0.2)
                : Colors.grey.shade300;
    final textColor = isSelected
        ? AppColors.white
        : isCurrentMonth
            ? AppColors.navy
            : Colors.grey.shade400;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            if (hasBooking)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: count > 1 ? 14 : 6,
                  height: count > 1 ? 14 : 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.white
                        : hasPriority
                            ? Colors.green
                            : AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: count > 1
                      ? Center(
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: isSelected ? AppColors.navy : AppColors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.teal, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
            ),
          ),
        ),
      ],
    );
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
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    if (status == 'accepted') return 'Confirmée';
    if (status == 'paid_cash') return 'Payé cash';
    if (status == 'completed') return 'Terminée';
    if (status == 'cancelled') return 'Annulée';
    if (status == 'rejected') return 'Refusée';
    return 'En attente';
  }

  Color _statusColor(String status) {
    if (status == 'accepted') return Colors.green;
    if (status == 'paid_cash') return AppColors.lightBlue;
    if (status == 'completed') return AppColors.teal;
    if (status == 'cancelled' || status == 'rejected') return Colors.red;
    return Colors.orange;
  }
}
