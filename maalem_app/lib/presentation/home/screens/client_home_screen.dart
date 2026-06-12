import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/presentation/search/screens/map_screen.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:maalem_app/providers/search_provider.dart';
import 'package:maalem_app/shared/widgets/profile_avatar.dart';
import 'package:provider/provider.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
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
    super.dispose();
  }

  void _openMapWithSearch([String? query]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapScreen()),
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
          child: ProfileAvatar(
            name: user?.fullName ?? 'Client Lmaalem',
            imageUrl: user?.photoUrl,
            size: 40,
            backgroundColor: AppColors.navy,
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
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
                  const Icon(
                    Icons.location_on,
                    color: AppColors.teal,
                    size: 28,
                  ),
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Specialty Filter
                    DropdownButtonFormField<String>(
<<<<<<< HEAD
                      initialValue: provider.allSpecialties.contains(
                        provider.selectedCategory,
                      )
=======
                      initialValue: provider.allSpecialties
                              .contains(provider.selectedCategory)
>>>>>>> origin/feature/wissal-avis-dashboard-reclamations
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
                        if (selected.isEmpty) {
                          provider.filterByCategory('');
                        } else {
                          provider.filterByCategory(selected);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // City Filter
                    DropdownButtonFormField<String>(
<<<<<<< HEAD
                      initialValue:
                          provider.cities.contains(provider.selectedCity)
                              ? provider.selectedCity
                              : null,
=======
                      initialValue: provider.cities.contains(provider.selectedCity)
                          ? provider.selectedCity
                          : null,
>>>>>>> origin/feature/wissal-avis-dashboard-reclamations
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
                        provider.filterByCity(selected);
                      },
                    ),
                    const SizedBox(height: 12),
                    // Average Rating Filter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.navy.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Note minimale',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${provider.minRating.toStringAsFixed(1)} ★',
                                  style: const TextStyle(
                                    color: AppColors.teal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: provider.minRating,
                            onChanged: provider.filterByMinRating,
                            min: 0,
                            max: 5,
                            divisions: 10,
                            activeColor: AppColors.teal,
                            inactiveColor: AppColors.navy.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Proximity/Distance Filter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.navy.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Proximité',
                                style: TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${provider.maxDistanceKm.toStringAsFixed(0)} km',
                                  style: const TextStyle(
                                    color: AppColors.teal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: provider.maxDistanceKm,
                            onChanged: provider.setMaxDistanceKm,
                            min: 1,
                            max: 80,
                            divisions: 79,
                            activeColor: AppColors.teal,
                            inactiveColor: AppColors.navy.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Availability Filter
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.navy.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Disponibilité',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _AvailabilityChip(
                                label: 'Tous',
                                selected: provider.availabilityFilter == null,
                                onTap: () =>
                                    provider.filterByAvailability(null),
                              ),
                              _AvailabilityChip(
                                label: 'Disponibles',
                                selected: provider.availabilityFilter == true,
                                onTap: () =>
                                    provider.filterByAvailability(true),
                              ),
                              _AvailabilityChip(
                                label: 'Indisponibles',
                                selected: provider.availabilityFilter == false,
                                onTap: () =>
                                    provider.filterByAvailability(false),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _openMapWithSearch,
                        icon: const Icon(Icons.map, color: Colors.white),
                        label: const Text(
                          'Recherche',
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
                    ? ['Plomberie', 'Électricité', 'Peinture', 'Carrelage']
                    : categories.take(4).toList();

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  children: displayCategories
                      .map(
                        (category) => _ServiceCard(
                          label: category,
                          onTap: () {
                            // Filtrer par catégorie et aller à la carte
                            provider.filterArtisans('', category: category);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MapScreen(),
                              ),
                            );
                          },
                        ),
                      )
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
}

class _ServiceCard extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ServiceCard({required this.label, this.onTap});

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
    if (cat.contains('rénovation') || cat.contains('renovati')) {
      return Icons.build;
    }
    if (cat.contains('étanch')) return Icons.water_damage;
    if (cat.contains('démolit') || cat.contains('demolit')) {
      return Icons.delete_sweep;
    }
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

class _AvailabilityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AvailabilityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.teal.withValues(alpha: 0.12)
              : AppColors.navy.withValues(alpha: 0.04),
          border: Border.all(
            color: selected
                ? AppColors.teal
                : AppColors.navy.withValues(alpha: 0.1),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.teal : AppColors.navy,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
