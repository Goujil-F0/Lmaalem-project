import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ComplaintScreen extends StatefulWidget {
  final int artisanId;
  final String token;
  final bool isAdmin;

  const ComplaintScreen({
    super.key,
    required this.artisanId,
    required this.token,
    this.isAdmin = false,
  });

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _complaints = [];

  @override
  void initState() {
    super.initState();
    if (widget.isAdmin) _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8081/api/complaints'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _complaints = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComplaint() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez écrire une description')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8081/api/complaints'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'target_id': widget.artisanId,
          'description': _descriptionController.text,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réclamation envoyée avec succès !'),
              backgroundColor: Color(0xFF296374),
            ),
          );
          _descriptionController.clear();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveComplaint(int complaintId) async {
    try {
      await http.put(
        Uri.parse('http://10.0.2.2:8081/api/complaints/$complaintId/resolve'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      _loadComplaints();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDCE),
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Réclamations' : 'Déposer une réclamation'),
        backgroundColor: const Color(0xFF0C2C55),
        foregroundColor: Colors.white,
      ),
      body: widget.isAdmin ? _buildAdminView() : _buildClientView(),
    );
  }

  Widget _buildClientView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Décrivez votre problème',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C2C55),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: 'Expliquez votre réclamation...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF296374)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitComplaint,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF296374),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Envoyer', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF296374)),
      );
    }

    if (_complaints.isEmpty) {
      return const Center(child: Text('Aucune réclamation'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _complaints.length,
      itemBuilder: (context, index) {
        final complaint = _complaints[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      complaint['user_name'] ?? 'Client',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C2C55),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: complaint['status'] == 'pending'
                            ? const Color(0xFF629FAD).withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        complaint['status'] == 'pending'
                            ? 'En attente'
                            : 'Résolu',
                        style: TextStyle(
                          color: complaint['status'] == 'pending'
                              ? const Color(0xFF296374)
                              : Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(complaint['description'] ?? ''),
                if (complaint['status'] == 'pending') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _resolveComplaint(complaint['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF629FAD),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Marquer comme résolu'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}