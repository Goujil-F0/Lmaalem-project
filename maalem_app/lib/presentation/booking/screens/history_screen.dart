// lib/presentation/booking/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Pour l'appel téléphonique
import '../../../providers/booking_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/services/dashboard_service.dart';
import '../../dashboard/screens/complaint_screen.dart';
import '../../dashboard/screens/review_screen.dart';
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

  // Filtrage simplifié pour les onglets de la maquette
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
    const Color bgColor = Color(0xFFF1F3E1); // Beige de la maquette
    const Color primaryDarkBlue = Color(0xFF0C2C55);
    const Color primaryTeal = Color(0xFF296374);

    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role ?? 'client';

    return Scaffold(
      backgroundColor: bgColor,
      // On masque l'appBar classique pour créer la notre, plus moderne
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 1. Titre "Mon suivi" (+ bouton de retour/sortie si standalone)
              Row(
                children: [
                  if (Navigator.canPop(context)) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: primaryDarkBlue, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Text(
                    'Mon suivi',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryDarkBlue,
                    ),
                  ),
                ],
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

                  final filteredBookings =
                      _getFilteredBookings(provider.bookings);

                  if (filteredBookings.isEmpty) {
                    return _buildEmptyState(primaryDarkBlue, primaryTeal);
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
      ),
    );
  }

  // --- WIDGETS REUTI  // Création d'un bouton d'onglet (Tab)
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
                          Navigator.of(context).popUntil((route) => route.isFirst);
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

  // La Carte de réservation (Design Maquette avec vos fonctionnalités de réclamation/avis/wallet)
  Widget _buildBookingCard(
      Booking booking, String role, Color titleColor, Color buttonColor) {
    bool isClient = role == 'client';

    String displayName = booking.otherPartyName;
    if (displayName.isEmpty || displayName == 'Utilisateur Inconnu') {
      final personName = isClient ? booking.artisanName : booking.clientName;
      displayName = personName ?? 'Service #${booking.id}';
    }
    String tagLabel = isClient ? 'PLOMBERIE' : 'DEMANDE CLIENT';

    // --- GESTION DU VISUEL DES STATUTS ---
    String statusText = '';
    Color statusColor = Colors.grey;
    Color statusBgColor = Colors.grey.withOpacity(0.1);

    if (booking.status == 'pending') {
      statusText = 'En attente';
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.withOpacity(0.1);
    } else if (booking.status == 'accepted') {
      statusText = 'Artisan en route / En cours';
      statusColor = Colors.green;
      statusBgColor = Colors.green.withOpacity(0.1);
    } else if (booking.status == 'completed' || booking.status == 'paid_cash') {
      statusText = booking.status == 'paid_cash' ? 'Payé en espèces' : 'Projet terminé';
      statusColor = Colors.blue;
      statusBgColor = Colors.blue.withOpacity(0.1);
    } else {
      statusText = 'Projet annulé/refusé';
      statusColor = Colors.red;
      statusBgColor = Colors.red.withOpacity(0.1);
    }

    // --- CRÉATION DU MENU (Les 3 petits points) SELON LE RÔLE ---
    List<PopupMenuEntry<String>> menuOptions = [];

    if (!isClient && booking.status == 'pending') {
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

    if (!isClient && booking.status == 'accepted') {
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

    if (isClient &&
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

    if (isClient &&
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

    String dateStr = booking.bookingDate.toString().substring(0, 10);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: buttonColor.withOpacity(0.1),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
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
                    if (value == 'complaint') {
                      _openComplaint(booking);
                    } else if (value == 'review') {
                      _openReview(booking);
                    } else if (value == 'accept_booking') {
                      await _acceptBookingWithWalletCheck(booking);
                    } else if (value == 'reject_booking') {
                      final ok = await Provider.of<BookingProvider>(context, listen: false)
                          .changeBookingStatus(booking.id!, 'rejected');
                      if (!mounted) return;
                      if (ok) {
                        _showSuccess("Réservation refusée.");
                      } else {
                        _showError(Provider.of<BookingProvider>(context, listen: false).errorMessage);
                      }
                    } else if (value == 'pay_cash') {
                      final ok = await Provider.of<BookingProvider>(context, listen: false)
                          .changeBookingStatus(booking.id!, 'paid_cash');
                      if (!mounted) return;
                      if (ok) {
                        _showSuccess("Paiement cash confirmé. Commission déduite du wallet.");
                      } else {
                        _showError(Provider.of<BookingProvider>(context, listen: false).errorMessage);
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) => menuOptions,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(booking.description, style: const TextStyle(fontSize: 15)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 20, color: titleColor),
                  const SizedBox(width: 8),
                  Text(dateStr, style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(width: 20),
                  Icon(Icons.payments_outlined, size: 20, color: titleColor),
                  const SizedBox(width: 8),
                  Text('${booking.agreedPrice.toStringAsFixed(0)} MAD',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: titleColor)),
                ],
              ),
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
                                .id,
                          ),
                        ),
                      );
                    },
                    icon: Badge(
                      isLabelVisible: booking.unreadCount > 0,
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

  Future<void> _acceptBookingWithWalletCheck(Booking booking) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final ok = await provider.changeBookingStatus(booking.id!, 'accepted');

    if (!mounted) return;
    if (ok) {
      _showSuccess("Réservation acceptée ! L'artisan est en route.");
      return;
    }

    final error = provider.errorMessage;
    if (!_isWalletError(error)) {
      _showError(error);
      return;
    }

    final recharged = await _showWalletRechargeDialog(
      artisanId: booking.artisanId,
      message: error,
    );

    if (!mounted || recharged != true) return;

    final retryOk = await provider.changeBookingStatus(booking.id!, 'accepted');
    if (!mounted) return;

    if (retryOk) {
      _showSuccess('Wallet rechargé. Réservation acceptée !');
    } else {
      _showError(provider.errorMessage);
    }
  }

  bool _isWalletError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('wallet') &&
        (normalized.contains('insuffisant') ||
            normalized.contains('recharge'));
  }

  Future<bool?> _showWalletRechargeDialog({
    required int artisanId,
    required String message,
  }) async {
    final amountController = TextEditingController(text: '100');
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    if (token == null || token.isEmpty) {
      _showError('Utilisateur non connecté.');
      amountController.dispose();
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var isRecharging = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> recharge(double amount) async {
              if (amount <= 0) {
                _showError('Montant de recharge invalide.');
                return;
              }

              setDialogState(() => isRecharging = true);

              try {
                final service = DashboardService(token: token);
                await service.rechargeWallet(artisanId, amount);

                Navigator.of(dialogContext).pop(true);
              } catch (e) {
                if (!mounted) return;
                _showError(e.toString().replaceFirst('Exception: ', ''));
                setDialogState(() => isRecharging = false);
              }
            }

            return AlertDialog(
              title: const Text('Recharge wallet requise'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant',
                        suffixText: 'MAD',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('50 MAD'),
                          selected: amountController.text == '50',
                          onSelected: isRecharging
                              ? null
                              : (_) {
                                  setDialogState(() {
                                    amountController.text = '50';
                                  });
                                },
                        ),
                        ChoiceChip(
                          label: const Text('100 MAD'),
                          selected: amountController.text == '100',
                          onSelected: isRecharging
                              ? null
                              : (_) {
                                  setDialogState(() {
                                    amountController.text = '100';
                                  });
                                },
                        ),
                        ChoiceChip(
                          label: const Text('200 MAD'),
                          selected: amountController.text == '200',
                          onSelected: isRecharging
                              ? null
                              : (_) {
                                  setDialogState(() {
                                    amountController.text = '200';
                                  });
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isRecharging
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: isRecharging
                      ? null
                      : () {
                          final amount =
                              double.tryParse(amountController.text.trim()) ??
                                  0;
                          recharge(amount);
                        },
                  icon: isRecharging
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.account_balance_wallet_outlined),
                  label: Text(
                      isRecharging ? 'Recharge...' : 'Recharger et accepter'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    return result;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
