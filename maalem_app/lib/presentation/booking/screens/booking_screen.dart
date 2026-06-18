import 'package:flutter/material.dart';
import 'package:maalem_app/shared/widgets/maalem_app_bar.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/auth_provider.dart'; // <-- 1. IMPORT DE L'AUTHPROVIDER DE FATIMA
import 'package:maalem_app/presentation/main_shell.dart';

class BookingScreen extends StatefulWidget {
  final int artisanId; // L'artisan qu'on veut réserver
  final String artisanName;
  final double hourlyRate;

  const BookingScreen({
    super.key,
    required this.artisanId,
    required this.artisanName,
    required this.hourlyRate,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;

  // Fonction pour ouvrir le calendrier
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0C2C55), // Bleu Nuit pour le calendrier
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 2. MODIFICATION DE LA FONCTION : Elle accepte maintenant le vrai userId
  void _submitBooking() async {
    // 1. On vérifie que les champs sont remplis
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      print("❌ Erreur : La date n'a pas été sélectionnée.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez choisir une date.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 4. RÉCUPÉRATION DU VRAI USER ID VIA L'AUTHPROVIDER
    final int? userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur non connecté. Veuillez vous reconnecter.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print(
        "✅ Formulaire valide ! Préparation de l'envoi pour le client ID : $userId");

    // 4. On appelle le Provider
    final success =
        await Provider.of<BookingProvider>(context, listen: false).addBooking(
      userId,
      widget.artisanId,
      _descriptionController.text,
      widget.hourlyRate,
      _selectedDate!,
    );

    if (!mounted) return;

    // 5. Résultat
    if (success) {
      // On redirige vers le MainShell avec l'index de l'onglet "Suivi" (qui est 1)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainShell(
            initialIndex: 1,
            successMessage: 'Réservation envoyée avec succès ! ✅',
          ),
        ),
        (route) => false,
      );
    } else {
      final errorMessage =
          Provider.of<BookingProvider>(context, listen: false).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage.isEmpty
                ? 'Erreur lors de la réservation ❌'
                : errorMessage,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkBlue = Color(0xFF0C2C55);
    const Color primaryTeal = Color(0xFF296374);
    const Color bgColor = Color(0xFFF1F3E1);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: MaalemAppBar(
        title: 'Réserver',
        subtitle: widget.artisanName,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Récapitulatif de l'artisan
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: primaryTeal.withValues(alpha: 0.2),
                      child: const Icon(Icons.person,
                          size: 30, color: primaryTeal),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.artisanName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryDarkBlue)),
                          const SizedBox(height: 4),
                          Text('Tarif estimé : ${widget.hourlyRate} MAD',
                              style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Description du besoin
              const Text('Décrivez votre besoin',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryDarkBlue)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Ex: Bonjour, j\'ai une fuite sous l\'évier de la cuisine...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Veuillez décrire votre problème' : null,
              ),
              const SizedBox(height: 30),

              // Choix de la date
              const Text('Date d\'intervention souhaitée',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryDarkBlue)),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Sélectionner une date'
                            : _selectedDate!.toString().substring(0, 10),
                        style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate == null
                                ? Colors.grey
                                : Colors.black),
                      ),
                      const Icon(Icons.calendar_today, color: primaryTeal),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Bouton de validation
              // Bouton de validation
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),

                  // --- LA CORRECTION EST EXACTEMENT ICI 👇 ---
                  onPressed: Provider.of<BookingProvider>(context).isLoading
                      ? null
                      : _submitBooking, // Sans parenthèses ni arguments !
                  // ------------------------------------------

                  child: Provider.of<BookingProvider>(context).isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirmer la réservation',
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
