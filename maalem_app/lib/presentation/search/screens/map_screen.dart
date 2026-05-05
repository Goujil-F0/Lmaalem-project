import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../providers/search_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    // Dès que l'écran s'affiche, on demande au Provider de charger les artisans
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadArtisans();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Trouver un Maalem")),
      // Dans le body du Scaffold
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (searchProvider.isLoading)
            return Center(child: CircularProgressIndicator());

          return FlutterMap(
            // Assure-toi qu'il n'est pas dans un widget qui réduit sa taille à zero
            options: MapOptions(
              initialCenter: LatLng(33.5731, -7.5898),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // Ajoute impérativement ceci :
                userAgentPackageName: 'com.maalem.app',
                // Optionnel : permet de mieux gérer les erreurs de chargement
                tileProvider: NetworkTileProvider(),
              ),
              MarkerLayer(
                markers: searchProvider.artisans
                    .map(
                      (artisan) => Marker(
                        point: LatLng(
                          artisan.latitude ?? 0,
                          artisan.longitude ?? 0,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.orange,
                          size: 40,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
