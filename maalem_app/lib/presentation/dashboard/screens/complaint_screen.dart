import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/data/services/complaint_service.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ComplaintScreen extends StatefulWidget {
  final int bookingId;
  final int artisanId;
  final bool isAdmin;

  const ComplaintScreen({
    super.key,
    required this.bookingId,
    required this.artisanId,
    this.isAdmin = false,
  });

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _complaints = [];
  String _selectedFilter = 'open';
  String _selectedSort = 'recent';

  @override
  void initState() {
    super.initState();
    if (widget.isAdmin) _loadComplaints();
  }

  ComplaintService _service() {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      throw Exception('Utilisateur non connecté');
    }
    return ComplaintService(token: token);
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final complaints = await _service().getComplaints();
      if (mounted) {
        setState(() {
          _complaints = complaints;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showComplaintConfirmationDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 2.5,
                    ),
                  ),
                  child: Icon(
                    Icons.gavel_rounded,
                    color: Colors.orange.shade800,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Réclamation envoyée',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Votre dossier a bien été enregistré. Notre équipe support va étudier les détails de votre réservation pour résoudre le différend sous 24 heures.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textGrey,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: const Text('Compris'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitComplaint() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez écrire une description'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service().createComplaint(
        bookingId: widget.bookingId,
        artisanId: widget.artisanId,
        description: description,
      );

      final message = "Bonjour, je souhaite déposer une réclamation.\n\n"
          "Détails :\n"
          "${widget.bookingId > 0 ? '- Réservation ID: #${widget.bookingId}\n' : ''}"
          "${widget.artisanId > 0 ? '- Artisan ID: #${widget.artisanId}\n' : ''}"
          "- Description : $description";

      final uri = Uri.https('wa.me', '/212658416668', {
        'text': message,
      });

      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Failed to launch WhatsApp: $e');
      }

      if (mounted) {
        _descriptionController.clear();
        await _showComplaintConfirmationDialog();
        if (mounted && !widget.isAdmin) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveComplaint(int complaintId) async {
    setState(() => _isLoading = true);
    try {
      await _service().resolveComplaint(complaintId);
      await _loadComplaints();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Réclamations' : 'Déposer une réclamation'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.beige,
        foregroundColor: AppColors.navy,
        titleTextStyle: const TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      body: widget.isAdmin ? _buildAdminView() : _buildClientView(),
    );
  }

  Widget _buildClientView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: AppColors.navy.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade100, width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.orange.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Notre équipe s\'engage à examiner votre réclamation sous 24h. Veuillez décrire le problème de manière précise.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Décrivez votre problème',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 1000,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Expliquez en détail le différend ou le problème rencontré avec l\'artisan...',
                hintStyle: TextStyle(
                  color: AppColors.textGrey.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.beige.withValues(alpha: 0.25),
                counterStyle: const TextStyle(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w700,
                ),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.teal.withValues(alpha: 0.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.teal.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.teal, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitComplaint,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: const Text('Envoyer la réclamation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }

    final filteredComplaints = _filteredComplaints();

    return RefreshIndicator(
      color: AppColors.teal,
      onRefresh: _loadComplaints,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount:
            filteredComplaints.isEmpty ? 4 : filteredComplaints.length + 3,
        itemBuilder: (context, index) {
          if (index == 0) return _buildAdminSummary();
          if (index == 1) return _buildAdminToolbar();
          if (index == 2) return _buildFilters();
          if (filteredComplaints.isEmpty) {
            return _buildAdminEmptyState();
          }

          return _ComplaintCard(
            complaint: filteredComplaints[index - 3],
            onResolve: _resolveComplaint,
          );
        },
      ),
    );
  }

  Widget _buildAdminSummary() {
    final openCount =
        _complaints.where((item) => _isOpenStatus(item['status'])).length;
    final resolvedCount = _complaints.length - openCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Support Réclamations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$openCount en attente • $resolvedCount résolues',
                  style: const TextStyle(
                    color: AppColors.beige,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'open', 
            label: Text('Ouvertes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            icon: Icon(Icons.hourglass_empty_rounded, size: 16),
          ),
          ButtonSegment(
            value: 'resolved', 
            label: Text('Résolues', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            icon: Icon(Icons.check_circle_outline_rounded, size: 16),
          ),
          ButtonSegment(
            value: 'all', 
            label: Text('Toutes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            icon: Icon(Icons.list_alt_rounded, size: 16),
          ),
        ],
        selected: {_selectedFilter},
        onSelectionChanged: (selection) {
          setState(() => _selectedFilter = selection.first);
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.teal.withValues(alpha: 0.16),
          selectedForegroundColor: AppColors.teal,
          foregroundColor: AppColors.navy,
          backgroundColor: AppColors.white,
          side: BorderSide(color: AppColors.teal.withValues(alpha: 0.16)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminEmptyState() {
    final hasComplaints = _complaints.isNotEmpty;
    final hasSearch = _searchController.text.trim().isNotEmpty;
    final title = hasComplaints
        ? 'Aucun résultat trouvé'
        : 'Aucune réclamation pour le moment';
    final message = hasSearch
        ? 'Essayez un autre nom, statut, description ou numéro de booking.'
        : 'Changez le filtre ou revenez après les premières réservations.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, color: AppColors.teal, size: 44),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (hasSearch) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Effacer la recherche'),
              style: TextButton.styleFrom(foregroundColor: AppColors.teal, textStyle: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminToolbar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.04), width: 1),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Rechercher client, artisan, booking...',
              hintStyle: TextStyle(
                color: AppColors.textGrey.withValues(alpha: 0.5),
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.teal, size: 22),
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded, color: AppColors.textGrey),
                    ),
              filled: true,
              fillColor: AppColors.beige.withValues(alpha: 0.25),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_filteredComplaints().length} résultat(s)',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Trier',
                initialValue: _selectedSort,
                onSelected: (value) => setState(() => _selectedSort = value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'recent',
                    child: Text('Plus récentes'),
                  ),
                  PopupMenuItem(
                    value: 'open_first',
                    child: Text('À traiter d’abord'),
                  ),
                  PopupMenuItem(
                    value: 'highest_amount',
                    child: Text('Montant élevé'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sort_rounded,
                        color: AppColors.teal,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _sortLabel(_selectedSort),
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<dynamic> _filteredComplaints() {
    final filtered = _complaints.where((item) {
      if (_selectedFilter == 'resolved' && _isOpenStatus(item['status'])) {
        return false;
      }
      if (_selectedFilter == 'open' && !_isOpenStatus(item['status'])) {
        return false;
      }

      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;

      return _searchableText(item).contains(query);
    }).toList();

    filtered.sort((a, b) {
      if (_selectedSort == 'open_first') {
        final openCompare =
            _openRank(a['status']).compareTo(_openRank(b['status']));
        if (openCompare != 0) return openCompare;
      }
      if (_selectedSort == 'highest_amount') {
        final amountCompare =
            _toDouble(b['agreed_price']).compareTo(_toDouble(a['agreed_price']));
        if (amountCompare != 0) return amountCompare;
      }

      return _toDateTime(b['created_at']).compareTo(_toDateTime(a['created_at']));
    });

    return filtered;
  }

  String _searchableText(dynamic item) {
    return [
      item['client_name'],
      item['artisan_name'],
      item['description'],
      item['booking_id'],
      item['booking_status'],
      item['status'],
    ].whereType<Object>().join(' ').toLowerCase();
  }

  String _sortLabel(String sort) {
    if (sort == 'open_first') return 'À traiter';
    if (sort == 'highest_amount') return 'Montant';
    return 'Récentes';
  }

  int _openRank(dynamic status) => _isOpenStatus(status) ? 0 : 1;

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse('$value') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _isOpenStatus(dynamic status) {
    return status == 'open' || status == 'in_progress';
  }
}

class _ComplaintCard extends StatelessWidget {
  final dynamic complaint;
  final ValueChanged<int> onResolve;

  const _ComplaintCard({
    required this.complaint,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final item = complaint is Map ? complaint : const {};
    final isOpen = _isOpenStatus(item['status']);
    final description = '${item['description'] ?? ''}'.trim();
    final complaintId = _toInt(item['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.navy.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['client_name'] ?? 'Client'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Artisan: ${item['artisan_name'] ?? 'Non renseigné'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ComplaintStatusBadge(isOpen: isOpen),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Booking #${item['booking_id'] ?? '-'}',
                ),
                if (item['agreed_price'] != null)
                  _InfoPill(
                    icon: Icons.payments_outlined,
                    label: '${item['agreed_price']} MAD',
                  ),
                if (item['booking_status'] != null)
                  _InfoPill(
                    icon: Icons.timeline_outlined,
                    label: '${item['booking_status']}',
                  ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.beige.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.08)),
                ),
                child: Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            if (isOpen) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: complaintId == null
                      ? null
                      : () => onResolve(complaintId),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Marquer résolu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isOpenStatus(dynamic status) {
    return status == 'open' || status == 'in_progress';
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}

class _ComplaintStatusBadge extends StatelessWidget {
  final bool isOpen;

  const _ComplaintStatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOpen ? 'À traiter' : 'Résolue',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.teal),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
