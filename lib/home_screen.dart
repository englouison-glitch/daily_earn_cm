import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'localization/app_localization.dart';
import 'tasks_screen.dart';
import 'wallet_screen.dart';
import 'referral_screen.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeContent(),
    TasksScreen(),
    WalletScreen(),
    ReferralScreen(),
    LeaderboardScreen(),
    SettingsScreen(),
  ];

  void _onTap(int index) => setState(()=>_selectedIndex=index);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalization.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate("welcome")), backgroundColor: const Color(0xFF0F3460)),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        selectedItemColor: const Color(0xFF0F3460),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: 'Gagner'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Portefeuille'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Parrainage'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Classement'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalization.of(context)!;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
      builder: (ctx, snap){
        if(!snap.hasData) return const Center(child: CircularProgressIndicator());
        var data = snap.data!.data() as Map;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE8F4FD), Color(0xFFBFD7EA)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Bonjour ${data['fullName']} !", style: const TextStyle(fontSize:22, fontWeight:FontWeight.bold, color:Color(0xFF0F3460))),
              const SizedBox(height:30),
              Container(
                padding: const EdgeInsets.symmetric(vertical:25, horizontal:35),
                decoration: BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(20), boxShadow:const [BoxShadow(color:Colors.black12, blurRadius:15)]),
                child: Column(children:[
                  Text(loc.translate("balance"), style:const TextStyle(fontSize:17, color:Colors.black54)),
                  const SizedBox(height:8),
                  Text("${data['balance'] ?? 0} FCFA", style:const TextStyle(fontSize:40, fontWeight:FontWeight.bold, color:Colors.green.shade700)),
                ]),
              ),
              const SizedBox(height:25),
              Container(padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:Colors.white.withOpacity(0.7), borderRadius:BorderRadius.circular(12)), child: Text(loc.translate("earning_disclaimer"), textAlign:TextAlign.center, style:const TextStyle(color:Color(0xFF0F3460), fontSize:14))),
            ],
          ),
        );
      },
    );
  }
}

