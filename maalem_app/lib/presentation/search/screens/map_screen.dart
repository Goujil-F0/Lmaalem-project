import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../providers/search_provider.dart';
import '../../../data/models/artisan_model.dart';
import 'package:maalem_app/presentation/dashboard/screens/dashboard_screen.dart';

// Palette centralisée — importe depuis un fichier theme si tu veux
class _Colors {
  static const blue = Color(0xFF2C5F8A);
  static const beige = Color(0xFFF5ECD7);
  static const beigeDark = Color(0xFFE8D5B0);
  static const textDark = Color(0xFF1A2D42);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadArtisans();
    });
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
          // COUCHE 1 : Carte
          Consumer<SearchProvider>(
            builder: (context, provider, _) {
              if (provider.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 48,
                          color: _Colors.blue.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _Colors.textDark.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => provider.loadArtisans(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: _Colors.blue),
                );
              }

              return FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(33.5731, -7.5898),
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.maalem.app',
                    tileProvider: NetworkTileProvider(),
                  ),
                  MarkerLayer(
                    markers: provider.artisans
                        .map(
                          (artisan) => Marker(
                            point: LatLng(
                              artisan.latitude,
                              artisan.longitude,
                            ),
                            width: 50,
                            height: 50,
                            child: GestureDetector(
                              onTap: () =>
                                  _showArtisanDetails(context, artisan),
                              child: const Icon(
                                Icons.location_on,
                                color: _Colors.blue,
                                size: 40,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
            },
          ),

          // COUCHE 2 : Barre de recherche
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _Colors.beigeDark, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _Colors.blue.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) =>
                    context.read<SearchProvider>().filterArtisans(value),
                style: const TextStyle(color: _Colors.textDark),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un artisan...',
                  hintStyle: TextStyle(color: Color(0xFFAAAFBC)),
                  prefixIcon: Icon(Icons.search, color: _Colors.blue),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
            // Handle bar
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
                // Avatar initiales
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _Colors.blue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      artisan.fullName.isNotEmpty
                          ? artisan.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                        '📍 ${artisan.city}',
                        style: TextStyle(
                          color: _Colors.textDark.withOpacity(0.55),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (artisan.isAvailable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C5F8A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Disponible',
                      style: TextStyle(
                        color: _Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Infos secondaires
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _Colors.beigeDark.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoChip(
                    icon: Icons.star_rounded,
                    label: (artisan.averageRating ?? 0.0).toStringAsFixed(1),
                    iconColor: const Color(0xFFD4A017),
                  ),
                  Container(width: 1, height: 28, color: _Colors.beigeDark),
                  _InfoChip(
                    icon: Icons.access_time_rounded,
                    label:
                        '${(artisan.hourlyRate ?? 0.0).toStringAsFixed(0)} MAD/h',
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
      ),
    ),
  );
                  // TODO : Navigator.push vers ArtisanProfileScreen
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

// Widget réutilisable pour les chips d'info
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
