import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/presentation/search/screens/map_screen.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:maalem_app/providers/search_provider.dart';
import 'package:provider/provider.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load artisans when home screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadArtisans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openMapWithSearch([String? query]) {
    final searchProvider = context.read<SearchProvider>();
    final searchText = (query ?? _searchController.text).trim();
    searchProvider.filterArtisans(searchText);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MapScreen(initialQuery: searchText)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        backgroundColor: AppColors.beige,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenue',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              user?.fullName ?? 'Client Lmaalem',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppColors.navy,
            child: Text(
              _initials(user?.fullName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Localisation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: AppColors.teal, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Votre localisation',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user?.city ?? 'Localisation'}, ${user?.neighborhood ?? ''}',
                          style: TextStyle(
                            color: AppColors.navy.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Consumer<SearchProvider>(
              builder: (context, provider, _) {
                final suggestions = provider.artisans.take(3).toList();

                return Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: provider.filterArtisans,
                      onSubmitted: _openMapWithSearch,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Nom, categorie ou probleme: robinet fuit...',
                        hintStyle: TextStyle(
                            color: AppColors.navy.withValues(alpha: 0.52)),
                        prefixIcon:
                            const Icon(Icons.search, color: AppColors.teal),
                        suffixIcon: IconButton(
                          onPressed: () => _openMapWithSearch(),
                          icon: const Icon(Icons.map, color: AppColors.teal),
                          tooltip: 'Voir sur la carte',
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: provider.allSpecialties
                              .contains(provider.selectedCategory)
                          ? provider.selectedCategory
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Choisir une specialite',
                        prefixIcon: const Icon(
                          Icons.work_outline,
                          color: AppColors.teal,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Toutes les specialites'),
                        ),
                        ...provider.allSpecialties.map(
                          (specialty) => DropdownMenuItem<String>(
                            value: specialty,
                            child: Text(specialty),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        final selected = value ?? '';
                        _searchController.clear();
                        if (selected.isEmpty) {
                          provider.resetFilters();
                        } else {
                          provider.filterArtisans('', category: selected);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: provider.cities.contains(provider.selectedCity)
                          ? provider.selectedCity
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Choisir une ville',
                        prefixIcon: const Icon(
                          Icons.location_city,
                          color: AppColors.teal,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Toutes les villes'),
                        ),
                        ...provider.cities.map(
                          (city) => DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        final selected = value ?? '';
                        if (selected.isEmpty) {
                          provider.filterByCity('');
                        } else {
                          provider.filterByCity(selected);
                        }
                      },
                    ),
                    if (_searchController.text.trim().isNotEmpty &&
                        suggestions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...suggestions.map(
                        (artisan) => _SearchSuggestionTile(
                          name: artisan.fullName,
                          subtitle:
                              '${artisan.speciality} - ${artisan.city.isEmpty ? 'Ville non renseignee' : artisan.city}',
                          isAvailable: artisan.isAvailable,
                          onTap: () => _openMapWithSearch(
                            _searchController.text,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Titre: Services populaires
            const Text(
              'Services populaires',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),

            // Grille de services - Dynamic based on categories
            Consumer<SearchProvider>(
              builder: (context, provider, _) {
                final categories = provider.categories;

                // Si les catégories ne sont pas chargées, afficher 4 par défaut
                final displayCategories = categories.isEmpty
                    ? [
                        'Plomberie',
                        'Électricité',
                        'Peinture',
                        'Carrelage',
                      ]
                    : categories.take(4).toList();

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  children: displayCategories
                      .map((category) => _ServiceCard(
                            label: category,
                            onTap: () {
                              // Filtrer par catégorie et aller à la carte
                              _searchController.clear();
                              provider.filterArtisans('', category: category);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MapScreen()),
                              );
                            },
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),

            // Bouton Voir sur la carte
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                ),
                icon: const Icon(Icons.map, color: Colors.white),
                label: const Text(
                  'Voir les artisans sur la carte',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Titre: Réservations récentes
            const Text(
              'Vos réservations',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 56,
                    color: AppColors.teal.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune réservation',
                    style: TextStyle(
                      color: AppColors.navy.withValues(alpha: 0.62),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commencez à chercher un artisan',
                    style: TextStyle(
                      color: AppColors.navy.withValues(alpha: 0.42),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return 'CL';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _ServiceCard extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ServiceCard({
    required this.label,
    this.onTap,
  });

  /// Génère une icône basée sur le nom du service
  IconData _getIconForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('plomb')) return Icons.water;
    if (cat.contains('électr')) return Icons.electric_bolt;
    if (cat.contains('peint')) return Icons.palette;
    if (cat.contains('maçon')) return Icons.construction;
    if (cat.contains('carrel')) return Icons.layers;
    if (cat.contains('menuiser')) return Icons.carpenter;
    if (cat.contains('climat')) return Icons.ac_unit;
    if (cat.contains('serr')) return Icons.vpn_key;
    if (cat.contains('garden') || cat.contains('jardin')) return Icons.grass;
    if (cat.contains('nettoy')) return Icons.cleaning_services;
    if (cat.contains('plátr')) return Icons.brush;
    if (cat.contains('isolation')) return Icons.layers;
    if (cat.contains('domotique')) return Icons.smart_button;
    if (cat.contains('solaire')) return Icons.solar_power;
    if (cat.contains('tv') || cat.contains('satellite')) return Icons.tv;
    if (cat.contains('rénovation') || cat.contains('renovati'))
      return Icons.build;
    if (cat.contains('étanch')) return Icons.water_damage;
    if (cat.contains('démolit') || cat.contains('demolit'))
      return Icons.delete_sweep;
    return Icons.handyman; // Default icon
  }

  @override
  Widget build(BuildContext context) {
    final displayIcon = _getIconForCategory(label);

    return GestureDetector(
      onTap: onTap ??
          () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(displayIcon, size: 40, color: AppColors.teal),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchSuggestionTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isAvailable;
  final VoidCallback onTap;

  const _SearchSuggestionTile({
    required this.name,
    required this.subtitle,
    required this.isAvailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.teal.withValues(alpha: 0.12),
          child: const Icon(Icons.handyman, color: AppColors.teal),
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isAvailable ? AppColors.teal : Colors.grey)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isAvailable ? 'Dispo' : 'Indispo',
            style: TextStyle(
              color: isAvailable ? AppColors.teal : Colors.grey.shade700,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
