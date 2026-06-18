import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/data/services/api_client.dart';
import 'package:maalem_app/presentation/booking/screens/booking_screen.dart';
import 'package:maalem_app/presentation/dashboard/screens/dashboard_screen.dart';
import 'package:maalem_app/shared/widgets/maalem_app_bar.dart';
import 'package:provider/provider.dart';

import '../../../data/models/artisan_model.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/search_provider.dart';

class _Colors {
  static const blue = AppColors.teal;
  static const navy = AppColors.navy;
  static const beige = AppColors.beige;
  static const beigeDark = Color(0xFFDCD9B7);
  static const textDark = AppColors.navy;
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
      context.read<LocationProvider>().startLocationUpdates();
    });
  }

  @override
  void dispose() {
    context.read<LocationProvider>().stopLocationUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.beige,
      appBar: const MaalemAppBar(
        title: 'Trouver un Maalem',
        subtitle: 'Artisans près de vous',
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Consumer2<SearchProvider, LocationProvider>(
              builder: (context, searchProvider, locationProvider, _) {
                final userLocation = locationProvider.userLocation;
                final userLat = userLocation?.latitude;
                final userLng = userLocation?.longitude;
                final visibleArtisans = searchProvider.artisansForLocation(
                  userLat,
                  userLng,
                );

                if (searchProvider.isLoading &&
                    searchProvider.artisans.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: _Colors.blue),
                  );
                }

                return FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(33.5731, -7.5898),
                    initialZoom: 12,
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
                        context,
                        visibleArtisans,
                        searchProvider,
                        locationProvider,
                      ),
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
            left: 14,
            right: 14,
            bottom: 16,
            child: Consumer2<SearchProvider, LocationProvider>(
              builder: (context, searchProvider, locationProvider, _) {
                final location = locationProvider.userLocation;
                final count = searchProvider.countForLocation(
                  location?.latitude,
                  location?.longitude,
                );
                return _SimpleMapResultBar(count: count);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(
    BuildContext context,
    List<ArtisanModel> artisans,
    SearchProvider searchProvider,
    LocationProvider locationProvider,
  ) {
    final markers = <Marker>[];
    final userLocation = locationProvider.userLocation;

    // Afficher le marqueur du client
    if (userLocation != null &&
        userLocation.latitude != 0 &&
        userLocation.longitude != 0) {
      markers.add(
        Marker(
          point: LatLng(userLocation.latitude, userLocation.longitude),
          width: 54,
          height: 54,
          child: const _ClientMarker(),
        ),
      );
    } else {
      // Fallback: marqueur au centre de la carte (Casablanca) si localisation non disponible
      markers.add(
        const Marker(
          point: LatLng(33.5731, -7.5898),
          width: 54,
          height: 54,
          child: _ClientMarker(),
        ),
      );
    }

    // Afficher les artisans avec des coordonnées valides
    markers.addAll(
      artisans
          .where((artisan) => artisan.latitude != 0 && artisan.longitude != 0)
          .map(
            (artisan) => Marker(
              point: LatLng(artisan.latitude, artisan.longitude),
              width: 58,
              height: 58,
              child: GestureDetector(
                onTap: () => _showArtisanDetails(
                  context,
                  artisan,
                  searchProvider.distanceLabel(
                    artisan,
                    userLocation?.latitude,
                    userLocation?.longitude,
                  ),
                ),
                child: _ArtisanMarker(artisan: artisan),
              ),
            ),
          ),
    );

    return markers;
  }

  void _showArtisanDetails(
    BuildContext context,
    ArtisanModel artisan,
    String distanceLabel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _ArtisanBottomSheet(artisan: artisan, distanceLabel: distanceLabel),
    );
  }
}

class _SimpleMapResultBar extends StatelessWidget {
  final int count;

  const _SimpleMapResultBar({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.beigeDark),
        boxShadow: [
          BoxShadow(
            color: _Colors.navy.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, color: _Colors.blue, size: 20),
          const SizedBox(width: 10),
          Text(
            '$count artisan${count != 1 ? 's' : ''}',
            style: const TextStyle(
              color: _Colors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtisanBottomSheet extends StatelessWidget {
  final ArtisanModel artisan;
  final String distanceLabel;

  const _ArtisanBottomSheet({
    required this.artisan,
    required this.distanceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final rating = artisan.averageRating ?? artisan.rating ?? 0;
    final imageUrl = _resolveImageUrl(artisan.profileImage);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: _Colors.beige,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: _Colors.beigeDark,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(name: artisan.fullName, imageUrl: imageUrl, size: 72),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AvailabilityBadge(isAvailable: artisan.isAvailable),
                        const SizedBox(height: 8),
                        Text(
                          artisan.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _Colors.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artisan.speciality.isEmpty
                              ? 'Artisan general'
                              : artisan.speciality,
                          style: TextStyle(
                            color: _Colors.textDark.withValues(alpha: 0.65),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricPill(
                    icon: Icons.star_rounded,
                    label:
                        '${rating.toStringAsFixed(1)} (${artisan.reviewCount ?? 0})',
                    iconColor: const Color(0xFFD4A017),
                  ),
                  _MetricPill(
                    icon: Icons.near_me_outlined,
                    label: distanceLabel,
                    iconColor: _Colors.blue,
                  ),
                  _MetricPill(
                    icon: Icons.location_city_outlined,
                    label: artisan.city.isEmpty
                        ? 'Ville non renseignee'
                        : artisan.city,
                    iconColor: _Colors.blue,
                  ),
                  if (artisan.hourlyRate != null && artisan.hourlyRate! > 0)
                    _MetricPill(
                      icon: Icons.payments_outlined,
                      label: '${artisan.hourlyRate!.toStringAsFixed(0)} MAD/h',
                      iconColor: _Colors.blue,
                    ),
                ],
              ),
              if (artisan.bio?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 16),
                Text(
                  artisan.bio!.trim(),
                  style: TextStyle(
                    color: _Colors.textDark.withValues(alpha: 0.76),
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
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
                      icon: const Icon(Icons.person_search_outlined),
                      label: const Text('Profil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _Colors.blue,
                        side: BorderSide(
                          color: _Colors.blue.withValues(alpha: 0.35),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: artisan.isAvailable
                          ? () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingScreen(
                                    artisanId: artisan.id,
                                    artisanName: artisan.fullName,
                                    hourlyRate: artisan.hourlyRate ?? 0,
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Reserver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Colors.blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _resolveImageUrl(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    final value = source.trim();
    if (value.startsWith('http') || value.startsWith('data:')) return value;
    if (value.startsWith('/')) return '${ApiClient.baseUrl}$value';
    return '${ApiClient.baseUrl}/$value';
  }
}

class _ClientMarker extends StatelessWidget {
  const _ClientMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 2),
          ),
        ),
        Container(
          width: 17,
          height: 17,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _ArtisanMarker extends StatelessWidget {
  final ArtisanModel artisan;

  const _ArtisanMarker({required this.artisan});

  @override
  Widget build(BuildContext context) {
    final color = artisan.isAvailable ? _Colors.blue : Colors.grey.shade600;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.handyman_outlined, color: color, size: 22),
        ),
        Positioned(
          bottom: 0,
          child: Icon(Icons.arrow_drop_down, color: color, size: 34),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        isAvailable ? 'Disponible' : 'Indisponible',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Colors.beigeDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _Colors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;

  const _Avatar({
    required this.name,
    required this.imageUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _Colors.blue,
        borderRadius: BorderRadius.circular(20),
        image: imageUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              ),
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : null,
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
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
