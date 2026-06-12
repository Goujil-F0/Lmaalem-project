import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/data/models/artisan_model.dart';
import 'package:maalem_app/data/services/api_client.dart';
import 'package:maalem_app/data/services/dashboard_service.dart';
import 'package:maalem_app/presentation/booking/screens/booking_screen.dart';
import 'package:maalem_app/presentation/dashboard/widgets/star_rating_widget.dart';
import 'package:maalem_app/presentation/dashboard/widgets/stats_card.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:maalem_app/shared/widgets/profile_avatar.dart';
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
  String? _error;
  Map<String, dynamic>? _dashboardData;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedCalendarDate;

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
              ? 'Artisan ajoute aux favoris'
              : 'Artisan retire des favoris',
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
        'speciality': profile?.specialty ?? 'Artisan general',
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
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        actions: [
          if (!isOwnDashboard)
            IconButton(
              tooltip:
                  _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.redAccent : AppColors.white,
              ),
            ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal))
          : _error != null || _dashboardData == null
              ? _buildErrorState()
              : RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isOwnDashboard) ...[
                          _buildProfileHeader(context),
                          const SizedBox(height: 18),
                        ],
                        if (isOwnDashboard) ...[
                          _buildWallet(),
                          const SizedBox(height: 24),
                          _buildStats(isOwnDashboard),
                          const SizedBox(height: 24),
                          _buildCalendar(),
                          const SizedBox(height: 24),
                          _buildRecentReviews(isOwnDashboard),
                          const SizedBox(height: 24),
                          _buildRecentBookings(),
                        ] else ...[
                          _buildStats(isOwnDashboard),
                          const SizedBox(height: 24),
                          _buildRecentReviews(isOwnDashboard),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.signal_wifi_statusbar_connected_no_internet_4_outlined,
              color: AppColors.teal,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Erreur de chargement',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.navy),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.white,
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
        icon: Icons.star,
        title: 'Note Moyenne',
        value: '${_dashboardData!['averageRating'] ?? 0}',
      ),
      StatsCard(
        icon: Icons.rate_review,
        title: 'Total Avis',
        value: '${_dashboardData!['totalReviews'] ?? 0}',
        color: AppColors.lightBlue,
      ),
      if (isOwnDashboard)
        StatsCard(
          icon: Icons.pending_actions,
          title: 'En attente',
          value: '${_dashboardData!['pendingBookings'] ?? 0}',
          color: Colors.orange,
        ),
      if (isOwnDashboard)
        StatsCard(
          icon: Icons.check_circle_outline,
          title: 'Confirmées',
          value: '${_dashboardData!['confirmedBookings'] ?? 0}',
          color: Colors.green,
        ),
      if (isOwnDashboard)
        StatsCard(
          icon: Icons.cancel_outlined,
          title: 'Annulées',
          value: '${_dashboardData!['cancelledBookings'] ?? 0}',
          color: Colors.redAccent,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOwnDashboard) ...[
          const Text(
            'Vue d\'ensemble',
            style: TextStyle(
              fontSize: 20,
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
          icon: Icons.handyman_outlined,
          title: 'Travaux récents',
        ),
        const SizedBox(height: 12),
        if (bookings.isEmpty)
          _buildEmptyBox('Aucune commande pour le moment')
        else
          ...bookings.map(_buildBookingCard),
      ],
    );
  }

  Widget _buildWallet() {
    final wallet = _dashboardData!['wallet'] is Map
        ? _dashboardData!['wallet'] as Map
        : const {};
    final received = _toDouble(wallet['received']) ?? 0;
    final expected = _toDouble(wallet['expected']) ?? 0;
    final balance = _toDouble(wallet['balance']) ?? received;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8B45D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: AppColors.navy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Wallet',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'MAD',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${received.toStringAsFixed(0)} MAD',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Montant reçu',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _WalletMetric(
                  icon: Icons.account_balance_outlined,
                  label: 'Solde',
                  value: '${balance.toStringAsFixed(0)} MAD',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WalletMetric(
                  icon: Icons.trending_up,
                  label: 'À venir',
                  value: '${expected.toStringAsFixed(0)} MAD',
                ),
              ),
            ],
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
        const _SectionTitle(
          icon: Icons.calendar_month_outlined,
          title: 'Calendrier',
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.06),
                blurRadius: 14,
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
                    icon: const Icon(Icons.chevron_left),
                    color: AppColors.navy,
                  ),
                  Expanded(
                    child: Text(
                      _monthLabel(_calendarMonth),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 18,
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
                    icon: const Icon(Icons.chevron_right),
                    color: AppColors.navy,
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
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
        const SizedBox(height: 12),
        if (bookings.isEmpty)
          _buildEmptyBox('Aucun rendez-vous à prioriser')
        else if (selectedBookings.isEmpty)
          _buildEmptyBox('Touchez une date marquée pour voir les rendez-vous')
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isPriority ? Colors.green : Colors.orange)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPriority ? Icons.priority_high : Icons.schedule,
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
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                  ],
                  if (price != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${price.toStringAsFixed(0)} MAD',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
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
        _SectionTitle(
          icon: Icons.rate_review_outlined,
          title: isOwnDashboard ? 'Derniers avis reçus' : 'Avis clients',
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
            'Specialite non renseignee';
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
    final imageSource = isOwnDashboard
        ? authUser?.photoUrl ?? dashboardProfile['profile_image'] ?? artisan?.profileImage
        : artisan?.profileImage ?? dashboardProfile['profile_image'] ?? authUser?.photoUrl;
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                name: fullName,
                imageUrl: imageSource?.toString(),
                size: 72,
                borderRadius: 18,
                backgroundColor: AppColors.white.withValues(alpha: 0.12),
                textStyle: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AvailabilityBadge(isAvailable: isAvailable),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                StarRatingWidget(rating: averageRating, size: 20),
                const SizedBox(width: 8),
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '($totalReviews avis)',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hourlyRate != null)
                  Text(
                    '${hourlyRate.toStringAsFixed(0)} MAD/h',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.82),
              height: 1.4,
            ),
          ),
          if (!isOwnDashboard) ...[
            const SizedBox(height: 16),
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
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Réserver cet artisan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          if (portfolioImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Travaux réalisés',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
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

  List<String> _toStringList(dynamic value) {
    if (value is List) return value.whereType<String>().toList();
    return const [];
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;

  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? AppColors.lightBlue : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isAvailable ? 'Disponible' : 'Indisponible',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.white, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
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
            ? Colors.green.withValues(alpha: 0.14)
            : hasBooking
                ? AppColors.teal.withValues(alpha: 0.13)
                : Colors.transparent;
    final borderColor = isSelected
        ? AppColors.navy
        : hasPriority
            ? Colors.green
            : hasBooking
                ? AppColors.teal
                : Colors.grey.shade300;
    final textColor = isSelected
        ? AppColors.white
        : isCurrentMonth
            ? AppColors.navy
            : Colors.grey.shade400;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (hasBooking)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: count > 1 ? 16 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.white
                        : hasPriority
                            ? Colors.green
                            : AppColors.teal,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: count > 1
                      ? Center(
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.navy
                                  : AppColors.white,
                              fontSize: 7,
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.teal, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
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
