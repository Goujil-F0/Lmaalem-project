// lib/presentation/booking/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Pour l'appel téléphonique
import '../../../providers/booking_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/booking_model.dart';
import 'chat_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Les deux nouveaux onglets de la maquette
  String _selectedTab = 'En cours';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        Provider.of<BookingProvider>(context, listen: false)
            .fetchBookingHistory(auth.user!.id, auth.user!.role);
      }
    });
  }

  // Filtrage simplifié pour les deux onglets de la maquette
  List<Booking> _getFilteredBookings(List<Booking> allBookings) {
    if (_selectedTab == 'En cours') {
      return allBookings
          .where((b) => b.status == 'pending' || b.status == 'accepted')
          .toList();
    } else {
      // Historique
      return allBookings
          .where((b) =>
              b.status == 'completed' ||
              b.status == 'cancelled' ||
              b.status == 'rejected')
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF1F3E1); // Beige de la maquette
    const Color primaryDarkBlue = Color(0xFF0C2C55);
    const Color primaryTeal = Color(0xFF296374);

    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role ?? 'client';

    return Scaffold(
      backgroundColor: bgColor,
      // On masque l'appBar classique pour créer la notre, plus moderne
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER (Titre Mon Suivi)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Mon Suivi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryDarkBlue,
                ),
              ),
            ),

            // 2. ONGLETS (Tabs en forme de pilule selon la maquette)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    _buildPillTab('En cours', primaryTeal),
                    _buildPillTab('Historique', primaryTeal),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. LISTE DES CARTES
            Expanded(
              child: Consumer<BookingProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                        child: CircularProgressIndicator(color: primaryTeal));
                  }

                  final filteredBookings =
                      _getFilteredBookings(provider.bookings);

                  if (filteredBookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open,
                              size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            userRole == 'client'
                                ? 'Aucun projet pour le moment.'
                                : 'Aucune demande client en attente.',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 16),
                          ),
                          const SizedBox(height: 24),

                          // LE BOUTON S'AFFICHE UNIQUEMENT POUR LE CLIENT !
                          if (userRole == 'client')
                            SizedBox(
                              width: 250,
                              height: 50,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryTeal,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  // Naviguer vers l'accueil pour faire une demande
                                  Navigator.of(context)
                                      .popUntil((route) => route.isFirst);
                                },
                                icon: const Icon(Icons.add_circle,
                                    color: Colors.white),
                                label: const Text('Déclarer un besoin',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      return _buildBookingCard(filteredBookings[index],
                          userRole, primaryDarkBlue, primaryTeal);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS REUTILISABLES ---

  // Onglet Pilule
  Widget _buildPillTab(String title, Color activeColor) {
    bool isActive = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = title),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _openReview(Booking booking) {
    // Plus tard : Navigator.push vers l'écran Review de Wissal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ouverture de la page d'avis...")),
    );
  }

  void _openComplaint(Booking booking) {
    // Plus tard : Navigator.push vers l'écran Réclamation de Wissal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ouverture de la page réclamation...")),
    );
  }

  // La Carte de réservation (Design Maquette)
  Widget _buildBookingCard(
      Booking booking, String role, Color titleColor, Color buttonColor) {
    bool isClient = role == 'client';

    String displayName = booking.otherPartyName;
    String tagLabel = isClient ? 'PLOMBERIE' : 'DEMANDE CLIENT';

    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (booking.status == 'pending') {
      statusText = 'En attente';
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.withOpacity(0.1);
    } else if (booking.status == 'accepted') {
      statusText = 'Confirmé';
      statusColor = Colors.blue;
      statusBgColor = Colors.blue.withOpacity(0.1);
    } else if (booking.status == 'completed') {
      statusText = 'Terminé';
      statusColor = Colors.green;
      statusBgColor = Colors.green.withOpacity(0.1);
    } else {
      statusText = 'Annulé';
      statusColor = Colors.red;
      statusBgColor = Colors.red.withOpacity(0.1);
    }

    String dateStr = booking.bookingDate.toString().substring(0, 10);
    String timeStr = "10:30";

    // --- LOGIQUE DU MENU (3 petits points) ---
    List<PopupMenuEntry<String>> menuOptions = [];

    if (isClient) {
      // Pour le Client
      if (booking.status == 'pending' ||
          booking.status == 'accepted' ||
          booking.status == 'completed') {
        menuOptions.add(const PopupMenuItem<String>(
          value: 'complaint',
          child: Row(children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Réclamation')
          ]),
        ));
      }
      if (booking.status == 'completed') {
        menuOptions.add(const PopupMenuItem<String>(
          value: 'review',
          child: Row(children: [
            Icon(Icons.star_border, color: Colors.orange),
            SizedBox(width: 8),
            Text('Évaluer')
          ]),
        ));
      }
    } else {
      // Pour l'Artisan
      if (booking.status == 'pending') {
        menuOptions.add(const PopupMenuItem<String>(
          value: 'accept_booking',
          child: Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('Accepter')
          ]),
        ));
        menuOptions.add(const PopupMenuItem<String>(
          value: 'reject_booking',
          child: Row(children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Refuser')
          ]),
        ));
      } else if (booking.status == 'accepted') {
        menuOptions.add(const PopupMenuItem<String>(
          value: 'pay_cash',
          child: Row(children: [
            Icon(Icons.payments_outlined, color: Colors.green),
            SizedBox(width: 8),
            Text('Marquer payé')
          ]),
        ));
      }
    }
    // ------------------------------------------

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    buttonColor.withOpacity(0.1), // Un fond bleu clair
                child: Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?', // Affiche la 1ère lettre !
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: buttonColor,
                      fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: titleColor)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(tagLabel,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: titleColor)),
                    ),
                  ],
                ),
              ),
              // Badge Statut
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              // Menu 3 petits points (s'affiche uniquement s'il y a des options)
              if (menuOptions.isNotEmpty)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  onSelected: (value) async {
                    if (value == 'complaint')
                      _openComplaint(booking);
                    else if (value == 'review')
                      _openReview(booking);
                    else if (value == 'accept_booking') {
                      await Provider.of<BookingProvider>(context, listen: false)
                          .changeBookingStatus(booking.id!, 'accepted');
                    } else if (value == 'reject_booking') {
                      await Provider.of<BookingProvider>(context, listen: false)
                          .changeBookingStatus(booking.id!, 'rejected');
                    } else if (value == 'pay_cash') {
                      await Provider.of<BookingProvider>(context, listen: false)
                          .changeBookingStatus(booking.id!, 'completed');
                    }
                  },
                  itemBuilder: (BuildContext context) => menuOptions,
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
          ),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 20, color: titleColor),
              const SizedBox(width: 8),
              Text(dateStr, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(width: 20),
              Icon(Icons.access_time, size: 20, color: titleColor),
              const SizedBox(width: 8),
              Text(timeStr, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                  bookingId: booking.id!,
                                  currentUserId: Provider.of<AuthProvider>(
                                          context,
                                          listen: false)
                                      .user!
                                      .id)));
                    },
                    icon: Badge(
                      isLabelVisible: booking.unreadCount >
                          0, // S'affiche seulement s'il y a des messages
                      label: Text(
                        booking.unreadCount.toString(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.chat_bubble_outline,
                          color: Colors.white),
                    ),
                    label: const Text('Message',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 50,
                width: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  onPressed: () async {
                    final Uri callUri = Uri.parse('tel:+212600000000');
                    if (await canLaunchUrl(callUri)) await launchUrl(callUri);
                  },
                  child: Icon(Icons.call_outlined, color: buttonColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
