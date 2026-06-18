import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/data/services/api_client.dart';
import 'package:maalem_app/data/services/location_service.dart';
import 'package:maalem_app/presentation/auth/screens/favorite_artisans_screen.dart';
import 'package:maalem_app/main.dart';
import 'package:maalem_app/presentation/search/screens/map_screen.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileClientScreen extends StatefulWidget {
  const ProfileClientScreen({super.key});

  @override
  State<ProfileClientScreen> createState() => _ProfileClientScreenState();
}

class _LocationUpdate {
  final String? city;
  final String? neighborhood;
  final double? latitude;
  final double? longitude;

  const _LocationUpdate({
    required this.city,
    required this.neighborhood,
    required this.latitude,
    required this.longitude,
  });
}

class _ProfileClientScreenState extends State<ProfileClientScreen> {
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();
  Uint8List? _localPhotoBytes;

  Future<void> _pickProfilePhoto() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() => _localPhotoBytes = bytes);

    final result = await context.read<AuthProvider>().updateProfilePhoto(image);
    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccess(_successMessage('Photo de profil mise a jour', result));
    } else {
      _showError(result['error'] ?? 'Erreur upload photo');
    }
  }

  Future<void> _editPersonalInfo() async {
    final user = context.read<AuthProvider>().user;
    final result = await _showPersonalInfoDialog(
      fullName: user?.fullName ?? '',
      email: user?.email ?? '',
      phone: user?.phone ?? '',
    );
    if (result == null) return;

    await _waitForUiToSettle();
    if (!mounted) return;
    final response = await context.read<AuthProvider>().updateClientProfile(
          fullName: result['fullName'],
          email: result['email'],
          phone: result['phone'],
        );
    if (!mounted) return;

    if (response['success'] == true) {
      _showSuccess(_successMessage('Informations mises a jour', response));
    } else {
      _showError(response['error'] ?? 'Erreur lors de la mise a jour');
    }
  }

  Future<void> _updateLocation() async {
    final user = context.read<AuthProvider>().user;
    final updated = await _showLocationDialog(
      city: user?.city ?? '',
      neighborhood: user?.neighborhood ?? '',
      latitude: user?.latitude,
      longitude: user?.longitude,
    );
    if (updated == null) return;

    await _waitForUiToSettle();
    if (!mounted) return;

    final response = await context.read<AuthProvider>().updateClientProfile(
          city: updated.city,
          neighborhood: updated.neighborhood,
          latitude: updated.latitude,
          longitude: updated.longitude,
        );
    if (!mounted) return;

    if (response['success'] == true) {
      _showSuccess(_successMessage('Localisation mise a jour', response));
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MapScreen()),
      );
    } else {
      _showError(response['error'] ?? 'Erreur lors de la mise a jour');
    }
  }

  Future<void> _openSupport() async {
    final uri = context.read<AuthProvider>().contactSupportUri();
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!launched) {
      _showError("Impossible d'ouvrir WhatsApp");
    }
  }

  Future<_LocationUpdate?> _showLocationDialog({
    required String city,
    required String neighborhood,
    double? latitude,
    double? longitude,
  }) async {
    final cityController = TextEditingController(text: city);
    final neighborhoodController = TextEditingController(text: neighborhood);
    UserLocation? selectedLocation = latitude != null && longitude != null
        ? UserLocation(latitude: latitude, longitude: longitude)
        : null;
    var isLocating = false;

    Future<void> useCurrentLocation(StateSetter setSheetState) async {
      setSheetState(() => isLocating = true);
      try {
        final location = await _locationService.getCurrentLocation();
        if (!mounted) return;
        setSheetState(() {
          selectedLocation = location;
          if (location.city?.isNotEmpty == true) {
            cityController.text = location.city!;
          }
          if (location.neighborhood?.isNotEmpty == true) {
            neighborhoodController.text = location.neighborhood!;
          }
        });
      } catch (e) {
        if (!mounted) return;
        _showError(e.toString().replaceFirst('Exception: ', ''));
      } finally {
        if (mounted) setSheetState(() => isLocating = false);
      }
    }

    final result = await showModalBottomSheet<_LocationUpdate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 22,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mettre a jour ma localisation',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cityController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: neighborhoodController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Quartier ou adresse',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      selectedLocation == null
                          ? 'Aucune position GPS enregistree'
                          : 'GPS: ${selectedLocation!.coordinatesLabel}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isLocating
                        ? null
                        : () => useCurrentLocation(setSheetState),
                    icon: isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppColors.teal,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.gps_fixed),
                    label: Text(
                      isLocating
                          ? 'Recherche de position...'
                          : 'Utiliser ma position actuelle',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                              _LocationUpdate(
                                city: cityController.text.trim().isEmpty
                                    ? null
                                    : cityController.text.trim(),
                                neighborhood:
                                    neighborhoodController.text.trim().isEmpty
                                        ? null
                                        : neighborhoodController.text.trim(),
                                latitude: selectedLocation?.latitude,
                                longitude: selectedLocation?.longitude,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                          ),
                          child: const Text(
                            'Enregistrer',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    cityController.dispose();
    neighborhoodController.dispose();
    return result;
  }

  Future<Map<String, String>?> _showPersonalInfoDialog({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _PersonalInfoDialog(
        fullName: fullName,
        email: email,
        phone: phone,
      ),
    );

    if (result == null ||
        (result['fullName'] ?? '').isEmpty ||
        (result['email'] ?? '').isEmpty) {
      return null;
    }
    return result;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.teal),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  String _successMessage(String message, Map<String, dynamic> result) {
    return result['mocked'] == true ? '$message (Simulation locale)' : message;
  }

  Future<void> _waitForUiToSettle() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final fullName = user?.fullName ?? 'Client Lmaalem';
    final email = user?.email ?? '-';
    final phone = user?.phone ?? '-';
    final location = [
      if (user?.city?.isNotEmpty == true) user!.city,
      if (user?.neighborhood?.isNotEmpty == true) user!.neighborhood,
    ].whereType<String>().join(', ');
    final coordinates = user?.latitude != null && user?.longitude != null
        ? 'GPS: ${user!.latitude!.toStringAsFixed(5)}, ${user.longitude!.toStringAsFixed(5)}'
        : null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.beige,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              children: [
                const _TopBar(),
                const SizedBox(height: 8),
                _ProfileHeader(
                  fullName: fullName,
                  initials: _initials(fullName),
                  photoUrl: user?.photoUrl,
                  localPhotoBytes: _localPhotoBytes,
                  isUploading: auth.isUploadingPhoto,
                  onEditPhoto: _pickProfilePhoto,
                ),
                const SizedBox(height: 24),
                _PersonalInfoCard(
                  fullName: fullName,
                  email: email,
                  phone: phone,
                  isUpdating: auth.isUpdatingProfile,
                  onEdit: _editPersonalInfo,
                ),
                const SizedBox(height: 16),
                _LocationCard(
                  location:
                      location.isEmpty ? 'Localisation non renseignee' : location,
                  details: coordinates ??
                      user?.neighborhood ??
                      'Utilisez votre position actuelle',
                  isUpdating: auth.isUpdatingProfile,
                  onUpdate: _updateLocation,
                ),
                const SizedBox(height: 16),
                _QuickActionsGrid(
                  onFavorites: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoriteArtisansScreen(),
                      ),
                    );
                  },
                  onHelp: _openSupport,
                ),
                const SizedBox(height: 22),
                _LogoutButton(
                  onLogout: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const AppGate()),
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'Version 2.4.1 - Lmaalem Client',
                  style: TextStyle(
                    color: AppColors.textGrey.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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

class _PersonalInfoDialog extends StatefulWidget {
  final String fullName;
  final String email;
  final String phone;

  const _PersonalInfoDialog({
    required this.fullName,
    required this.email,
    required this.phone,
  });

  @override
  State<_PersonalInfoDialog> createState() => _PersonalInfoDialogState();
}

class _PersonalInfoDialogState extends State<_PersonalInfoDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fullName);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    Navigator.pop(context, {
      'fullName': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AlertDialog(
        title: const Text('Modifier mes informations'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                autofocus: true,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                onSubmitted: (_) => _emailFocus.requestFocus(),
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                focusNode: _emailFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _phoneFocus.requestFocus(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.phone,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Telephone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 40, height: 40),
        const Expanded(
          child: Text(
            'Lmaalem',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Material(
          color: Colors.white.withValues(alpha: 0.5),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Notifications - en construction')),
              );
            },
            icon: const Icon(Icons.notifications_none, color: AppColors.navy),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String fullName;
  final String initials;
  final String? photoUrl;
  final Uint8List? localPhotoBytes;
  final bool isUploading;
  final VoidCallback onEditPhoto;

  const _ProfileHeader({
    required this.fullName,
    required this.initials,
    required this.photoUrl,
    required this.localPhotoBytes,
    required this.isUploading,
    required this.onEditPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    ImageProvider? providerImage;
    if (localPhotoBytes != null) {
      providerImage = MemoryImage(localPhotoBytes!);
    } else if (hasPhoto && photoUrl!.startsWith('data:image')) {
      final commaIndex = photoUrl!.indexOf(',');
      if (commaIndex != -1) {
        try {
          providerImage =
              MemoryImage(base64Decode(photoUrl!.substring(commaIndex + 1)));
        } catch (_) {
          providerImage = null;
        }
      }
    } else if (hasPhoto) {
      final resolvedPhotoUrl = _resolveImageUrl(photoUrl!);
      if (resolvedPhotoUrl != null) {
        providerImage = NetworkImage(resolvedPhotoUrl);
      }
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: AppColors.navy,
                backgroundImage: providerImage,
                child: providerImage != null
                    ? null
                    : Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
            Material(
              color: AppColors.teal,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isUploading ? null : onEditPhoto,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(11),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          fullName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Client',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  String? _resolveImageUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.startsWith('data:image')) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) return '${ApiClient.baseUrl}$trimmed';
    return '${ApiClient.baseUrl}/$trimmed';
  }
}

class _PersonalInfoCard extends StatelessWidget {
  final String fullName;
  final String email;
  final String phone;
  final bool isUpdating;
  final VoidCallback onEdit;

  const _PersonalInfoCard({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.isUpdating,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Informations personnelles',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: isUpdating ? null : onEdit,
                icon: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.teal,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.edit, color: AppColors.teal),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _InfoRow(
              icon: Icons.person_outline,
              label: 'Nom complet',
              value: fullName),
          const _DividerLine(),
          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email),
          const _DividerLine(),
          _InfoRow(
              icon: Icons.phone_outlined, label: 'Telephone', value: phone),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String location;
  final String details;
  final bool isUpdating;
  final VoidCallback onUpdate;

  const _LocationCard({
    required this.location,
    required this.details,
    required this.isUpdating,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ma localisation',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _IconBox(icon: Icons.location_on_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location,
                      style: const TextStyle(
                        color: Color(0xFF1D1B20),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: isUpdating ? null : onUpdate,
              icon: isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppColors.teal,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.map_outlined),
              label: const Text('Mettre a jour sur la carte'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                backgroundColor: AppColors.teal.withValues(alpha: 0.05),
                side: BorderSide(
                  color: AppColors.teal.withValues(alpha: 0.3),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onFavorites;
  final VoidCallback onHelp;

  const _QuickActionsGrid({
    required this.onFavorites,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.14,
      children: [
        const _ActionTile(
            icon: Icons.calendar_today_outlined, label: 'Mes reservations'),
        _ActionTile(
          icon: Icons.favorite_border,
          label: 'Artisans favoris',
          onTap: onFavorites,
        ),
        const _ActionTile(
            icon: Icons.settings_outlined, label: 'Parametres du compte'),
        _ActionTile(
          icon: Icons.help_center_outlined,
          label: "Centre d'aide",
          onTap: onHelp,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionTile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label - en construction')),
              );
            },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _softDecoration(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.teal, size: 25),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout, color: Color(0xFFBA1A1A)),
        label: const Text(
          'Deconnexion',
          style: TextStyle(
            color: Color(0xFFBA1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;

  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _softDecoration(),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          _IconBox(icon: icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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

class _IconBox extends StatelessWidget {
  final IconData icon;

  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.teal, size: 22),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: double.infinity,
      color: AppColors.textGrey.withValues(alpha: 0.05),
    );
  }
}

BoxDecoration _softDecoration() {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: AppColors.navy.withValues(alpha: 0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
