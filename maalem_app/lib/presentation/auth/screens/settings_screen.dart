import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.beige.withOpacity(0.8),
            floating: true,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: AppColors.navy, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Paramètres',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            actions: [
              IconButton(
                icon:
                    const Icon(Icons.notifications_none, color: AppColors.navy),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Compte',
                    [
                      _buildRow(
                          Icons.person_outline, 'Informations personnelles'),
                      _buildRow(Icons.security_outlined, 'Sécurité'),
                      _buildRow(Icons.language_outlined, 'Langue',
                          trailingText: 'Français'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    'Préférences',
                    [
                      _buildRow(
                          Icons.notifications_active_outlined, 'Notifications'),
                      _buildRow(Icons.lock_outline, 'Confidentialité'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    'Paiement',
                    [
                      _buildRow(Icons.payments_outlined, 'Modes de paiement'),
                      _buildRow(Icons.receipt_long_outlined,
                          'Historique de facturation'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSection(
                    'Support',
                    [
                      _buildRow(Icons.help_center_outlined, 'Centre d\'aide',
                          isExternal: true),
                      _buildRow(Icons.info_outline, 'À propos'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFBA1A1A),
                            side: const BorderSide(color: Color(0x33BA1A1A)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Supprimer le compte',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Version 2.4.0 (2024)',
                          style: TextStyle(
                            color: AppColors.navy.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Column(
              children: items,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(IconData icon, String label,
      {String? trailingText, bool isExternal = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.navy.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.navy, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (trailingText != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      trailingText,
                      style: TextStyle(
                        color: AppColors.navy.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ),
                Icon(
                  isExternal ? Icons.open_in_new : Icons.chevron_right,
                  color: AppColors.navy.withOpacity(0.4),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
