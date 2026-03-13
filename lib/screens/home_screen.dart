import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'checkin_screen.dart';
import 'finish_class_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final _firestoreService = FirestoreService();
  bool _isCheckingIn = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Logo & Title
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B7BF7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text('📚', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Smart Class\nCheck-in',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Learning Reflection App',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 36),

                // Student Info Card
                _SectionCard(
                  title: 'Student Information',
                  children: [
                    _InputField(
                      controller: _studentIdController,
                      label: 'Student ID',
                      hint: 'e.g. 6xxxxxxxxx',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 14),
                    _InputField(
                      controller: _studentNameController,
                      label: 'Full Name',
                      hint: 'e.g. John Doe',
                      icon: Icons.person_outline_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Actions
                _ActionTile(
                  icon: Icons.login_rounded,
                  title: 'Check-in to Class',
                  subtitle: 'Start your class session',
                  color: const Color(0xFF8B7BF7),
                  isLoading: _isCheckingIn,
                  onTap: () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isCheckingIn = true);
                    try {
                      final studentId = _studentIdController.text.trim();
                      final activeRecord = await _firestoreService.getActiveCheckIn(studentId);
                      
                      if (!context.mounted) return;
                      
                      if (activeRecord != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("You already have an active class session. Please finish it first."),
                            backgroundColor: Color(0xFFEF6B6B),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckInScreen(
                              studentId: studentId,
                              studentName: _studentNameController.text.trim(),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF6B6B)),
                      );
                    } finally {
                      if (mounted) setState(() => _isCheckingIn = false);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.logout_rounded,
                  title: 'Finish Class',
                  subtitle: 'Complete your session',
                  color: const Color(0xFFEF6B6B),
                  onTap: () => _navigateTo(
                    FinishClassScreen(
                      studentId: _studentIdController.text.trim(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.history_rounded,
                  title: 'View History',
                  subtitle: 'See your past records',
                  color: const Color(0xFF5EDCB4),
                  onTap: () => _navigateTo(
                    HistoryScreen(
                      studentId: _studentIdController.text.trim(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────── Reusable Widgets ────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF8B7BF7), size: 20),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A32)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        ),
                      )
                    : Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF48484A),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
