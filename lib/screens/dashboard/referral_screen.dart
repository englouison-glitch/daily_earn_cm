import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_constants.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("👥 Parrainage")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final user = snap.data!.data() as Map<String, dynamic>;
          final referralCode = user['referralCode'] ?? 'EL??????';
          final referralsCount = user['referralsCount'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  color: const Color(0xFF10B981),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text("Ton code de parrainage", style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 12),
                        Text(referralCode, style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 4)),
                        const SizedBox(height: 16),
                        Text("Invite un ami → +${AppConstants.referralBonus} FCFA", style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [
                          const Text("Filleuls", style: TextStyle(fontSize:14, color:Colors.grey)),
                          Text("$referralsCount", style: const TextStyle(fontSize:28, fontWeight:FontWeight.bold, color:Color(0xFF2563EB))),
                        ]),
                        Column(children: [
                          const Text("Gagné", style: TextStyle(fontSize:14, color:Colors.grey)),
                          Text("${referralsCount * AppConstants.referralBonus} FCFA", style: const TextStyle(fontSize:28, fontWeight:FontWeight.bold, color:Colors.green)),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height:20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical:16)),
                    onPressed: ()=>Share.share("Rejoins DailyEarn CM ! Utilise mon code : $referralCode", subject:"Invitation DailyEarn"),
                    icon: const Icon(Icons.share, color:Colors.white),
                    label: const Text("Partager mon code", style: TextStyle(fontSize:16, color:Colors.white)),
                  ),
                ),
                const SizedBox(height:24),
                const Text("📋 Mes filleuls", style: TextStyle(fontSize:18, fontWeight:FontWeight.bold)),
                const SizedBox(height:12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('referredBy', isEqualTo:uid).orderBy('createdAt', descending:true).limit(20).snapshots(),
                  builder: (context, refSnap){
                    if(!refSnap.hasData) return const SizedBox.shrink();
                    if(refSnap.data!.docs.isEmpty) return const Card(child:Padding(padding:EdgeInsets.all(20), child:Text("Aucun filleul pour l'instant ! Partage ton code.", textAlign:TextAlign.center)));
                    return Column(children: refSnap.data!.docs.map((doc){
                      final data=doc.data() as Map<String,dynamic>;
                      return Card(child:ListTile(
                        leading:CircleAvatar(child:Text((data['fullName']??'?')[0].toUpperCase())),
                        title:Text(data['fullName']??''),
                        subtitle:Text(data['email']??''),
                        trailing:Text("+${AppConstants.referralBonus} FCFA", style:const TextStyle(color:Colors.green, fontWeight:FontWeight.bold)),
                      ));
                    }).toList());
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

