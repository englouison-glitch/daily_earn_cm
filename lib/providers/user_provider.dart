import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;
  bool _loading = false;

  Map<String, dynamic>? get userData => _userData;
  bool get loading => _loading;
  double get balance => (_userData?['balance'] as num?)?.toDouble() ?? 0.0;
  String get level => _userData?['level'] ?? 'Bronze';
  String get fullName => _userData?['fullName'] ?? 'Utilisateur';
  String get referralCode => _userData?['referralCode'] ?? '';
  int get referralsCount => _userData?['referralsCount'] ?? 0;

  UserProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
          if (snapshot.exists) {
            _userData = snapshot.data() as Map<String, dynamic>;
            notifyListeners();
          }
        });
  }

  void clearUserData() {
    _userData = null;
    notifyListeners();
  }
}

