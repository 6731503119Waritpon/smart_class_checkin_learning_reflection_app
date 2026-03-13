import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../models/checkin_record.dart';
import 'qr_scanner_screen.dart';

class FinishClassScreen extends StatefulWidget {
  final String studentId;
  const FinishClassScreen({super.key, required this.studentId});

  @override
  State<FinishClassScreen> createState() => _FinishClassScreenState();
}

class _FinishClassScreenState extends State<FinishClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _learnedCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();

  final _firestore = FirestoreService();
  final _location = LocationService();

  String? _qrData;
  double? _lat, _lng;
  bool _submitting = false;
  bool _locLoading = false;
  bool _fetching = true;
  String? _locError;
  CheckInRecord? _record;
  String? _fetchErr;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _fetchActive();
    _getLocation();
  }

  @override
  void dispose() {
    _learnedCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchActive() async {
    if (!mounted) return;
    setState(() => _fetching = true);
    try {
      _record = await _firestore.getActiveCheckIn(widget.studentId);
      if (_record == null) _fetchErr = 'No active check-in found.';
    } catch (e) {
      _fetchErr = 'Error: $e';
    }
    if (mounted) setState(() => _fetching = false);
  }

  Future<void> _getLocation() async {
    if (!mounted) return;
    setState(() {
      _locLoading = true;
      _locError = null;
    });
    try {
      final p = await _location.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _lat = p.latitude;
        _lng = p.longitude;
        _locLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locError = e.toString();
        _locLoading = false;
      });
    }
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null && mounted) setState(() => _qrData = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_record == null) return _snack('No active session', err: true);
    if (_qrData == null) return _snack('Scan QR first', err: true);
    if (_lat == null) return _snack('GPS not available', err: true);

    setState(() => _submitting = true);
    try {
      await _firestore.updateCheckOut(
        docId: _record!.id!,
        checkOutTime: DateTime.now(),
        checkOutLatitude: _lat!,
        checkOutLongitude: _lng!,
        qrCodeDataOut: _qrData!,
        whatLearned: _learnedCtrl.text.trim(),
        feedback: _feedbackCtrl.text.trim(),
      );
      if (mounted) {
        _snack('Session completed! ✓');
        Navigator.pop(context);
      }
    } catch (e) {
      _snack('Error: $e', err: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: err ? const Color(0xFFEF6B6B) : const Color(0xFF5EDCB4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Finish Class',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.3),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101014),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _fetching
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B7BF7)))
          : _fetchErr != null
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Active session badge
                        if (_record != null) _buildSessionBadge(),
                        const SizedBox(height: 14),

                        // Status chips
                        _StatusChip(
                          icon: Icons.location_on_rounded,
                          label: _locLoading
                              ? 'Getting location...'
                              : _locError != null
                                  ? 'Location error'
                                  : 'Lat ${_lat?.toStringAsFixed(4)}, Lng ${_lng?.toStringAsFixed(4)}',
                          state: _locLoading
                              ? _ChipState.loading
                              : _locError != null
                                  ? _ChipState.error
                                  : _ChipState.success,
                          onRetry: _locError != null ? _getLocation : null,
                        ),
                        const SizedBox(height: 10),
                        _StatusChip(
                          icon: Icons.qr_code_scanner_rounded,
                          label: _qrData != null ? 'QR: $_qrData' : 'QR not scanned',
                          state: _qrData != null ? _ChipState.success : _ChipState.idle,
                          onAction: _scanQR,
                          actionLabel: _qrData != null ? 'Rescan' : 'Scan',
                        ),
                        const SizedBox(height: 24),

                        // Form
                        _Card(
                          title: 'Post-Class Reflection',
                          children: [
                            TextFormField(
                              controller: _learnedCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              maxLines: 3,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                              decoration: const InputDecoration(
                                labelText: 'What did you learn?',
                                hintText: 'Summarize today\'s lesson',
                                prefixIcon: Icon(Icons.school_rounded,
                                    color: Color(0xFF8B7BF7), size: 20),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _feedbackCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              maxLines: 3,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                              decoration: const InputDecoration(
                                labelText: 'Feedback',
                                hintText: 'About the class or instructor',
                                prefixIcon: Icon(Icons.rate_review_rounded,
                                    color: Color(0xFF8B7BF7), size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF6B6B),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Complete Session'),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSessionBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF8B7BF7).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B7BF7).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded, color: Color(0xFF8B7BF7), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Session',
                  style: TextStyle(
                    color: Color(0xFF8B7BF7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Checked in ${_record!.checkInTime.toString().substring(11, 16)} · Mood ${_record!.moodEmoji}',
                  style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEF6B6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: Color(0xFFEF6B6B), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              _fetchErr ?? 'Error',
              style: const TextStyle(color: Color(0xFFCCCCD0), fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check-in first before finishing class.',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────── Shared widgets ────────────────────────

enum _ChipState { idle, loading, success, error }

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final _ChipState state;
  final VoidCallback? onRetry;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.state,
    this.onRetry,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent;
    switch (state) {
      case _ChipState.success:
        accent = const Color(0xFF5EDCB4);
        break;
      case _ChipState.error:
        accent = const Color(0xFFEF6B6B);
        break;
      default:
        accent = const Color(0xFF8B7BF7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          if (state == _ChipState.loading)
            SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent))
          else
            Icon(icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Color(0xFFCCCCD0), fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          if (onRetry != null)
            InkWell(
              onTap: onRetry,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.refresh_rounded, color: accent, size: 18),
              ),
            ),
          if (onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  actionLabel ?? 'Go',
                  style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFCCCCD0))),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
