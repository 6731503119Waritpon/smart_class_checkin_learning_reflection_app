import 'package:flutter/material.dart';
import '../models/checkin_record.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'qr_scanner_screen.dart';

class CheckInScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const CheckInScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _previousTopicCtrl = TextEditingController();
  final _expectedTopicCtrl = TextEditingController();

  final _firestore = FirestoreService();
  final _location = LocationService();

  int _mood = 3;
  String? _qrData;
  double? _lat, _lng;
  bool _submitting = false;
  bool _locLoading = false;
  String? _locError;

  final _moods = const [
    {'s': 1, 'e': '😡', 'l': 'Very Bad'},
    {'s': 2, 'e': '🙁', 'l': 'Bad'},
    {'s': 3, 'e': '😐', 'l': 'Okay'},
    {'s': 4, 'e': '🙂', 'l': 'Good'},
    {'s': 5, 'e': '😄', 'l': 'Great'},
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _previousTopicCtrl.dispose();
    _expectedTopicCtrl.dispose();
    super.dispose();
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
    if (result != null && mounted) {
      setState(() => _qrData = result);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_qrData == null) return _snack('Please scan the QR code first', err: true);
    if (_lat == null) return _snack('GPS not available', err: true);

    setState(() => _submitting = true);
    try {
      await _firestore.createCheckIn(CheckInRecord(
        studentId: widget.studentId,
        studentName: widget.studentName,
        checkInTime: DateTime.now(),
        checkInLatitude: _lat!,
        checkInLongitude: _lng!,
        qrCodeData: _qrData!,
        previousTopic: _previousTopicCtrl.text.trim(),
        expectedTopic: _expectedTopicCtrl.text.trim(),
        moodBefore: _mood,
      ));
      if (mounted) {
        _snack('Check-in successful! ✓');
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
      appBar: _buildAppBar('Class Check-in'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              // Form card
              _Card(
                title: 'Pre-Class Reflection',
                children: [
                  TextFormField(
                    controller: _previousTopicCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Previous class topic',
                      hintText: 'What was covered last time?',
                      prefixIcon: Icon(Icons.menu_book_rounded,
                          color: Color(0xFF8B7BF7), size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _expectedTopicCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Required'
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Expected topic today',
                      hintText: 'What do you expect to learn?',
                      prefixIcon: Icon(Icons.lightbulb_outline_rounded,
                          color: Color(0xFF8B7BF7), size: 20),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Mood
                  const Text(
                    'How are you feeling?',
                    style: TextStyle(
                      color: Color(0xFFCCCCD0),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _moods.map((m) {
                      final s = m['s'] as int;
                      final selected = _mood == s;
                      return GestureDetector(
                        onTap: () => setState(() => _mood = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 56,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF8B7BF7).withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(
                                    color: const Color(0xFF8B7BF7)
                                        .withValues(alpha: 0.5))
                                : Border.all(color: Colors.transparent),
                          ),
                          child: Column(
                            children: [
                              Text(m['e'] as String,
                                  style: TextStyle(
                                      fontSize: selected ? 28 : 22)),
                              const SizedBox(height: 4),
                              Text(
                                m['l'] as String,
                                style: TextStyle(
                                  color: selected
                                      ? const Color(0xFF8B7BF7)
                                      : const Color(0xFF8E8E93),
                                  fontSize: 10,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Submit Check-in'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────── Shared widgets ────────────────────────

PreferredSizeWidget _buildAppBar(String title) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        letterSpacing: -0.3,
      ),
    ),
    centerTitle: true,
    backgroundColor: const Color(0xFF101014),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  );
}

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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accent,
              ),
            )
          else
            Icon(icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFCCCCD0), fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRetry != null)
            _miniBtn(Icons.refresh_rounded, accent, onRetry!),
          if (onAction != null)
            _miniTextBtn(actionLabel ?? 'Go', accent, onAction!),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData ic, Color c, VoidCallback fn) {
    return InkWell(
      onTap: fn,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(ic, color: c, size: 18),
      ),
    );
  }

  Widget _miniTextBtn(String text, Color c, VoidCallback fn) {
    return GestureDetector(
      onTap: fn,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: c,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFFCCCCD0),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
