import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';

/// AppBar unifiée pour toutes les pages de l'application Lmaalem.
///
/// - Fond : dégradé subtil navy → teal
/// - Logo "L" animé à gauche (ou bouton retour si [showBackButton] est true)
/// - Titre centré avec animation de fondu au changement
/// - Actions optionnelles à droite
/// - Hauteur fixe kToolbarHeight + safe area
class MaalemAppBar extends StatefulWidget implements PreferredSizeWidget {
  /// Titre affiché au centre de l'AppBar
  final String title;

  /// Sous-titre optionnel (ligne plus petite sous le titre)
  final String? subtitle;

  /// Widgets d'action (icônes à droite)
  final List<Widget>? actions;

  /// Affiche un bouton retour si true (sinon affiche le logo "L")
  final bool showBackButton;

  /// Widget personnalisé à gauche (ex: avatar utilisateur)
  final Widget? leading;

  /// Couleur de fond de la barre de statut (pour SystemOverlayStyle)
  final Brightness statusBarBrightness;

  const MaalemAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.leading,
    this.statusBarBrightness = Brightness.dark,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<MaalemAppBar> createState() => _MaalemAppBarState();
}

class _MaalemAppBarState extends State<MaalemAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _displayedTitle = '';

  @override
  void initState() {
    super.initState();
    _displayedTitle = widget.title;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(MaalemAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      _controller.reset();
      setState(() => _displayedTitle = widget.title);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final showBack = widget.showBackButton || (canPop && widget.leading == null);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      // On gère le leading manuellement
      automaticallyImplyLeading: false,
      flexibleSpace: _AppBarBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // --- LEADING ---
                _buildLeading(context, showBack),
                const SizedBox(width: 8),

                // --- TITRE CENTRÉ ---
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _displayedTitle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              widget.subtitle!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.72),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // --- ACTIONS ---
                const SizedBox(width: 8),
                if (widget.actions != null && widget.actions!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.actions!.map((action) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          iconTheme: const IconThemeData(color: AppColors.white),
                        ),
                        child: action,
                      );
                    }).toList(),
                  )
                else
                  // Espace équivalent pour centrer le titre
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context, bool showBack) {
    if (widget.leading != null) {
      return SizedBox(
        width: 48,
        height: 48,
        child: widget.leading,
      );
    }

    if (showBack) {
      return _AppBarIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.of(context).pop(),
        tooltip: 'Retour',
      );
    }

    // Logo "L" Lmaalem
    return _LogoBadge();
  }
}

/// Fond dégradé de l'AppBar avec effet de brillance subtile
class _AppBarBackground extends StatelessWidget {
  final Widget child;
  const _AppBarBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navy,
            Color(0xFF1A4A6A), // intermédiaire navy-teal
            AppColors.teal,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Bouton icône adapté au thème AppBar
class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _AppBarIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: AppColors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Badge logo "L" stylisé Lmaalem
class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'L',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
