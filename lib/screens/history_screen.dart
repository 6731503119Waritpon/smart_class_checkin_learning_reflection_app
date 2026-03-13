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
  final FirestoreService _firestoreService = FirestoreService();
  List<CheckInRecord> _records = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _records =
          await _firestoreService.getCheckInHistory(widget.studentId);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Check-in History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: _fetchHistory,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  style:
                                      const TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : _records.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      color: Colors.white
                                          .withValues(alpha: 0.3),
                                      size: 64,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No check-in records yet',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.5),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _fetchHistory,
                                color: const Color(0xFF6C63FF),
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount: _records.length,
                                  itemBuilder: (context, index) {
                                    return _buildRecordCard(
                                      _records[index],
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(CheckInRecord record) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: record.isCompleted
              ? const Color(0xFF4ECDC4).withValues(alpha: 0.3)
              : const Color(0xFFFF6B6B).withValues(alpha: 0.3),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: record.isCompleted
                  ? const Color(0xFF4ECDC4).withValues(alpha: 0.2)
                  : const Color(0xFFFF6B6B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              record.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.pending_rounded,
              color: record.isCompleted
                  ? const Color(0xFF4ECDC4)
                  : const Color(0xFFFF6B6B),
            ),
          ),
          title: Text(
            dateFormat.format(record.checkInTime),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            record.isCompleted ? '✅ Completed' : '🔴 In Progress',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          iconColor: Colors.white54,
          collapsedIconColor: Colors.white38,
          children: [
            const Divider(
              color: Colors.white12,
              height: 1,
            ),
            const SizedBox(height: 12),

            // Check-in Details
            _buildSection('Check-in Details', [
              _buildDetailRow(
                '🕐 Time',
                dateFormat.format(record.checkInTime),
              ),
              _buildDetailRow(
                '📍 Location',
                '${record.checkInLatitude.toStringAsFixed(6)}, '
                    '${record.checkInLongitude.toStringAsFixed(6)}',
              ),
              _buildDetailRow('📱 QR Code', record.qrCodeData),
              _buildDetailRow('${record.moodEmoji} Mood', '${record.moodBefore}/5'),
              _buildDetailRow(
                '📖 Previous',
                record.previousTopic,
              ),
              _buildDetailRow(
                '🎯 Expected',
                record.expectedTopic,
              ),
            ]),

            // Check-out Details
            if (record.isCompleted) ...[
              const SizedBox(height: 12),
              _buildSection('Check-out Details', [
                _buildDetailRow(
                  '🕐 Time',
                  record.checkOutTime != null
                      ? dateFormat.format(record.checkOutTime!)
                      : 'N/A',
                ),
                _buildDetailRow(
                  '📍 Location',
                  '${record.checkOutLatitude?.toStringAsFixed(6)}, '
                      '${record.checkOutLongitude?.toStringAsFixed(6)}',
                ),
                _buildDetailRow(
                  '📱 QR Code',
                  record.qrCodeDataOut ?? 'N/A',
                ),
                _buildDetailRow(
                  '📝 Learned',
                  record.whatLearned ?? 'N/A',
                ),
                _buildDetailRow(
                  '💬 Feedback',
                  record.feedback ?? 'N/A',
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF6C63FF),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
