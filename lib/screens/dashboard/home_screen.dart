import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_constants.dart';
import 'tasks_screen.dart';
import 'wallet_screen.dart';
import 'referral_screen.dart';
import 'wheel_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  int _selectedIndex = 0;

  Future<void> _dailyCheckin() async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;

    final lastCheckin = userDoc.data()?['lastCheckin'];
    final now = DateTime.now();
    bool canCheckin = true;

    if (lastCheckin != null) {
      final lastDate = (lastCheckin as Timestamp).toDate();
      canCheckin = now.day != lastDate.day || now.month != lastDate.month || now.year != lastDate.year;
    }

    if (!canCheckin && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Tu as déjà récupéré ton bonus aujourd'hui ! Reviens demain.")),
      );
      return;
    }

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snapshot = await tx.get(userRef);
      final currentBalance = snapshot.data()?['balance'] ?? 0;
      tx.update(userRef, {
        'balance': currentBalance + AppConstants.dailyCheckinBonus,
        'lastCheckin': FieldValue.serverTimestamp(),
      });
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🎉 +${AppConstants.dailyCheckinBonus} FCFA ajouté !")),
      );
    }
  }

  Widget _buildLevelBadge(String level) {
    Color color;
    IconData icon;
    switch (level) {
      case 'Silver': color = Colors.grey; icon = Icons.silver; break;
      case 'Gold': color = Colors.amber; icon = Icons.workspace_premium; break;
      case 'Platinum': color = Colors.lightBlue; icon = Icons.diamond; break;
      case 'Diamond': color = Colors.purple; icon = Icons.star; break;
      default: color = Colors.brown; icon = Icons.circle;
    }
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(level, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DailyEarn CM"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (!snap.data!.exists) return const Center(child: Text("Profil introuvable"));

          final user = snap.data!.data() as Map<String, dynamic>;
          final fullName = user['fullName'] ?? 'Utilisateur';
          final balance = (user['balance'] as num?)?.toDouble() ?? 0;
          final level = user['level'] ?? 'Bronze';
          final referralsCount = user['referralsCount'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(child: Text(fullName[0].toUpperCase(), style: const TextStyle(fontSize: 24))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          _buildLevelBadge(level),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  color: const Color(0xFF2563EB),
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Solde actuel", style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text("${balance.toStringAsFixed(0)} FCFA", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _dailyCheckin,
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    label: const Text("🎁 Récupérer mon bonus journalier", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Accès Rapide", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _menuCard(Icons.list_alt, "Mes Tâches", Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen()))),
                    _menuCard(Icons.wallet, "Portefeuille", Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
                    _menuCard(Icons.share, "Parrainer ($referralsCount)", Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()))),
                    _menuCard(Icons.casino, "Roue Chance", Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WheelScreen()))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _menuCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
