import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/data/services/location_service.dart';
import 'package:maalem_app/presentation/auth/screens/auth_screen.dart';
import 'package:maalem_app/presentation/auth/screens/upload_cin_screen.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isArtisan = false;
  bool _isLocating = false;
  UserLocation? _selectedLocation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final LocationService _locationService = LocationService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _specialtyController.dispose();
    _neighborhoodController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() => _selectedLocation = location);
      _showSnackBar('Position GPS ajoutee');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        (isArtisan && _specialtyController.text.isEmpty)) {
      _showSnackBar('Veuillez remplir les champs obligatoires');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Les mots de passe ne correspondent pas');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.register({
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'role': isArtisan ? 'artisan' : 'client',
      'phone': isArtisan ? _phoneController.text.trim() : null,
      'specialty': isArtisan ? _specialtyController.text.trim() : null,
      'city': _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      'neighborhood': _neighborhoodController.text.trim().isEmpty
          ? null
          : _neighborhoodController.text.trim(),
      'latitude': _selectedLocation?.latitude,
      'longitude': _selectedLocation?.longitude,
    });

    if (!mounted) return;

    if (result['success'] != true) {
      _showSnackBar(result['error'] ?? 'Une erreur est survenue');
      return;
    }

    if (isArtisan) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const UploadCinScreen(),
          transitionsBuilder: (_, animation, __, child) {
            final slideUp = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            return SlideTransition(position: slideUp, child: child);
          },
        ),
      );
      return;
    }

    _showSnackBar('Inscription reussie. Connectez-vous maintenant.');
    _openLogin();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _openLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const AuthScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final slideUp = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return SlideTransition(position: slideUp, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              const SizedBox(height: 34),
              const _RegisterLogo(),
              const SizedBox(height: 18),
              Text(
                'Rejoignez la communaute Lmaalem',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.navy.withValues(alpha: 0.62),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 34),
              _RoleSwitcher(
                isArtisan: isArtisan,
                onChanged: (value) => setState(() => isArtisan = value),
              ),
              const SizedBox(height: 28),
              _RegisterInput(
                controller: _nameController,
                hintText: 'Nom complet',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _RegisterInput(
                controller: _emailController,
                hintText: 'E-mail',
                icon: Icons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _RegisterInput(
                controller: _passwordController,
                hintText: 'Mot de passe',
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _RegisterInput(
                controller: _confirmPasswordController,
                hintText: 'Confirmer le mot de passe',
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _RegisterDropdown(
                controller: _cityController,
                hintText: 'Ville',
                icon: Icons.location_city,
                items: _moroccanCities,
              ),
              const SizedBox(height: 16),
              _RegisterInput(
                controller: _neighborhoodController,
                hintText: 'Quartier ou adresse',
                icon: Icons.location_on,
                keyboardType: TextInputType.streetAddress,
              ),
              const SizedBox(height: 16),
              _LocationPickerBox(
                isArtisan: isArtisan,
                isLocating: _isLocating,
                selectedLocation: _selectedLocation,
                onPressed: _useCurrentLocation,
              ),
              if (isArtisan) ...[
                const SizedBox(height: 16),
                _RegisterInput(
                  controller: _phoneController,
                  hintText: 'Telephone',
                  icon: Icons.call,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _RegisterDropdown(
                  controller: _specialtyController,
                  hintText: 'Specialite',
                  icon: Icons.handyman,
                  items: _artisanSpecialties,
                ),
                const SizedBox(height: 16),
                const _UploadCinBox(),
              ],
              const SizedBox(height: 34),
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.teal))
                  : _PrimaryRegisterButton(
                      text:
                          isArtisan ? 'Devenir Artisan Lmaalem' : "S'inscrire",
                      onPressed: _handleRegister,
                    ),
              const SizedBox(height: 44),
              TextButton(
                onPressed: _openLogin,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.navy.withValues(alpha: 0.72),
                      fontSize: 15,
                    ),
                    children: const [
                      TextSpan(text: 'Vous avez deja un compte ? '),
                      TextSpan(
                        text: 'Se connecter',
                        style: TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterLogo extends StatelessWidget {
  const _RegisterLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.handyman, color: AppColors.navy, size: 38),
        ),
        const SizedBox(height: 14),
        Text(
          'Lmaalem',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: AppColors.teal.withValues(alpha: 0.22),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleSwitcher extends StatelessWidget {
  final bool isArtisan;
  final ValueChanged<bool> onChanged;

  const _RoleSwitcher({required this.isArtisan, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _RoleOption(
            text: 'Client',
            selected: !isArtisan,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 8),
          _RoleOption(
            text: 'Artisan',
            selected: isArtisan,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterInput extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextEditingController controller;

  const _RegisterInput({
    required this.hintText,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.navy.withValues(alpha: 0.52)),
        prefixIcon: Icon(icon, color: AppColors.navy.withValues(alpha: 0.72)),
        filled: true,
        fillColor: AppColors.navy.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.navy.withValues(alpha: 0.03)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
        ),
      ),
    );
  }
}

class _RegisterDropdown extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final List<String> items;

  const _RegisterDropdown({
    required this.hintText,
    required this.icon,
    required this.controller,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: controller.text.isEmpty ? null : controller.text,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.navy.withValues(alpha: 0.52)),
        prefixIcon: Icon(icon, color: AppColors.navy.withValues(alpha: 0.72)),
        filled: true,
        fillColor: AppColors.navy.withValues(alpha: 0.08),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.navy.withValues(alpha: 0.03)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) => controller.text = value ?? '',
    );
  }
}

class _UploadCinBox extends StatelessWidget {
  const _UploadCinBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload,
              color: AppColors.navy.withValues(alpha: 0.72)),
          const SizedBox(height: 8),
          Text(
            'Upload CIN Recto / Verso apres inscription',
            style: TextStyle(
              color: AppColors.navy.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPickerBox extends StatelessWidget {
  final bool isArtisan;
  final bool isLocating;
  final UserLocation? selectedLocation;
  final VoidCallback onPressed;

  const _LocationPickerBox({
    required this.isArtisan,
    required this.isLocating,
    required this.selectedLocation,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = selectedLocation != null;
    final title = isArtisan
        ? 'Definir ma zone d intervention'
        : 'Ajouter ma position actuelle';
    final savedTitle = isArtisan
        ? 'Zone d intervention enregistree'
        : 'Position GPS enregistree';
    final action = isArtisan
        ? 'Utiliser cette position pour mes clients'
        : 'Utiliser ma position';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasLocation ? Icons.my_location : Icons.location_searching,
                color: AppColors.teal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasLocation ? savedTitle : title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (hasLocation) ...[
            const SizedBox(height: 8),
            Text(
              selectedLocation!.coordinatesLabel,
              style: TextStyle(
                color: AppColors.navy.withValues(alpha: 0.62),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLocating ? null : onPressed,
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
                    : action,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                side: BorderSide(color: AppColors.teal.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryRegisterButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryRegisterButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          elevation: 6,
          shadowColor: AppColors.teal.withValues(alpha: 0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

const _moroccanCities = [
  'Agadir',
  'Beni Mellal',
  'Casablanca',
  'El Jadida',
  'Essaouira',
  'Fes',
  'Kenitra',
  'Marrakech',
  'Meknes',
  'Mohammedia',
  'Nador',
  'Oujda',
  'Rabat',
  'Safi',
  'Sale',
  'Settat',
  'Tanger',
  'Temara',
  'Tetouan',
  'Tiznit',
];

const _artisanSpecialties = [
  'Plomberie',
  'Electricite',
  'Maconnerie',
  'Platrerie / Staff',
  'Etancheite',
  'Isolation thermique & phonique',
  'Demolition',
  'Renovation generale',
  'Climatisation',
  'Domotique',
  'Reparation electromenager',
  'Installation TV / Satellite',
  'Panneaux solaires',
  'Peinture',
  'Carrelage',
  'Menuiserie',
  'Serrurerie',
  'Jardinage',
  'Nettoyage',
];
