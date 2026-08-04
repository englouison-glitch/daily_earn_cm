import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'localization/app_localization.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  String? _myCode;
  int _totalBonus = 0;
  const int _rewardPerFriend = 150;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(_uid);
    final doc = await userRef.get();
    if (!doc.exists) return;
    if (!doc.data()!.containsKey('referralCode')) {
      String code = _uid.substring(0,6).toUpperCase();
      await userRef.set({'referralCode': code, 'referralBonusTotal':0}, SetOptions(merge:true));
      setState((){_myCode=code; _totalBonus=0;});
    } else {
      setState((){
        _myCode = doc.data()!['referralCode'];
        _totalBonus = doc.data()!['referralBonusTotal'] ?? 0;
      });
    }
  }

  void _share() {
    if(_myCode==null) return;
    String msg = "💸 Gagne de l'argent avec DailyEarn CM ! Utilise MON CODE : **$_myCode** à l'inscription 🇨🇲 Regarde des pubs, retrait dès 2000FCFA via Mobile Money 🚀";
    Share.share(msg);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalization.of(context)!;
    return Scaffold(
      appBar: AppBar(title:Text(loc.translate("refer_friend")), backgroundColor:const Color(0xFF0F3460)),
      body:SingleChildScrollView(padding:const EdgeInsets.all(20),
        child:Column(children:[
          const Icon(Icons.card_giftcard, size:60, color:Colors.green), SizedBox(height:10),
          Text("Gagnez $_rewardPerFriend FCFA par ami !", style:TextStyle(fontSize:22, fontWeight:FontWeight.bold, color:Color(0xFF0F3460))),
          SizedBox(height:25),
          Container(width:double.infinity, padding:const EdgeInsets.all(25), decoration:BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(20), boxShadow:[BoxShadow(color:Colors.black12, blurRadius:15)]),
            child:Column(children:[
              Text("Votre code unique :", style:TextStyle(fontSize:16, color:Colors.black54)),SizedBox(height:8),
              Text(_myCode??"Chargement...", style:TextStyle(fontSize:32, fontWeight:FontWeight.bold, letterSpacing:5, color:Color(0xFF1A5F7A))),
              SizedBox(height:12),
              Text("Total primes : $_totalBonus FCFA", style:TextStyle(fontSize:17, color:Colors.green.shade700, fontWeight:FontWeight.w600))
            ])),
          SizedBox(height:20),
          SizedBox(width:double.infinity, child:ElevatedButton.icon(
            icon:const Icon(Icons.share, color:Colors.white), label:Text("Partager & Inviter", style:TextStyle(fontSize:17, fontWeight:FontWeight.bold)),
            style:ElevatedButton.styleFrom(backgroundColor:Colors.blueAccent, padding:const EdgeInsets.symmetric(vertical:15), borderRadius:BorderRadius.circular(14)),
            onPressed:_myCode!=null?_share:null
          )),
          SizedBox(height:25),
          Align(alignment:Alignment.centerLeft, child:Text("📋 Mes amis invités", style:TextStyle(fontSize:20, fontWeight:FontWeight.bold, color:Color(0xFF0F3460)))),
          SizedBox(height:10),
          SizedBox(height:250, child:StreamBuilder<QuerySnapshot>(
            stream:FirebaseFirestore.instance.collection('users').where('referredBy', isEqualTo:_uid).limit(20).snapshots(),
            builder:(ctx,snap){
              if(!snap.hasData||snap.data!.docs.isEmpty) return const Center(child:Text("Aucun ami encore invité !", style:TextStyle(color:Colors.black45)));
              return ListView(children:snap.data!.docs.map((doc){
                return Card(child:ListTile(
                  leading:CircleAvatar(child:Icon(Icons.person_add, color:Colors.white)),
                  title:Text(doc['fullName']??"Utilisateur"),
                  trailing:Text("+$_rewardPerFriend FCFA", style:TextStyle(color:Colors.green.shade700, fontWeight:FontWeight.bold))
                ));
              }).toList());
            }
          ))
        ])
      )
    );
  }
}

