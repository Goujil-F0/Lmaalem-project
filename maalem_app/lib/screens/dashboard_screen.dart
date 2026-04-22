import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  final String artisanId;
  const DashboardScreen({super.key, required this.artisanId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _service = DashboardService();
  DashboardStats? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final stats = await _service.getArtisanStats(widget.artisanId);
      if (mounted) setState(() { _stats = stats; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : _error != null ? _buildError() : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadStats, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final stats = _stats!;
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGreeting(),
          const SizedBox(height: 16),
          const Text('Vue d\'ensemble', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _KpiCard(label: 'Total réservations', value: '${stats.totalBookings}', icon: Icons.calendar_today, color: const Color(0xFF1A237E)),
              _KpiCard(label: 'Complétées', value: '${stats.completedBookings}', icon: Icons.check_circle_outline, color: Colors.green),
              _KpiCard(label: 'En attente', value: '${stats.pendingBookings}', icon: Icons.hourglass_empty, color: Colors.orange),
              _KpiCard(label: 'Revenu total', value: '${stats.totalRevenue.toStringAsFixed(0)} DH', icon: Icons.payments_outlined, color: const Color(0xFF00796B)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Réputation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildReputationCard(stats),
          const SizedBox(height: 20),
          const Text('Revenus mensuels (DH)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildBarChart(stats.monthlyRevenue, color: const Color(0xFF00796B)),
          const SizedBox(height: 20),
          const Text('Réservations mensuelles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _buildBarChart(stats.monthlyBookings, color: const Color(0xFF1A237E)),
          const SizedBox(height: 20),
          _buildComplaintsCard(stats),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final name = FirebaseAuth.instance.currentUser?.displayName ?? 'Artisan';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.waving_hand, color: Colors.amber, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting, $name !', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Voici vos statistiques du moment.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReputationCard(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(stats.averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFFFFB300))),
              Row(
                children: List.generate(5, (i) => Icon(i < stats.averageRating.round() ? Icons.star : Icons.star_border, color: const Color(0xFFFFB300), size: 16)),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [const Icon(Icons.rate_review, color: Colors.blue, size: 18), const SizedBox(width: 6), Text('${stats.totalReviews} avis reçus', style: const TextStyle(fontSize: 13))]),
                const SizedBox(height: 6),
                Row(children: [Icon(Icons.warning_amber_outlined, color: stats.totalComplaints > 0 ? Colors.orange : Colors.green, size: 18), const SizedBox(width: 6), Text('${stats.totalComplaints} réclamation(s)', style: const TextStyle(fontSize: 13))]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<MonthlyData> data, {required Color color}) {
    if (data.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text('Pas de données', style: TextStyle(color: Colors.grey))),
      );
    }
    final maxVal = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final ratio = maxVal == 0 ? 0.0 : d.value / maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (d.value > 0)
                          Text(
                            d.value >= 1000 ? '${(d.value / 1000).toStringAsFixed(1)}k' : d.value.toInt().toString(),
                            style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
                          ),
                        const SizedBox(height: 2),
                        Container(
                          height: 90 * ratio,
                          decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: data.map((d) => Expanded(child: Text(d.month, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey)))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsCard(DashboardStats stats) {
    if (stats.totalComplaints == 0) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text('Vous avez ${stats.totalComplaints} réclamation(s). Contactez le support si nécessaire.', style: TextStyle(color: Colors.orange.shade800, fontSize: 13))),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}