import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:maalem_app/presentation/dashboard/screens/dashboard_screen.dart';
import 'package:maalem_app/shared/widgets/profile_avatar.dart';
import 'package:provider/provider.dart';

import '../../../data/models/artisan_model.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/location_provider.dart';

class _Colors {
  static const blue = Color(0xFF2C5F8A);
  static const beige = Color(0xFFF5ECD7);
  static const beigeDark = Color(0xFFE8D5B0);
  static const textDark = Color(0xFF1A2D42);
}

class MapScreen extends StatefulWidget {
  final String initialQuery;

  const MapScreen({super.key, this.initialQuery = ''});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchProvider = context.read<SearchProvider>();
      if (widget.initialQuery.trim().isNotEmpty) {
        searchProvider.filterArtisans(widget.initialQuery);
      }
      searchProvider.loadArtisans();
      // Démarrer le suivi de la localisation du client
      context.read<LocationProvider>().startLocationUpdates();
    });
  }

  @override
  void dispose() {
    // Arrêter le suivi de la localisation quand on quitte l'écran
    context.read<LocationProvider>().stopLocationUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.beige,
      appBar: AppBar(
        backgroundColor: _Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Trouver un Maalem',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Consumer2<SearchProvider, LocationProvider>(
              builder: (context, searchProvider, locationProvider, _) {
                if (searchProvider.isLoading &&
                    searchProvider.artisans.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: _Colors.blue),
                  );
                }

                return FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(33.5731, -7.5898),
                    initialZoom: 13,
                    minZoom: 4,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.maalem.app',
                      tileProvider: NetworkTileProvider(),
                    ),
                    MarkerLayer(
                      markers: _buildMarkers(
                          context, searchProvider, locationProvider),
                    ),
                    if (searchProvider.hasError)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _MapNotice(message: searchProvider.errorMessage),
                      ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _SearchBox(),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(BuildContext context,
      SearchProvider searchProvider, LocationProvider locationProvider) {
    List<Marker> markers = [];

    // Ajouter le marqueur de localisation du client
    if (locationProvider.userLocation != null) {
      markers.add(
        Marker(
          point: LatLng(
            locationProvider.userLocation!.latitude,
            locationProvider.userLocation!.longitude,
          ),
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Ajouter les marqueurs des artisans
    markers.addAll(
      searchProvider.artisans
          .where((artisan) => artisan.latitude != 0 && artisan.longitude != 0)
          .map(
            (artisan) => Marker(
              point: LatLng(artisan.latitude, artisan.longitude),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showArtisanDetails(context, artisan),
                child: Icon(
                  Icons.location_on,
                  color: artisan.isAvailable ? _Colors.blue : Colors.grey,
                  size: 42,
                ),
              ),
            ),
          )
          .toList(),
    );

    return markers;
  }

  void _showArtisanDetails(BuildContext context, ArtisanModel artisan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _Colors.beige,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _Colors.beigeDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                ProfileAvatar(
                  name: artisan.fullName,
                  imageUrl: artisan.profileImage,
                  size: 52,
                  borderRadius: 14,
                  backgroundColor: _Colors.blue,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artisan.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _Colors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${artisan.speciality} - ${artisan.city}',
                        style: TextStyle(
                          color: _Colors.textDark.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _AvailabilityBadge(isAvailable: artisan.isAvailable),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _Colors.beigeDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoChip(
                    icon: Icons.star_rounded,
                    label: (artisan.averageRating ?? artisan.rating ?? 0)
                        .toStringAsFixed(1),
                    iconColor: const Color(0xFFD4A017),
                  ),
                  Container(width: 1, height: 28, color: _Colors.beigeDark),
                  _InfoChip(
                    icon: Icons.access_time_rounded,
                    label:
                        '${(artisan.hourlyRate ?? 0).toStringAsFixed(0)} MAD/h',
                    iconColor: _Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardScreen(
                        artisanId: artisan.id,
                        artisan: artisan,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Voir le profil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatefulWidget {
  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  bool _showCategories = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final query = context.read<SearchProvider>().searchQuery;
      if (query.isNotEmpty) _searchController.text = query;
    });
    // On web, `onTap` can be flaky depending on how the user clicks.
    // Focusing the field should always reveal category chips when available.
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && !_showCategories) {
        setState(() => _showCategories = true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _Colors.beigeDark, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _Colors.blue.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => provider.filterArtisans(value),
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: _Colors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Decrivez votre probleme ou cherchez un artisan...',
                      hintStyle: const TextStyle(color: Color(0xFFAAAFBC)),
                      prefixIcon: const Icon(Icons.search, color: _Colors.blue),
                      suffixIcon: _showCategories
                          ? IconButton(
                              icon: const Icon(Icons.expand_less,
                                  color: _Colors.blue),
                              onPressed: () =>
                                  setState(() => _showCategories = false),
                            )
                          : IconButton(
                              icon: const Icon(Icons.expand_more,
                                  color: _Colors.blue),
                              onPressed: () =>
                                  setState(() => _showCategories = true),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 8),
                    ),
                  ),
                  if (_showCategories && provider.categories.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: _Colors.beige.withValues(alpha: 0.5),
                        border: Border(
                          top: BorderSide(
                            color: _Colors.beigeDark.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Bouton "Tous"
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: FilterChip(
                                label: const Text('Tous'),
                                selected: provider.selectedCategory.isEmpty,
                                onSelected: (_) {
                                  provider.resetFilters();
                                  _searchController.clear();
                                },
                                backgroundColor: Colors.white,
                                selectedColor: _Colors.blue,
                                labelStyle: TextStyle(
                                  color: provider.selectedCategory.isEmpty
                                      ? Colors.white
                                      : _Colors.textDark,
                                ),
                              ),
                            ),
                            // Catégories
                            ...provider.categories.map((category) {
                              final isSelected =
                                  provider.selectedCategory.toLowerCase() ==
                                      category.toLowerCase();
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (_) {
                                  provider.filterArtisans('', category: category);
                                  _searchController.clear();
                                  setState(() => _showCategories = false);
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: _Colors.blue,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : _Colors.textDark,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatusChip(
                            label: 'Tous',
                            selected: provider.availabilityFilter == null,
                            onSelected: () =>
                                provider.filterByAvailability(null),
                          ),
                          _StatusChip(
                            label: 'Disponibles (${provider.availableCount})',
                            selected: provider.availabilityFilter == true,
                            onSelected: () =>
                                provider.filterByAvailability(true),
                          ),
                          _StatusChip(
                            label:
                                'Indisponibles (${provider.unavailableCount})',
                            selected: provider.availabilityFilter == false,
                            onSelected: () =>
                                provider.filterByAvailability(false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;

  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? _Colors.blue : Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAvailable ? 'Disponible' : 'Indisponible',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.white,
        selectedColor: _Colors.blue,
        labelStyle: TextStyle(
          color: selected ? Colors.white : _Colors.textDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  final String message;

  const _MapNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Colors.beigeDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, color: _Colors.blue, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(color: _Colors.textDark, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _Colors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
