import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maalem_app/data/services/api_client.dart';
import 'package:maalem_app/data/services/dashboard_service.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileArtisanScreen extends StatefulWidget {
  const ProfileArtisanScreen({super.key});

  @override
  State<ProfileArtisanScreen> createState() => _ProfileArtisanScreenState();
}

class _ProfileArtisanScreenState extends State<ProfileArtisanScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _localPhotoBytes;
  Map<String, dynamic>? _dashboardStats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboardStats());
  }

  Future<void> _loadDashboardStats() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    final userId = auth.user?.id;
    if (token == null || userId == null) return;

    try {
      final data =
          await DashboardService(token: token).getArtisanDashboard(userId);
      if (mounted) setState(() => _dashboardStats = data);
    } catch (_) {
      // Le compte reste utilisable meme si les stats dashboard ne chargent pas.
    }
  }

  Future<void> _handleAvailabilityChange(bool value) async {
    final result = await context.read<AuthProvider>().updateAvailability(value);
    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccess(_successMessage('Statut mis a jour', result));
    } else {
      _showError(result['error'] ?? 'Erreur lors de la mise a jour');
    }
  }

  Future<void> _pickProfilePhoto() async {
    final auth = context.read<AuthProvider>();
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (mounted) setState(() => _localPhotoBytes = bytes);

    final result = await auth.updateProfilePhoto(image);
    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccess(_successMessage('Photo de profil mise a jour', result));
    } else {
      _showError(result['error'] ?? 'Erreur upload photo');
    }
  }

  Future<void> _pickPortfolioImage() async {
    final auth = context.read<AuthProvider>();
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final result = await auth.uploadPortfolioImage(image);
    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccess(_successMessage('Image ajoutee au portfolio', result));
    } else {
      _showError(result['error'] ?? 'Erreur upload portfolio');
    }
  }

  Future<void> _replacePortfolioImage(int index) async {
    final auth = context.read<AuthProvider>();
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final result = await auth.replacePortfolioImage(index, image);
    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccess(_successMessage('Image portfolio mise a jour', result));
    } else {
      _showError(result['error'] ?? 'Erreur modification portfolio');
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

  Future<void> _editSpecialty(String current) async {
    final value = await _showSingleFieldDialog(
      title: 'Modifier la specialite',
      label: 'Specialite',
      initialValue: current,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
    );
    if (value == null) return;

    await _waitForUiToSettle();
    if (!mounted) return;
    final result = await context.read<AuthProvider>().updateArtisanProfile(
          specialty: value.trim(),
        );
    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccess(_successMessage('Specialite mise a jour', result));
    } else {
      _showError(result['error'] ?? 'Erreur lors de la mise a jour');
    }
  }

  Future<void> _editHourlyRate(double? current) async {
    final value = await _showSingleFieldDialog(
      title: 'Modifier le tarif',
      label: 'Tarif horaire',
      initialValue: current?.toStringAsFixed(0) ?? '',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
    );
    if (value == null) return;

    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) {
      _showError('Veuillez entrer un montant valide');
      return;
    }

    await _waitForUiToSettle();
    if (!mounted) return;
    final result = await context.read<AuthProvider>().updateArtisanProfile(
          hourlyRate: parsed,
        );
    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccess(_successMessage('Tarif mis a jour', result));
    } else {
      _showError(result['error'] ?? 'Erreur lors de la mise a jour');
    }
  }

  Future<void> _editDescription(String current) async {
    final value = await _showSingleFieldDialog(
      title: 'Modifier a propos',
      label: 'A propos',
      initialValue: current,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLines: 5,
    );
    if (value == null) return;

    await _waitForUiToSettle();
    if (!mounted) return;
    final result = await context.read<AuthProvider>().updateArtisanProfile(
          description: value.trim(),
        );
    if (!mounted) return;

    if (result['success'] == true) {
      _showSuccess(_successMessage('A propos mis a jour', result));
    } else {
      _showError(result['error'] ?? 'Erreur lors de la mise a jour');
    }
  }

  Future<String?> _showSingleFieldDialog({
    required String title,
    required String label,
    required String initialValue,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
    int maxLines = 1,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _SingleFieldDialog(
        title: title,
        label: label,
        initialValue: initialValue,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        maxLines: maxLines,
      ),
    );

    final trimmed = result?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
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

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final profile = user?.profile;
    final available = profile?.isAvailable ?? true;
    final averageRating = _toDouble(_dashboardStats?['averageRating']) ??
        profile?.averageRating ??
        0;
    final totalReviews = _toInt(_dashboardStats?['totalReviews']) ?? 0;
    final totalMissions = (_toInt(_dashboardStats?['pendingBookings']) ?? 0) +
        (_toInt(_dashboardStats?['confirmedBookings']) ?? 0);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.beige,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                _ProfileHeader(
                  name: user?.fullName ?? 'Artisan Lmaalem',
                  specialty: profile?.specialty ?? 'Specialite non renseignee',
                  photoUrl: user?.photoUrl,
                  localPhotoBytes: _localPhotoBytes,
                  initials: _initials(user?.fullName),
                  isUploading: auth.isUploadingPhoto,
                  onEditPhoto: _pickProfilePhoto,
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    _StatCard(
                      value: averageRating.toStringAsFixed(1),
                      label: 'Note Moyenne',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(value: '$totalReviews', label: 'Avis'),
                    const SizedBox(width: 12),
                    _StatCard(value: '$totalMissions', label: 'Missions'),
                  ],
                ),
                const SizedBox(height: 26),
                _ManagementCard(
                  specialty: profile?.specialty ?? 'Non renseignee',
                  hourlyRate: profile?.hourlyRate,
                  available: available,
                  isUpdatingProfile: auth.isUpdatingProfile,
                  isUpdatingAvailability: auth.isUpdatingAvailability,
                  onEditSpecialty: () =>
                      _editSpecialty(profile?.specialty ?? ''),
                  onEditHourlyRate: () => _editHourlyRate(profile?.hourlyRate),
                  onAvailabilityChanged: auth.isUpdatingAvailability
                      ? null
                      : _handleAvailabilityChange,
                ),
                const SizedBox(height: 26),
                _PortfolioSection(
                  images: profile?.portfolioImages ?? const [],
                  isUploading: auth.isUploadingPortfolio,
                  onAdd: _pickPortfolioImage,
                  onReplace: _replacePortfolioImage,
                ),
                const SizedBox(height: 26),
                _BioSection(
                  description: profile?.description,
                  isUpdating: auth.isUpdatingProfile,
                  onEdit: () => _editDescription(profile?.description ?? ''),
                ),
                const SizedBox(height: 26),
                _FooterActions(
                  onSupport: _openSupport,
                  onLogout: () => context.read<AuthProvider>().logout(),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return 'AR';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _SingleFieldDialog extends StatefulWidget {
  final String title;
  final String label;
  final String initialValue;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;

  const _SingleFieldDialog({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.keyboardType,
    required this.textInputAction,
    required this.maxLines,
  });

  @override
  State<_SingleFieldDialog> createState() => _SingleFieldDialogState();
}

class _SingleFieldDialogState extends State<_SingleFieldDialog> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.maxLines == 1 ? (_) => _submit() : null,
          decoration: InputDecoration(
            labelText: widget.label,
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.teal),
            ),
            border: const OutlineInputBorder(),
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

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String specialty;
  final String? photoUrl;
  final Uint8List? localPhotoBytes;
  final String initials;
  final bool isUploading;
  final VoidCallback onEditPhoto;

  const _ProfileHeader({
    required this.name,
    required this.specialty,
    required this.photoUrl,
    required this.localPhotoBytes,
    required this.initials,
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
        // Photo Profile Container with Shadow
        Container(
          margin: const EdgeInsets.only(bottom: 28),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white,
                      width: 4,
                    ),
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
                              letterSpacing: -0.5,
                            ),
                          ),
                  ),
                ),
              ),
              // Edit Photo Button with Animation
              Material(
                color: AppColors.teal,
                shape: const CircleBorder(),
                elevation: 8,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isUploading ? null : onEditPhoto,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: isUploading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Name
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        // Specialty
        Text(
          specialty,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.teal,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 14),
        // Verified Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified,
                color: AppColors.teal,
                size: 14,
              ),
              SizedBox(width: 6),
              Text(
                'Professionnel Vérifié',
                style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
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

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: AppColors.navy.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final String specialty;
  final double? hourlyRate;
  final bool available;
  final bool isUpdatingProfile;
  final bool isUpdatingAvailability;
  final VoidCallback onEditSpecialty;
  final VoidCallback onEditHourlyRate;
  final ValueChanged<bool>? onAvailabilityChanged;

  const _ManagementCard({
    required this.specialty,
    required this.hourlyRate,
    required this.available,
    required this.isUpdatingProfile,
    required this.isUpdatingAvailability,
    required this.onEditSpecialty,
    required this.onEditHourlyRate,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.navy.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _ManagementItem(
            label: 'Ma Specialite',
            value: specialty,
            isLoading: isUpdatingProfile,
            onTap: onEditSpecialty,
          ),
          const Divider(height: 26, color: Color(0x1A0C2C55)),
          _ManagementItem(
            label: 'Tarif Horaire',
            value: '${hourlyRate?.toStringAsFixed(0) ?? '0'} MAD / h',
            isLoading: isUpdatingProfile,
            onTap: onEditHourlyRate,
          ),
          const Divider(height: 26, color: Color(0x1A0C2C55)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statut',
                    style: TextStyle(
                      color: AppColors.navy.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    available ? 'Actuellement Disponible' : 'Indisponible',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              isUpdatingAvailability
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: AppColors.teal,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Switch(
                      value: available,
                      activeThumbColor: AppColors.teal,
                      onChanged: onAvailabilityChanged,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManagementItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;
  final VoidCallback onTap;

  const _ManagementItem({
    required this.label,
    required this.value,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.navy.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: isLoading ? null : onTap,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.teal,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.edit, color: AppColors.teal, size: 20),
        ),
      ],
    );
  }
}

class _PortfolioSection extends StatelessWidget {
  final List<String> images;
  final bool isUploading;
  final VoidCallback onAdd;
  final ValueChanged<int> onReplace;

  const _PortfolioSection({
    required this.images,
    required this.isUploading,
    required this.onAdd,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mes Realisations',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextButton.icon(
              onPressed: isUploading ? null : onAdd,
              icon: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppColors.teal,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add_circle,
                      color: AppColors.teal, size: 20),
              label: const Text(
                'Ajouter',
                style: TextStyle(
                  color: AppColors.teal,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: images.isEmpty
              ? List.generate(4, (_) => const _PortfolioPlaceholder())
              : List.generate(
                  images.length,
                  (index) => _PortfolioImageTile(
                    image: images[index],
                    isLoading: isUploading,
                    onReplace: () => onReplace(index),
                  ),
                ),
        ),
      ],
    );
  }
}

class _PortfolioImageTile extends StatelessWidget {
  final String image;
  final bool isLoading;
  final VoidCallback onReplace;

  const _PortfolioImageTile({
    required this.image,
    required this.isLoading,
    required this.onReplace,
  });

  void _openImageZoom(BuildContext context, ImageProvider imageProvider) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image(
                image: imageProvider,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white, size: 48),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProvider(image);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: GestureDetector(
        onTap: imageProvider == null
            ? null
            : () => _openImageZoom(context, imageProvider),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.navy.withValues(alpha: 0.05)),
            image: imageProvider == null
                ? null
                : DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
          child: imageProvider == null
              ? const _PortfolioPlaceholder()
              : Stack(
                  children: [
                    const SizedBox.expand(),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(14),
                        child: IconButton(
                          tooltip: 'Modifier',
                          onPressed: isLoading ? null : onReplace,
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  ImageProvider? _imageProvider(String value) {
    final resolvedValue = _resolveImageUrl(value);
    if (value.startsWith('data:image')) {
      final commaIndex = value.indexOf(',');
      if (commaIndex == -1) return null;
      try {
        return MemoryImage(base64Decode(value.substring(commaIndex + 1)));
      } catch (_) {
        return null;
      }
    }

    if (resolvedValue != null) {
      return NetworkImage(resolvedValue);
    }

    return null;
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

class _PortfolioPlaceholder extends StatelessWidget {
  const _PortfolioPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.05)),
      ),
      child: Icon(
        Icons.image_outlined,
        color: AppColors.teal.withValues(alpha: 0.55),
        size: 34,
      ),
    );
  }
}

class _BioSection extends StatelessWidget {
  final String? description;
  final bool isUpdating;
  final VoidCallback onEdit;

  const _BioSection({
    required this.description,
    required this.isUpdating,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final text = description?.trim().isNotEmpty == true
        ? description!.trim()
        : "Avec plus de 15 ans d'experience dans l'artisanat traditionnel marocain, je marie authenticite et confort moderne.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'A propos',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
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
                  : const Icon(Icons.edit, color: AppColors.teal, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.navy.withValues(alpha: 0.05), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.navy.withValues(alpha: 0.75),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterActions extends StatelessWidget {
  final VoidCallback onSupport;
  final VoidCallback onLogout;

  const _FooterActions({required this.onSupport, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton.icon(
            onPressed: onSupport,
            icon: const Icon(Icons.headset_mic, color: Colors.white, size: 22),
            label: const Text(
              'Support Client',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              elevation: 6,
              shadowColor: AppColors.teal.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout, color: AppColors.textGrey, size: 20),
          label: const Text(
            'Deconnexion',
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _cardDecoration({required double radius}) {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.navy.withValues(alpha: 0.05)),
    boxShadow: [
      BoxShadow(
        color: AppColors.navy.withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
