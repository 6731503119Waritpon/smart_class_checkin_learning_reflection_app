import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/checkin_record.dart';
import '../services/firestore_service.dart';

class HistoryScreen extends StatefulWidget {
  final String studentId;
  const HistoryScreen({super.key, required this.studentId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _firestore = FirestoreService();
  List<CheckInRecord> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _records = await _firestore.getCheckInHistory(widget.studentId);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Check-in History',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.3),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101014),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF8E8E93)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B7BF7)))
          : _error != null
              ? _buildMessage(Icons.error_outline_rounded, _error!, const Color(0xFFEF6B6B))
              : _records.isEmpty
                  ? _buildMessage(
                      Icons.history_rounded, 'No records yet', const Color(0xFF8E8E93))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: const Color(0xFF8B7BF7),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        itemCount: _records.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _buildCard(_records[i]),
                      ),
                    ),
    );
  }

  Widget _buildMessage(IconData icon, String text, Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 14),
          Text(text,
              style: TextStyle(color: color, fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCard(CheckInRecord r) {
    final df = DateFormat('MMM dd, yyyy • HH:mm');
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A32)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const Border(),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: r.isCompleted
                  ? const Color(0xFF5EDCB4).withValues(alpha: 0.12)
                  : const Color(0xFFEF6B6B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              r.isCompleted ? Icons.check_circle_outline_rounded : Icons.pending_rounded,
              color: r.isCompleted ? const Color(0xFF5EDCB4) : const Color(0xFFEF6B6B),
              size: 20,
            ),
          ),
          title: Text(
            df.format(r.checkInTime),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            r.isCompleted ? 'Completed' : 'In Progress',
            style: TextStyle(
              color: r.isCompleted ? const Color(0xFF5EDCB4) : const Color(0xFFEF6B6B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          iconColor: const Color(0xFF48484A),
          collapsedIconColor: const Color(0xFF48484A),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF101014),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Check-in'),
                  _row('Time', df.format(r.checkInTime)),
                  _row('Location',
                      '${r.checkInLatitude.toStringAsFixed(4)}, ${r.checkInLongitude.toStringAsFixed(4)}'),
                  _row('QR Code', r.qrCodeData),
                  _row('Mood', '${r.moodEmoji}  ${r.moodBefore}/5'),
                  _row('Previous', r.previousTopic),
                  _row('Expected', r.expectedTopic),
                  if (r.isCompleted) ...[
                    const SizedBox(height: 12),
                    _sectionLabel('Check-out'),
                    _row('Time',
                        r.checkOutTime != null ? df.format(r.checkOutTime!) : '-'),
                    _row('Location',
                        '${r.checkOutLatitude?.toStringAsFixed(4)}, ${r.checkOutLongitude?.toStringAsFixed(4)}'),
                    _row('QR Code', r.qrCodeDataOut ?? '-'),
                    _row('Learned', r.whatLearned ?? '-'),
                    _row('Feedback', r.feedback ?? '-'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8B7BF7),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Color(0xFFCCCCD0), fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
