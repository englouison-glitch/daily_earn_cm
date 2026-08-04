import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_constants.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final _amountCtrl = TextEditingController();
  String _selectedMethod = "MTN Mobile Money";
  final _phoneCtrl = TextEditingController();
  bool _withdrawing = false;

  Future<void> _requestWithdrawal(double balance) async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final phone = _phoneCtrl.text.trim();

    if (amount < AppConstants.minWithdrawalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Montant minimum : ${AppConstants.minWithdrawalAmount} FCFA")),
      );
      return;
    }
    if (amount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Solde insuffisant !")),
      );
      return;
    }
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Numéro invalide (9 chiffres minimum)")),
      );
      return;
    }

    setState(() => _withdrawing = true);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final userDoc = await tx.get(userRef);
        final currentBalance = userDoc.data()?['balance'] ?? 0;

        tx.update(userRef, {'balance': currentBalance - amount});

        await FirebaseFirestore.instance.collection('withdrawals').add({
          'userId': uid,
          'amount': amount,
          'method': _selectedMethod,
          'phoneNumber': phone,
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Demande envoyée ! En attente de validation")),
        );
        _amountCtrl.clear();
        _phoneCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Erreur : $e")),
        );
      }
    }

    setState(() => _withdrawing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("💰 Mon Portefeuille")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
          final balance = (userSnap.data!['balance'] as num?)?.toDouble() ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  color: const Color(0xFF10B981),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      const Text("Solde disponible", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text("${balance.toStringAsFixed(0)} FCFA", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Demander un retrait", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Montant à retirer",
                    hintText: "Ex: 500, 1000, 2000",
                    prefixIcon: Icon(Icons.money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedMethod,
                  decoration: const InputDecoration(labelText: "Méthode de paiement", border: OutlineInputBorder()),
                  items: AppConstants.withdrawalMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => _selectedMethod = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Numéro Mobile Money",
                    hintText: "6XX XXX XXX",
                    prefixIcon: Icon(Icons.phone_android),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    onPressed: _withdrawing ? null : () => _requestWithdrawal(balance),
                    child: Text(_withdrawing ? "Envoi en cours..." : "✅ Demander le retrait", style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text("Historique des retraits", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('withdrawals')
                      .where('userId', isEqualTo: uid)
                      .orderBy('requestedAt', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, wdSnap) {
                    if (!wdSnap.hasData) return const SizedBox.shrink();
                    if (wdSnap.data!.docs.isEmpty) return const Text("Aucune demande de retrait");

                    return Column(
                      children: wdSnap.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? 'pending';
                        Color statusColor = status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;

                        return Card(
                          child: ListTile(
                            title: Text("${(data['amount'] as num).toDouble().toStringAsFixed(0)} FCFA"),
                            subtitle: Text("${data['method']} • ${data['phoneNumber']}"),
                            trailing: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

