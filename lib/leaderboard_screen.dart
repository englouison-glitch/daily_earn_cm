import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'localization/app_localization.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final String _myUid = FirebaseAuth.instance.currentUser!.uid;

  Widget _getMedal(int rank, double size){
    if(rank==1) return Icon(Icons.workspace_premium, color:Colors.amber, size:size);
    if(rank==2) return Icon(Icons.workspace_premium, color:Colors.grey.shade300, size:size);
    if(rank==3) return Icon(Icons.workspace_premium, color:Colors.brown.shade400, size:size);
    return Text("$rank", style:TextStyle(fontWeight:FontWeight.bold, fontSize:size*0.8, color:Colors.black54));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalization.of(context)!;
    return Scaffold(
      appBar: AppBar(title:Text(loc.translate("leaderboard")), backgroundColor:const Color(0xFF0F3460)),
      body:Container(
        decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFFF0F4F8),Color(0xFFE2EBF3)], begin:Alignment.topCenter, end:Alignment.bottomCenter)),
        child:StreamBuilder<QuerySnapshot>(
          stream:FirebaseFirestore.instance.collection('users').orderBy('balance', descending:true).limit(20).snapshots(),
          builder:(ctx,snap){
            if(snap.connectionState==ConnectionState.waiting) return const Center(child:CircularProgressIndicator(color:Color(0xFF0F3460)));
            if(!snap.hasData||snap.data!.docs.isEmpty) return const Center(child:Text("Classement vide pour l'instant !", style:TextStyle(fontSize:16, color:Colors.black45)));

            var topList = snap.data!.docs;
            int myRank = -1; Map? myData;
            for(int i=0;i<topList.length;i++){if(topList[i].id==_myUid){myRank=i+1; myData=topList[i].data() as Map; break;}}

            return Column(children:[
              Container(padding:const EdgeInsets.symmetric(vertical:20), color:Colors.white.withOpacity(0.6),
                child:Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly, children:[
                  if(topList.length>=2)_podiumItem(topList[1],2),
                  if(topList.length>=1)_podiumItem(topList[0],1),
                  if(topList.length>=3)_podiumItem(topList[2],3),
                ])
              ),
              const Divider(height:2),
              Expanded(child:ListView.builder(padding:const EdgeInsets.symmetric(vertical:10),
                itemCount:topList.length,
                itemBuilder:(ctx,i){if(i==0||i==1||i==3)return const SizedBox.shrink(); return _rankItem(i+1, topList[i].data() as Map, topList[i].id==_myUid);}
              )),
              if(myRank>3)Container(width:double.infinity, padding:const EdgeInsets.all(14), color:const Color(0xFF0F3460).withOpacity(0.15),
                child:Row(children:[_getMedal(myRank,30),SizedBox(width:12),Expanded(child:Text(myData?['fullName']??"Moi", style:TextStyle(fontWeight:FontWeight.bold))),Text("${myData?['balance']??0} FCFA", style:TextStyle(fontWeight:FontWeight.bold, color:Colors.green.shade700))])
            ]);
          }
        )
      )
    );
  }

  Widget _podiumItem(DocumentSnapshot d,int r){Map m=d.data()as Map;return Column(children:[_getMedal(r,35),SizedBox(height:6),Text(m['fullName']?.toString().split(' ').first??"Top", style:const TextStyle(fontWeight:FontWeight.w600)),Text("${m['balance']} FCFA", style:TextStyle(color:Colors.green.shade700, fontWeight:FontWeight.bold))]);}
  Widget _rankItem(int r,Map d,bool moi){return Container(margin:const EdgeInsets.symmetric(horizontal:12,vertical:5),decoration:BoxDecoration(color:moi?const Color(0xFFE8F4FD):Colors.white,borderRadius:BorderRadius.circular(12)),child:ListTile(leading:_getMedal(r,28),title:Text(d['fullName']??"Utilisateur",style:TextStyle(fontWeight:moi?FontWeight.bold:FontWeight.normal)),trailing:Text("${d['balance']} FCFA",style:const TextStyle(fontWeight:FontWeight.bold,color:Color(0xFF0F3460)))));}
}

