import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/data/models/artisan_model.dart';
import 'package:maalem_app/data/services/artisan_service.dart';
import 'package:maalem_app/presentation/dashboard/screens/dashboard_screen.dart';
import 'package:maalem_app/presentation/dashboard/widgets/star_rating_widget.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:maalem_app/shared/widgets/maalem_app_bar.dart';
import 'package:maalem_app/shared/widgets/profile_avatar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteArtisansScreen extends StatefulWidget {
  const FavoriteArtisansScreen({super.key});

  @override
  State<FavoriteArtisansScreen> createState() => _FavoriteArtisansScreenState();
}

class _FavoriteArtisansScreenState extends State<FavoriteArtisansScreen> {
  final ArtisanService _artisanService = ArtisanService();
  bool _isLoading = true;
  String? _error;
  List<ArtisanModel> _favorites = const [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  String _favoritesKey(int? clientId) =>
      'favorite_artisans_${clientId ?? 'guest'}';

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clientId = context.read<AuthProvider>().user?.id;
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds =
          (prefs.getStringList(_favoritesKey(clientId)) ?? const [])
              .map(int.tryParse)
              .whereType<int>()
              .toSet();

      final artisans = await _artisanService.fetchAllArtisans();
      if (!mounted) return;

      setState(() {
        _favorites = artisans
            .where((artisan) => favoriteIds.contains(artisan.id))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(ArtisanModel artisan) async {
    final clientId = context.read<AuthProvider>().user?.id;
    final prefs = await SharedPreferences.getInstance();
    final key = _favoritesKey(clientId);
    final ids = prefs.getStringList(key) ?? <String>[];
    ids.remove('${artisan.id}');
    await prefs.setStringList(key, ids);
    if (!mounted) return;

    setState(() {
      _favorites = _favorites.where((item) => item.id != artisan.id).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${artisan.fullName} retire des favoris')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: MaalemAppBar(
        title: 'Mes Favoris',
        subtitle: 'Artisans sauvegardés',
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _loadFavorites,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            )
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadFavorites)
              : _favorites.isEmpty
                  ? const _EmptyFavorites()
                  : RefreshIndicator(
                      color: AppColors.teal,
                      onRefresh: _loadFavorites,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favorites.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final artisan = _favorites[index];
                          return _FavoriteArtisanCard(
                            artisan: artisan,
                            onOpen: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DashboardScreen(
                                    artisanId: artisan.id,
                                    artisan: artisan,
                                  ),
                                ),
                              ).then((_) => _loadFavorites());
                            },
                            onRemove: () => _removeFavorite(artisan),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _FavoriteArtisanCard extends StatelessWidget {
  final ArtisanModel artisan;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _FavoriteArtisanCard({
    required this.artisan,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                name: artisan.fullName,
                imageUrl: artisan.profileImage,
                size: 62,
                borderRadius: 16,
                backgroundColor: AppColors.navy,
                textStyle: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            artisan.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Retirer des favoris',
                          onPressed: onRemove,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      artisan.speciality,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StarRatingWidget(
                          rating: artisan.averageRating ?? artisan.rating ?? 0,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(artisan.averageRating ?? artisan.rating ?? 0).toStringAsFixed(1)}'
                          ' (${artisan.reviewCount ?? 0} avis)',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (artisan.city.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textGrey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              artisan.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, color: AppColors.teal, size: 52),
            const SizedBox(height: 14),
            const Text(
              'Aucun artisan favori',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoute un artisan avec le coeur depuis son profil.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGrey.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.navy),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
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
}
