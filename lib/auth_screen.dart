import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'localization/app_localization.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final loc = AppLocalization.of(context)!;
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      } else {
        UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        await FirebaseFirestore.instance.collection('users').doc(user.user!.uid).set({
          'fullName': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'balance': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        String code = _referralCtrl.text.trim().toUpperCase();
        if (code.isNotEmpty) {
          final q = await FirebaseFirestore.instance.collection('users').where('referralCode', isEqualTo: code).limit(1).get();
          if (q.docs.isNotEmpty && q.docs.first.id != user.user!.uid) {
            await FirebaseFirestore.instance.collection('users').doc(user.user!.uid).set({
              'referredBy': q.docs.first.id,
            }, SetOptions(merge: true));
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Erreur'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalization.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0F3460),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, size: 70, color: Colors.white),
                const SizedBox(height: 10),
                Text('DailyEarn CM', style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                if (!_isLogin) TextFormField(controller: _nameCtrl, decoration: inputDec('Nom complet'), validator: (_) => _.isEmpty ? 'Indiquez votre nom' : null),
                if (!_isLogin) const SizedBox(height: 12),
                TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: inputDec('Email'), validator: (_) => _.isEmpty || !_.contains('@') ? 'Email invalide' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _passCtrl, obscureText: true, decoration: inputDec('Mot de passe'), validator: (_) => _.length < 6 ? '6 caractères minimum' : null),
                const SizedBox(height: 12),
                if (!_isLogin) TextFormField(controller: _referralCtrl, decoration: inputDec('Code parrainage (facultatif)')),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _submit, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical:14), backgroundColor: Colors.white, foregroundColor: const Color(0xFF0F3460), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _loading ? const CircularProgressIndicator() : Text(_isLogin ? 'Se connecter' : 'Créer un compte', style: const TextStyle(fontSize:16, fontWeight:FontWeight.bold)))),
                TextButton(onPressed: ()=>setState(()=>_isLogin=!_isLogin), child: Text(_isLogin ? 'Pas de compte ? Créer' : 'Déjà inscrit ? Se connecter', style: const TextStyle(color:Colors.white)))
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration inputDec(String label)=>InputDecoration(labelText:label, filled:true, fillColor:Colors.white, border:OutlineInputBorder(borderRadius:BorderRadius.circular(10)));
}
￼Enter
