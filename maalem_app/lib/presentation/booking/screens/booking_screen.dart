// lib/presentation/booking/screens/booking_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
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

  void _submitBooking() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      // 1. On affiche un chargement (facultatif si le provider est rapide)

      // 2. On appelle le Provider
      final success =
          await Provider.of<BookingProvider>(context, listen: false).addBooking(
        1, // clientId (temporaire pour le test)
        widget.artisanId,
        _descriptionController.text,
        widget
            .hourlyRate, // On part du principe qu'on bloque 1h au tarif indiqué
        _selectedDate!,
      );

      // 3. Résultat
      // 3. Résultat
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Réservation envoyée avec succès ! ✅'),
              backgroundColor: Colors.green),
        );

        // --- MODIFICATION ICI ---
        // Au lieu de "pop", on détruit cet écran et on le remplace par l'Historique
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HistoryScreen()),
        );
        // ------------------------
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur lors de la réservation ❌'),
              backgroundColor: Colors.red),
        );
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez choisir une date.'),
            backgroundColor: Colors.orange),
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
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: Provider.of<BookingProvider>(context).isLoading
                      ? null
                      : _submitBooking,
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
