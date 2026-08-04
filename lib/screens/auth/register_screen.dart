import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../dashboard/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  String generateReferralCode(String uid) {
    final hash = sha1.convert(utf8.encode(uid)).toString().toUpperCase().substring(0, 6);
    return "EL$hash";
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final authResult = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      final uid = authResult.user!.uid;
      final referralCode = generateReferralCode(uid);
      String? referredByCode = _referralCtrl.text.trim().isNotEmpty ? _referralCtrl.text.trim() : null;

      String? referredByUid;
      if (referredByCode != null) {
        final referrer = await FirebaseFirestore.instance
            .collection('users')
            .where('referralCode', isEqualTo: referredByCode)
            .limit(1)
            .get();
        if (referrer.docs.isNotEmpty) {
          referredByUid = referrer.docs.first.id;
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'fullName': _nameCtrl.text.trim(),
        'referralCode': referralCode,
        'referredBy': referredByUid,
        'balance': 0,
        'referralsCount': 0,
        'level': "Bronze",
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastCheckin': null,
      });

      if (referredByUid != null) {
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final refDoc = await tx.get(FirebaseFirestore.instance.collection('users').doc(referredByUid!));
          if (refDoc.exists) {
            final newBalance = (refDoc.data()?['balance'] ?? 0) + 50;
            tx.update(FirebaseFirestore.instance.collection('users').doc(referredByUid!), {
              'referralsCount': FieldValue.increment(1),
              'balance': newBalance,
            });
          }
        });
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? "Erreur lors de l'inscription";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inscription")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.person_add, size: 60, color: Color(0xFF2563EB)),
                const SizedBox(height: 16),
                const Text("Créer un compte", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: "Nom complet", prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                  validator: (v) => v!.length >= 3 ? null : "Au moins 3 caractères",
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                  validator: (v) => v!.contains('@') ? null : "Email invalide",
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Téléphone (MTN/Orange)", prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                  validator: (v) => v!.length >= 9 ? null : "Numéro à 9 chiffres",
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Mot de passe", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
                  validator: (v) => v!.length >= 6 ? null : "Au moins 6 caractères",
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _referralCtrl,
                  decoration: const InputDecoration(labelText: "Code parrainage (EL______) - Optionnel", prefixIcon: Icon(Icons.share), border: OutlineInputBorder()),
                ),
                if (_error != null) Padding(padding: const EdgeInsets.only(top:12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: Text(_loading ? "Inscription en cours..." : "S'inscrire", style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

