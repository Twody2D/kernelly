import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/gradient_banner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await fetchUser(1);
    setState(() {
      user = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9F9),
        elevation: 0,
        title: Text('Профиль', style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 18, color: const Color(0xFF1B2430))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GradientBanner(
            eyebrow: '\$ whoami',
            title: user!['username'],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statCard('ВСЕГО XP', '${user!['xp']}')),
              const SizedBox(width: 12),
              Expanded(child: _statCard('STREAK', '🔥 ${user!['streak']}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1EAEA), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF5C6B73))),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 22, color: const Color(0xFF1B2430))),
        ],
      ),
    );
  }
}