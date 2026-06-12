// lib/presentation/booking/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/booking_model.dart';
import '../../dashboard/screens/complaint_screen.dart';
import '../../dashboard/screens/review_screen.dart';
import '../../search/screens/map_screen.dart';
import 'chat_screen.dart';
import 'package:maalem_app/presentation/main_shell.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Gère l'onglet sélectionné
  String _selectedTab = 'En cours';

  @override
  void initState() {
    super.initState();
    // On charge l'historique au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user!.id; // Le vrai ID
      final userRole = authProvider.user!.role; // 'client' ou 'artisan'

      Provider.of<BookingProvider>(context, listen: false)
          .fetchBookingHistory(userId, userRole);
    });
  }

  // Fonction mise à jour avec les statuts exacts de Wissal
  List<Booking> _getFilteredBookings(List<Booking> allBookings) {
    if (_selectedTab == 'En cours') {
      return allBookings
          .where((b) => b.status == 'pending' || b.status == 'accepted')
          .toList();
    } else if (_selectedTab == 'Terminé') {
      return allBookings
          .where((b) => b.status == 'completed' || b.status == 'paid_cash')
          .toList();
    } else if (_selectedTab == 'Annulé') {
      // On inclut rejected (refusé par l'artisan) et cancelled (annulé par le client)
      return allBookings
          .where((b) => b.status == 'cancelled' || b.status == 'rejected')
          .toList();
    }
    return allBookings;
  }

  @override
  Widget build(BuildContext context) {
    // Les couleurs exactes de votre maquette
    const Color bgColor = Color(0xFFF1F3E1); // Le beige clair du fond
    const Color primaryDarkBlue = Color(0xFF0C2C55); // Le bleu nuit du texte
    const Color primaryTeal = Color(0xFF296374); // Le bleu canard des boutons

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 1. Titre "Mon suivi"
              const Text(
                'Mon suivi',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryDarkBlue,
                ),
              ),
              const SizedBox(height: 20),

              // 2. Barre de recherche
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Rechercher un projet...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Les filtres (En cours, Terminé, Annulé)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTabButton('En cours', primaryTeal),
                    _buildTabButton('Terminé', primaryTeal),
                    _buildTabButton('Annulé', primaryTeal),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Liste des résultats ou État vide (Connecté au Provider)
              Expanded(
                child: Consumer<BookingProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(
                          child: CircularProgressIndicator(color: primaryTeal));
                    }

                    // On filtre la liste selon l'onglet choisi
                    final filteredBookings =
                        _getFilteredBookings(provider.bookings);

                    // S'il n'y a pas de projet dans cet onglet (L'état vide de ta maquette)
                    if (filteredBookings.isEmpty) {
                      return _buildEmptyState(primaryDarkBlue, primaryTeal);
                    }

                    // S'il y a des projets, on affiche de jolies cartes
                    return ListView.builder(
                      itemCount: filteredBookings.length,
                      itemBuilder: (context, index) {
                        final booking = filteredBookings[index];
                        return _buildBookingCard(
                            booking, primaryDarkBlue, primaryTeal);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS REUTILISABLES POUR CET ECRAN --- //

  // Création d'un bouton d'onglet (Tab)
  Widget _buildTabButton(String title, Color activeColor) {
    bool isActive = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF0C2C55),
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Création de la vue quand il n'y a pas de réservation
  Widget _buildEmptyState(Color titleColor, Color buttonColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(
                        Icons.assignment_outlined,
                        color: buttonColor,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Aucun projet ${_selectedTab.toLowerCase()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Vous n'avez pas encore de travaux lancés dans cette catégorie.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MapScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_circle, color: Colors.white),
                        label: const Text(
                          'Déclarer mon besoin',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Version finale de la carte avec Navigation ET Paiement Espèces
  // Version Finale avec gestion des Rôles (Client / Artisan)
  Widget _buildBookingCard(
      Booking booking, Color titleColor, Color priceColor) {
    // 1. On récupère le rôle de la personne connectée
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole =
        authProvider.user?.role ?? 'client'; // 'client' ou 'artisan'
    final personName = userRole == 'artisan'
        ? booking.clientName
        : booking.artisanName;
    final cardTitle = personName != null && personName.trim().isNotEmpty
        ? personName.trim()
        : 'Service #${booking.id}';

    // --- GESTION DU VISUEL DES STATUTS ---
    String statusText = '';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;

    if (booking.status == 'pending') {
      statusText = 'En attente de l\'artisan';
      statusColor = Colors.orange;
      statusIcon = Icons.access_time;
    } else if (booking.status == 'accepted') {
      statusText = 'Artisan en route / En cours';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (booking.status == 'completed' || booking.status == 'paid_cash') {
      statusText = booking.status == 'paid_cash'
          ? 'Payé en espèces'
          : 'Projet terminé';
      statusColor = Colors.blue;
      statusIcon = booking.status == 'paid_cash'
          ? Icons.qr_code_scanner
          : Icons.done_all;
    } else {
      statusText = 'Projet annulé/refusé';
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    // --- CRÉATION DU MENU (Les 3 petits points) SELON LE RÔLE ---
    List<PopupMenuEntry<String>> menuOptions = [];

    // Option A : L'ARTISAN valide le paiement (seulement si le projet est en cours)
    if (userRole == 'artisan' && booking.status == 'pending') {
      menuOptions.add(
        const PopupMenuItem<String>(
          value: 'accept_booking',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Accepter la demande'),
            ],
          ),
        ),
      );
      menuOptions.add(
        const PopupMenuItem<String>(
          value: 'reject_booking',
          child: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text('Refuser la demande'),
            ],
          ),
        ),
      );
    }

    // Option B : L'ARTISAN valide le paiement (seulement si le projet est EN COURS)
    if (userRole == 'artisan' && booking.status == 'accepted') {
      menuOptions.add(
        const PopupMenuItem<String>(
          value: 'pay_cash',
          child: Row(
            children: [
              Icon(Icons.payments_outlined, color: Colors.green),
              SizedBox(width: 8),
              Text('Confirmer paiement cash'),
            ],
          ),
        ),
      );
    }

    // Option B : LE CLIENT laisse un avis (seulement si le projet est terminé)
    if (userRole == 'client' &&
        (booking.status == 'completed' || booking.status == 'paid_cash') &&
        !booking.hasReview) {
      menuOptions.add(
        const PopupMenuItem<String>(
          value: 'review',
          child: Row(
            children: [
              Icon(Icons.star_border, color: Colors.orange),
              SizedBox(width: 8),
              Text('Évaluer l\'artisan'),
            ],
          ),
        ),
      );
    }

    // Option C : LE CLIENT fait une réclamation seulement après acceptation.
    if (userRole == 'client' &&
        (booking.status == 'accepted' ||
            booking.status == 'completed' ||
            booking.status == 'paid_cash')) {
      menuOptions.add(
        const PopupMenuItem<String>(
          value: 'complaint',
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Faire une réclamation'),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        final currentUserId = context.read<AuthProvider>().user?.id;
        if (booking.id == null || currentUserId == null) return;

        // Navigation fluide vers le chat au clic sur la carte
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              bookingId: booking.id!,
              currentUserId: currentUserId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  cardTitle,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: titleColor),
                ),

                // On affiche les 3 points UNIQUEMENT si on a des options à proposer !
                if (menuOptions.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
                    onSelected: (value) async {
                      // --- NOUVELLES ACTIONS ARTISAN ---
                      if (value == 'accept_booking') {
                        final ok = await Provider.of<BookingProvider>(context,
                                listen: false)
                            .changeBookingStatus(booking.id!, 'accepted');
                        if (!mounted) return;
                        if (!ok) {
                          final error = Provider.of<BookingProvider>(context,
                                  listen: false)
                              .errorMessage;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Réservation acceptée ! L'artisan est en route ✅"),
                              backgroundColor: Colors.green),
                        );
                      } else if (value == 'reject_booking') {
                        final ok = await Provider.of<BookingProvider>(context,
                                listen: false)
                            .changeBookingStatus(booking.id!, 'rejected');
                        if (!mounted) return;
                        if (!ok) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Réservation refusée."),
                              backgroundColor: Colors.red),
                        );
                      }
                      // Action : Payer
                      if (value == 'pay_cash') {
                        final ok = await Provider.of<BookingProvider>(context,
                                listen: false)
                            .changeBookingStatus(booking.id!, 'paid_cash');

                        if (!mounted) return;
                        if (!ok) {
                          final error = Provider.of<BookingProvider>(context,
                                  listen: false)
                              .errorMessage;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Paiement cash confirmé. Commission déduite du wallet."),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      // Action : Évaluer
                      else if (value == 'review') {
                        _openReview(booking); // Appelle la fonction de Wissal !
                      }
                      // Action : Réclamation
                      else if (value == 'complaint') {
                        _openComplaint(
                            booking); // Appelle la fonction de Wissal !
                      }
                    },
                    itemBuilder: (BuildContext context) => menuOptions,
                  )
                else
                  const SizedBox(width: 24, height: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(booking.description, style: const TextStyle(fontSize: 15)),

            const SizedBox(height: 12),

            // Le Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.bookingDate.toString().substring(0, 10),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  '${booking.agreedPrice.toStringAsFixed(0)} MAD',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: priceColor),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _openReview(Booking booking) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          bookingId: booking.id!,
          artisanId: booking.artisanId,
          artisanName: booking.artisanName ?? 'Artisan #${booking.artisanId}',
        ),
      ),
    );

    if (saved == true && mounted) {
      Provider.of<BookingProvider>(context, listen: false)
          .markBookingReviewed(booking.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre avis est enregistré. Merci !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _openComplaint(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintScreen(
          bookingId: booking.id!,
          artisanId: booking.artisanId,
        ),
      ),
    );
  }
}
