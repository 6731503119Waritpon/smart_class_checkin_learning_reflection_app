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
  final TextEditingController _previousTopicController =
      TextEditingController();
  final TextEditingController _expectedTopicController =
      TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  int _selectedMood = 3;
  String? _qrData;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _locationLoading = false;
  String? _locationError;

  final List<Map<String, dynamic>> _moods = [
    {'score': 1, 'emoji': '😡', 'label': 'Very negative'},
    {'score': 2, 'emoji': '🙁', 'label': 'Negative'},
    {'score': 3, 'emoji': '😐', 'label': 'Neutral'},
    {'score': 4, 'emoji': '🙂', 'label': 'Positive'},
    {'score': 5, 'emoji': '😄', 'label': 'Very positive'},
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _previousTopicController.dispose();
    _expectedTopicController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationLoading = false;
      });
    } catch (e) {
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

  Future<void> _submitCheckIn() async {
    if (!_formKey.currentState!.validate()) return;

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
      final record = CheckInRecord(
        studentId: widget.studentId,
        studentName: widget.studentName,
        checkInTime: DateTime.now(),
        checkInLatitude: _latitude!,
        checkInLongitude: _longitude!,
        qrCodeData: _qrData!,
        previousTopic: _previousTopicController.text.trim(),
        expectedTopic: _expectedTopicController.text.trim(),
        moodBefore: _selectedMood,
      );

      await _firestoreService.createCheckIn(record);

      if (mounted) {
        _showSnackBar('✅ Check-in successful!');
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
                        'Class Check-in',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // GPS Status Card
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
                          onRetry:
                              _locationError != null ? _getLocation : null,
                        ),
                        const SizedBox(height: 16),

                        // QR Code Card
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

                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pre-Class Reflection',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildFormField(
                                controller: _previousTopicController,
                                label: 'Previous Class Topic',
                                hint:
                                    'What topic was covered in the previous class?',
                                icon: Icons.menu_book_rounded,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              _buildFormField(
                                controller: _expectedTopicController,
                                label: 'Expected Topic Today',
                                hint: 'What do you expect to learn today?',
                                icon: Icons.lightbulb_outline_rounded,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 24),

                              // Mood Selector
                              Text(
                                'How are you feeling?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: _moods.map((mood) {
                                  final isSelected =
                                      _selectedMood == mood['score'];
                                  return GestureDetector(
                                    onTap: () => setState(() =>
                                        _selectedMood = mood['score']),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF6C63FF)
                                                .withValues(alpha: 0.3)
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: isSelected
                                            ? Border.all(
                                                color:
                                                    const Color(0xFF6C63FF),
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            mood['emoji'],
                                            style: TextStyle(
                                              fontSize: isSelected ? 32 : 26,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${mood['score']}',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                              fontSize: 12,
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
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitCheckIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor:
                                  const Color(0xFF6C63FF).withValues(alpha: 0.5),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Submit Check-in',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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
          return 'Please enter $label';
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
