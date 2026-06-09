import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/auth_provider.dart'; // <-- 1. IMPORT DE L'AUTHPROVIDER DE FATIMA
import 'history_screen.dart';

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
      print("❌ Erreur : Le champ description est vide.");
      return;
    }
    if (_selectedDate == null) {
      print("❌ Erreur : La date n'a pas été sélectionnée.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez choisir une date.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    print("✅ Formulaire valide ! Préparation de l'envoi...");

    // 2. On récupère ton VRAI ID grâce au provider de Fatima
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Si tu testes l'écran directement sans être connecté, on met 1 par défaut, sinon on prend ton vrai ID
    final int myUserId = authProvider.user != null ? authProvider.user!.id : 1;

    print("👤 Tentative de réservation pour le client ID : $myUserId");

    // 3. On envoie au backend
    final success =
        await Provider.of<BookingProvider>(context, listen: false).addBooking(
      myUserId, // Ton vrai ID
      widget.artisanId,
      _descriptionController.text,
      widget.hourlyRate,
      _selectedDate!,
    );

    if (!mounted) return;

    // 4. On gère le résultat
    if (success) {
      print("🎉 Réservation réussie dans la BDD !");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Réservation envoyée avec succès ! ✅'),
            backgroundColor: Colors.green),
      );

      // On retourne à la page principale pour voir le suivi
      Navigator.pop(context);
    } else {
      print("⚠️ Le backend a refusé la réservation !");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur serveur lors de la réservation ❌'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 4. RÉCUPÉRATION DU VRAI USER ID VIA L'AUTHPROVIDER
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final int currentUserId = authProvider.user!.id;

    const Color primaryDarkBlue = Color(0xFF0C2C55);
    const Color primaryTeal = Color(0xFF296374);
    const Color bgColor = Color(0xFFF1F3E1);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Réserver'),
        backgroundColor: primaryDarkBlue,
        foregroundColor: Colors.white,
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
                      backgroundColor: primaryTeal.withOpacity(0.2),
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
