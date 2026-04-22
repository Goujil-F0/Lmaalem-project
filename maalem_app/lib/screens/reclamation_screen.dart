import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/complaint_model.dart';
import '../services/complaint_service.dart';

class ReclamationScreen extends StatefulWidget {
  final String? targetId;      // artisan visé (optionnel si déjà connu)
  final String? targetName;
  final String? bookingId;

  const ReclamationScreen({
    super.key,
    this.targetId,
    this.targetName,
    this.bookingId,
  });

  @override
  State<ReclamationScreen> createState() => _ReclamationScreenState();
}

class _ReclamationScreenState extends State<ReclamationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ComplaintService _service = ComplaintService();

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  String get _userName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'Anonyme';

  // Formulaire
  final _descController = TextEditingController();
  final _targetNameController = TextEditingController();
  ComplaintType _selectedType = ComplaintType.service;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.targetName != null) {
      _targetNameController.text = widget.targetName!;
    }
  }

  Future<void> _submitComplaint() async {
    if (_descController.text.trim().isEmpty) {
      _showSnack('Veuillez décrire votre réclamation.', isError: true);
      return;
    }
    if (_userId == null) {
      _showSnack('Vous devez être connecté.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.submitComplaint(ComplaintModel(
        id: '',
        reporterId: _userId!,
        reporterName: _userName,
        targetId: widget.targetId ?? 'unknown',
        targetName: _targetNameController.text.trim(),
        type: _selectedType,
        description: _descController.text.trim(),
        createdAt: DateTime.now(),
        bookingId: widget.bookingId,
      ));
      _descController.clear();
      _showSnack('Réclamation soumise. Nous la traiterons dans les plus brefs délais.');
      _tabController.animateTo(1); // passer à l'onglet "Mes réclamations"
    } catch (e) {
      _showSnack('Erreur : ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Réclamations'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Nouvelle réclamation', icon: Icon(Icons.add_circle_outline)),
            Tab(text: 'Mes réclamations', icon: Icon(Icons.list_alt)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForm(),
          _buildMyComplaints(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bannière info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3F51B5).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF3F51B5)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Votre réclamation sera examinée dans un délai de 48h.',
                    style: TextStyle(color: Color(0xFF3F51B5), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Artisan concerné
          if (widget.targetId == null) ...[
            _label('Artisan concerné'),
            TextField(
              controller: _targetNameController,
              decoration: _inputDeco('Nom de l\'artisan'),
            ),
            const SizedBox(height: 16),
          ] else ...[
            _label('Artisan concerné'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF1A237E)),
                  const SizedBox(width: 8),
                  Text(widget.targetName ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Type de réclamation
          _label('Type de réclamation'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: ComplaintType.values.map((type) {
                return RadioListTile<ComplaintType>(
                  value: type,
                  groupValue: _selectedType,
                  onChanged: (v) => setState(() => _selectedType = v!),
                  title: Text(ComplaintModel.typeLabel(type)),
                  activeColor: const Color(0xFF1A237E),
                  dense: true,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          _label('Description'),
          TextField(
            controller: _descController,
            maxLines: 5,
            maxLength: 500,
            decoration: _inputDeco('Décrivez votre problème en détail...'),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitComplaint,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(_isSubmitting ? 'Envoi en cours...' : 'Soumettre la réclamation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyComplaints() {
    if (_userId == null) {
      return const Center(child: Text('Connectez-vous pour voir vos réclamations.'));
    }

    return StreamBuilder<List<ComplaintModel>>(
      stream: _service.getMyComplaints(_userId!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 8),
                Text('Aucune réclamation soumise.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: snap.data!.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ComplaintCard(complaint: snap.data![i]),
        );
      },
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300)),
  );

  @override
  void dispose() {
    _tabController.dispose();
    _descController.dispose();
    _targetNameController.dispose();
    super.dispose();
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;

  const _ComplaintCard({required this.complaint});

  Color get _statusColor {
    switch (complaint.status) {
      case ComplaintStatus.pending: return Colors.orange;
      case ComplaintStatus.inProgress: return Colors.blue;
      case ComplaintStatus.resolved: return Colors.green;
      case ComplaintStatus.rejected: return Colors.red;
    }
  }

  IconData get _statusIcon {
    switch (complaint.status) {
      case ComplaintStatus.pending: return Icons.hourglass_empty;
      case ComplaintStatus.inProgress: return Icons.sync;
      case ComplaintStatus.resolved: return Icons.check_circle;
      case ComplaintStatus.rejected: return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon, color: _statusColor, size: 18),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ComplaintModel.statusLabel(complaint.status),
                  style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(complaint.createdAt),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('Contre : ${complaint.targetName}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(ComplaintModel.typeLabel(complaint.type),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF1A237E))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          if (complaint.adminNote != null && complaint.adminNote!.isNotEmpty) ...[
            const Divider(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.admin_panel_settings,
                    size: 14, color: Color(0xFF1A237E)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Réponse admin : ${complaint.adminNote}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF1A237E)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}