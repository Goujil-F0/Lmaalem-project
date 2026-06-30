import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:maalem_app/shared/widgets/profile_avatar.dart';
import 'package:provider/provider.dart';

/// AppBar unifiee pour toutes les pages de l'application Lmaalem.
class MaalemAppBar extends StatefulWidget implements PreferredSizeWidget {
  static const double _height = 64;

  /// Titre affiche au centre de l'AppBar.
  final String title;

  /// Sous-titre optionnel.
  final String? subtitle;

  /// Widgets d'action a droite.
  final List<Widget>? actions;

  /// Affiche un bouton retour si true, sinon affiche le logo.
  final bool showBackButton;

  /// Widget personnalise a gauche.
  final Widget? leading;

  /// Luminosite de la barre de statut.
  final Brightness statusBarBrightness;

  const MaalemAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = false,
    this.leading,
    this.statusBarBrightness = Brightness.light,
  });

  @override
  Size get preferredSize => const Size.fromHeight(_height);

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
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
    final showBack =
        widget.showBackButton || (canPop && widget.leading == null);

    return AppBar(
      toolbarHeight: MaalemAppBar._height,
      backgroundColor: _appBarColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: widget.statusBarBrightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: widget.statusBarBrightness,
      ),
      automaticallyImplyLeading: false,
      flexibleSpace: _AppBarBackground(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Row(
              children: [
                _buildLeading(context, showBack),
                const SizedBox(width: 10),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _TitleCapsule(
                        title: _displayedTitle,
                        subtitle: widget.subtitle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.actions != null && widget.actions!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.actions!.map((action) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          iconTheme: const IconThemeData(
                            color: AppColors.navy,
                            size: 22,
                          ),
                          iconButtonTheme: IconButtonThemeData(
                            style: IconButton.styleFrom(
                              foregroundColor: AppColors.navy,
                              backgroundColor:
                                  AppColors.navy.withValues(alpha: 0.05),
                              shape: const CircleBorder(),
                            ),
                          ),
                        ),
                        child: action,
                      );
                    }).toList(),
                  )
                else
                  const SizedBox(width: 44),
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
        width: 44,
        height: 44,
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

    return const _CurrentUserAvatar();
  }
}

final Color _appBarColor = Color.alphaBlend(
  AppColors.white.withValues(alpha: 0.36),
  AppColors.beige,
);

class _TitleCapsule extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _TitleCapsule({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: EdgeInsets.symmetric(
          horizontal: subtitle == null ? 18 : 16,
          vertical: subtitle == null ? 7 : 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.72)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.navy.withValues(alpha: 0.58),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrentUserAvatar extends StatelessWidget {
  const _CurrentUserAvatar();

  @override
  Widget build(BuildContext context) {
    final user =
        context.select<AuthProvider, ({String name, String? photoUrl})>(
      (auth) => (
        name: auth.user?.fullName ?? 'Lmaalem',
        photoUrl: auth.user?.photoUrl,
      ),
    );

    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.16)),
      ),
      child: ProfileAvatar(
        name: user.name,
        imageUrl: user.photoUrl,
        size: 40,
        borderRadius: 12,
        backgroundColor: AppColors.navy,
        textStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AppBarBackground extends StatelessWidget {
  final Widget child;

  const _AppBarBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _appBarColor,
        border: Border(
          bottom: BorderSide(color: AppColors.teal.withValues(alpha: 0.12)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

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
        color: AppColors.navy.withValues(alpha: 0.05),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: AppColors.navy, size: 20),
          ),
        ),
      ),
    );
  }
}
