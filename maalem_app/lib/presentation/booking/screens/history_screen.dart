// lib/presentation/booking/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/booking_model.dart';
import '../../dashboard/screens/complaint_screen.dart';
import '../../dashboard/screens/review_screen.dart';
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
      return allBookings.where((b) => b.status == 'completed').toList();
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
                          // Retourne à la page principale (Accueil) et vide l'historique de navigation
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MainShell()),
                            (route) => false,
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
  Widget _buildBookingCard(
      Booking booking, Color titleColor, Color priceColor) {
    final authUser = context.read<AuthProvider>().user;
    final currentUserId = authUser?.id ?? booking.clientId;
    final isClient = authUser?.role == 'client';
    final canComplain = isClient &&
        booking.id != null &&
        (booking.status == 'accepted' || booking.status == 'completed');
    final canReview =
        isClient && booking.id != null && booking.status == 'completed';

    return GestureDetector(
      onTap: () {
        if (booking.id == null) return;
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
                  'Service #${booking.id}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: titleColor),
                ),

                // --- LE NOUVEAU MENU DES 3 POINTS ---
                if (booking.status == 'pending' || booking.status == 'accepted')
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
                    onSelected: (value) async {
                      if (value == 'pay_cash') {
                        // 1. Appel du Provider pour passer au statut "completed"
                        await Provider.of<BookingProvider>(context,
                                listen: false)
                            .changeBookingStatus(booking.id!, 'completed');

                        // 2. Affichage d'un petit message de succès en bas de l'écran
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Paiement validé. Projet terminé ! ✅"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'pay_cash',
                        child: Row(
                          children: [
                            Icon(Icons.payments_outlined, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Paiement en espèces'),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  // Si le projet est annulé ou terminé, on ne met rien à la place des 3 points
                  const SizedBox(width: 24, height: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(booking.description, style: const TextStyle(fontSize: 15)),
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
            ),
            if (canComplain || canReview) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (canReview)
                    OutlinedButton.icon(
                      onPressed: () => _openReview(booking),
                      icon: const Icon(Icons.star_outline, size: 18),
                      label: const Text('Laisser un avis'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: priceColor,
                        side: BorderSide(color: priceColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  if (canComplain)
                    TextButton.icon(
                      onPressed: () => _openComplaint(booking),
                      icon: const Icon(
                        Icons.report_problem_outlined,
                        size: 18,
                      ),
                      label: const Text('Réclamation'),
                      style: TextButton.styleFrom(
                        foregroundColor: titleColor,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openReview(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          bookingId: booking.id!,
          artisanId: booking.artisanId,
          artisanName: 'Artisan #${booking.artisanId}',
        ),
      ),
    );
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
