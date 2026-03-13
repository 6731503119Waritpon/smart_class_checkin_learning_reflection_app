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
  final TextEditingController _whatLearnedController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  String? _qrData;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _locationLoading = false;
  bool _fetchingRecord = true;
  String? _locationError;
  CheckInRecord? _activeRecord;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _fetchActiveCheckIn();
    _getLocation();
  }

  @override
  void dispose() {
    _whatLearnedController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _fetchActiveCheckIn() async {
    if (!mounted) return;
    setState(() => _fetchingRecord = true);
    try {
      _activeRecord =
          await _firestoreService.getActiveCheckIn(widget.studentId);
      if (_activeRecord == null) {
        _fetchError = 'No active check-in found for this student ID.';
      }
    } catch (e) {
      _fetchError = 'Error fetching record: $e';
    }
    if (mounted) setState(() => _fetchingRecord = false);
  }

  Future<void> _getLocation() async {
    if (!mounted) return;
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });
    try {
      final position = await _locationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e.toString();
        _locationLoading = false;
      });
    }
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null) {
      setState(() => _qrData = result);
    }
  }

  Future<void> _submitFinish() async {
    if (!_formKey.currentState!.validate()) return;

    if (_activeRecord == null) {
      _showSnackBar('No active check-in found', isError: true);
      return;
    }

    if (_qrData == null) {
      _showSnackBar('Please scan the QR code first', isError: true);
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showSnackBar('GPS location not available', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestoreService.updateCheckOut(
        docId: _activeRecord!.id!,
        checkOutTime: DateTime.now(),
        checkOutLatitude: _latitude!,
        checkOutLongitude: _longitude!,
        qrCodeDataOut: _qrData!,
        whatLearned: _whatLearnedController.text.trim(),
        feedback: _feedbackController.text.trim(),
      );

      if (mounted) {
        _showSnackBar('✅ Class session completed!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF4ECDC4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                        'Finish Class',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _fetchingRecord
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                        ),
                      )
                    : _fetchError != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: Colors.orangeAccent,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _fetchError!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Please check-in first before finishing class.',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  // Active Check-in Info
                                  if (_activeRecord != null)
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF6C63FF)
                                                .withValues(alpha: 0.3),
                                            const Color(0xFF4ECDC4)
                                                .withValues(alpha: 0.3),
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '📋 Active Session',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Checked in: ${_activeRecord!.checkInTime.toString().substring(0, 19)}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            'Mood: ${_activeRecord!.moodEmoji}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 16),

                                  // GPS Status
                                  _buildStatusCard(
                                    icon: Icons.location_on_rounded,
                                    title: 'GPS Location',
                                    subtitle: _locationLoading
                                        ? 'Getting location...'
                                        : _locationError != null
                                            ? 'Error: $_locationError'
                                            : '📍 Lat: ${_latitude?.toStringAsFixed(6)}, '
                                                'Lng: ${_longitude?.toStringAsFixed(6)}',
                                    isLoading: _locationLoading,
                                    isError: _locationError != null,
                                    isSuccess: _latitude != null,
                                    onRetry: _locationError != null
                                        ? _getLocation
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // QR Code
                                  _buildStatusCard(
                                    icon: Icons.qr_code_scanner_rounded,
                                    title: 'QR Code',
                                    subtitle: _qrData != null
                                        ? '✅ Scanned: $_qrData'
                                        : 'Not scanned yet',
                                    isSuccess: _qrData != null,
                                    onAction: _scanQR,
                                    actionLabel: _qrData != null
                                        ? 'Scan Again'
                                        : 'Scan QR Code',
                                  ),
                                  const SizedBox(height: 24),

                                  // Form
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Post-Class Reflection',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _buildFormField(
                                          controller:
                                              _whatLearnedController,
                                          label: 'What did you learn?',
                                          hint:
                                              'Summarize what you learned today',
                                          icon:
                                              Icons.school_rounded,
                                          maxLines: 3,
                                        ),
                                        const SizedBox(height: 16),
                                        _buildFormField(
                                          controller:
                                              _feedbackController,
                                          label: 'Feedback',
                                          hint:
                                              'Feedback about the class or instructor',
                                          icon:
                                              Icons.rate_review_rounded,
                                          maxLines: 3,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Submit Button
                                  SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _submitFinish,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFF6B6B),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: 8,
                                        shadowColor:
                                            const Color(0xFFFF6B6B)
                                                .withValues(alpha: 0.5),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child:
                                                  CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              'Complete Session',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isLoading = false,
    bool isError = false,
    bool isSuccess = false,
    VoidCallback? onRetry,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? Colors.redAccent.withValues(alpha: 0.5)
              : isSuccess
                  ? const Color(0xFF4ECDC4).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isError
                  ? Colors.redAccent.withValues(alpha: 0.2)
                  : isSuccess
                      ? const Color(0xFF4ECDC4).withValues(alpha: 0.2)
                      : const Color(0xFF6C63FF).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6C63FF),
                    ),
                  )
                : Icon(
                    icon,
                    color: isError
                        ? Colors.redAccent
                        : isSuccess
                            ? const Color(0xFF4ECDC4)
                            : const Color(0xFF6C63FF),
                    size: 24,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                actionLabel ?? 'Action',
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please fill in this field';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF6C63FF),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
